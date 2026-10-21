#!/usr/bin/env python3
"""Audit VisionBend's 20 chosen languages and translation-key coverage.

Run: python3 tools/audit_localizations.py
     python3 tools/audit_localizations.py --strict
The audit intentionally does not treat the existence of a language picker as
proof the whole interface is translated. Unrecognized dynamic strings must
also be reviewed manually.
"""
import argparse
import ast
import json
from pathlib import Path
import re

ROOT = Path(__file__).resolve().parent.parent
SOURCE = ROOT / "VisionBend"
LANGUAGES = SOURCE / "LanguageSelectionView.swift"
PRIMARY = SOURCE / "VisionBendLocalization.swift"
EXTRA = SOURCE / "VisionBendMoreTranslations.swift"
EXPECTED = ("en", "tr", "es", "fr", "de", "ar", "pt", "it", "ru",
            "fa", "hi", "zh-Hans", "zh-Hant", "ja", "ko", "id",
            "da", "sv", "nl", "fi")
KEY_RE = r'"((?:[^"\\]|\\.)*)"'
CODE_RE = re.compile(r'\("([a-zA-Z-]+)",\s*"')
ENTRY_RE = re.compile(r'^\s*"((?:[^"\\]|\\.)+)": \[([^\n]+)\],?$', re.M)
TRANS_RE = re.compile(r'"([a-zA-Z-]+)":\s*"((?:[^"\\]|\\.)*)"')
LOCAL_RE = re.compile(r'\bl\(\s*"((?:[^"\\]|\\.)*)"') 
TWO_LANGUAGE_RE = re.compile(r'\bt\(\s*"(?:[^"\\]|\\.)*"\s*,\s*"((?:[^"\\]|\\.)*)"')
TEXT_RE = re.compile(r'VisionBendLocalization\.text\(\s*"((?:[^"\\]|\\.)*)"')
RAW_RE = re.compile(r'\b(?:Text|Section|Button|Label|TextField|Toggle|navigationTitle|navigationBarTitle|Picker|ShareLink)\(\s*"((?:[^"\\]|\\.)*)"')

def unquote(raw):
    try:
        return json.loads('"' + raw + '"')
    except json.JSONDecodeError:
        return raw

def load_primary():
    entries = {}
    for match in ENTRY_RE.finditer(PRIMARY.read_text()):
        english = unquote(match.group(1))
        values = {code: unquote(text) for code, text in TRANS_RE.findall(match.group(2))}
        entries[english] = values
    return entries

def load_extra():
    data = EXTRA.read_text()
    km = re.search(r'private static let keys: \[String\] = (\[[^\n]+\])', data)
    if not km:
        raise SystemExit('Extra translation key list not found')
    keys = json.loads(km.group(1))
    rows = {}
    for m in re.finditer(r'^\s*"([a-zA-Z-]+)": (\[[^\n]+\]),?$', data, re.M):
        rows[m.group(1)] = json.loads(m.group(2))
        if len(rows[m.group(1)]) != len(keys):
            raise SystemExit('Translation array misaligned for ' + m.group(1))
    return {k:{language: rows[language][idx] for language in rows} for idx,k in enumerate(keys)}

def load_watch():
    """Read the watchOS-only localization table, compiled in its own target."""
    src = (ROOT / "VisionBendWatch" / "WatchApp.swift").read_text()
    km = re.search(r'private static let keys = (\[[^\n]+\])', src)
    if not km:
        return {}
    keys = json.loads(km.group(1))
    rows = {}
    for m in re.finditer(r'^\s*"([a-zA-Z-]+)": (\[[^\n]+\]),?$', src, re.M):
        rows[m.group(1)] = json.loads(m.group(2))
        if len(rows[m.group(1)]) != len(keys):
            raise SystemExit("Watch localization length mismatch: " + m.group(1))
    return {key: {code: row[i] for code, row in rows.items()}
            for i, key in enumerate(keys)}


def check():
    picker = tuple(CODE_RE.findall(LANGUAGES.read_text().split('static let supported:', 1)[1].split('    ]',1)[0]))
    if picker != EXPECTED:
        raise SystemExit('Language picker differs from required 20: ' + repr(picker))
    translations = load_primary()
    for source in (load_extra(), load_watch()):
        for key, row in source.items():
            translations.setdefault(key, {}).update(row)

    call_sites = {}
    raw_sites = {}
    for path in list(SOURCE.glob("*.swift")) + list((ROOT / "VisionBendWatch").glob("*.swift")):
        if path.name.startswith("VisionBendLocalization") or path.name == "VisionBendMoreTranslations.swift":
            continue
        src = path.read_text()
        # t(turkish, english) uses the second, English argument as the catalog key.
        for pattern in (LOCAL_RE, TWO_LANGUAGE_RE, TEXT_RE):
            for match in pattern.finditer(src):
                call_sites.setdefault(unquote(match.group(1)), set()).add(path.name)
        for match in RAW_RE.finditer(src):
            text = unquote(match.group(1))
            # Branding and manufacturer-identifying data are intentionally not translated.
            if text and not text.startswith(("VisionBend", "Greenlee", "Premium", "AR ", "UIKit", "\\(")):
                raw_sites.setdefault(text, set()).add(path.name)

    coverage = {}
    for code in EXPECTED:
        if code == "en":
            coverage[code] = {"translated": len(call_sites), "missing": []}
            continue
        missing = sorted(key for key in call_sites if not translations.get(key, {}).get(code))
        coverage[code] = {"translated": len(call_sites) - len(missing), "missing": missing}

    report = {
        "supportedLanguages": list(picker),
        "localizationCallCount": len(call_sites),
        "localizationCatalogKeys": len(translations),
        "coverage": coverage,
        "unlocalizedLiteralCandidates": {
            key: sorted(files) for key, files in sorted(raw_sites.items())
        },
        "unlocalizedLiteralCount": len(raw_sites),
        "note": "This static audit does not verify runtime strings, PDF export labels, Watch sync, dynamic errors or natural translation quality."
    }
    return report

if __name__ == "__main__":
    parser = argparse.ArgumentParser()
    parser.add_argument("--strict", action="store_true")
    parser.add_argument("--output", default="localization-audit.json")
    args = parser.parse_args()
    report = check()
    Path(args.output).write_text(json.dumps(report, indent=2, ensure_ascii=False))
    print("Supported languages:", len(report["supportedLanguages"]))
    print("Localized call keys:", report["localizationCallCount"])
    for code, item in report["coverage"].items():
        if code != "en":
            print(code, 'missing', len(item["missing"]))
    print("Raw literal candidates:", report["unlocalizedLiteralCount"])
    print("Detailed report:", args.output)
    if args.strict and (any(row["missing"] for language, row in report["coverage"].items() if language != "en")
                        or report["unlocalizedLiteralCount"] > 0):
        raise SystemExit("NOT READY FOR RELEASE: translation gaps remain.")
