#!/usr/bin/env python3
"""Create REVIEW-REQUIRED offline translation drafts for untranslated UI keys.
This is a one-off development utility, not an app dependency or runtime API.
The generated JSON is shipped as a static resource only after validation.
Usage: python3 tools/fill_missing_translations.py
"""
import concurrent.futures
import json
import os
import pathlib
import re
import threading
import time
import urllib.error
import urllib.parse
import urllib.request
from audit_localizations import check

ROOT = pathlib.Path(__file__).resolve().parent.parent
DESTINATION = ROOT / "VisionBend" / "GeneratedTranslations.json"
REPORT = ROOT / "translation-draft-qa.json"
LOCALES = ("tr", "es", "fr", "de", "ar", "pt", "it", "ru", "fa", "hi",
           "zh-Hans", "zh-Hant", "ja", "ko", "id", "da", "sv", "nl", "fi")
FORMAT = re.compile(r'%(?:\d+\$)?[-+ 0#]*\d*(?:\.\d+)?(?:@|ld|d|f|s|u)|\n')
lock = threading.Lock()
metrics = {"translated": 0, "failed": 0}
CACHE = ROOT / "translation-draft-cache.json"
completed = json.loads(CACHE.read_text()) if CACHE.exists() else {}

def google_translate(fragment, locale):
    if not fragment.strip() or not re.search(r'[A-Za-z]', fragment):
        return fragment
    lead = fragment[:len(fragment)-len(fragment.lstrip())]
    trail = fragment[len(fragment.rstrip()):]
    core = fragment.strip()
    query = urllib.parse.urlencode({
        "client": "gtx", "sl": "en", "tl": locale, "dt": "t", "q": core,
    })
    url = "https://translate.googleapis.com/translate_a/single?" + query
    for attempt in range(5):
        try:
            request = urllib.request.Request(url, headers={"User-Agent": "Mozilla/5.0 VisionBend-localization-build/1.0"})
            with urllib.request.urlopen(request, timeout=25) as response:
                payload = json.load(response)
            rendered = "".join(segment[0] for segment in payload[0] if segment and isinstance(segment[0], str))
            if rendered.strip():
                return lead + rendered + trail
        except Exception as exc:
            if attempt == 4:
                raise RuntimeError(f"{locale} translation error ({type(exc).__name__})") from exc
            time.sleep(min(12, 0.7 * 2 ** attempt))
    raise RuntimeError("empty translation response")

def translate_safe(english, locale):
    # Split instead of asking a translator to preserve printf specifiers.
    # This guarantees every type and argument order stays unchanged.
    parts = FORMAT.split(english)
    tokens = FORMAT.findall(english)
    out = []
    for index, text in enumerate(parts):
        if text:
            out.append(google_translate(text, locale))
        if index < len(tokens):
            out.append(tokens[index])
    result = "".join(out)
    if FORMAT.findall(result) != tokens:
        raise ValueError("Printf placeholders changed")
    if not result.strip():
        raise ValueError("Empty translation")
    return result

def translate_locale(code, english_keys):
    already = dict(completed.get(code, {}))
    total = len(english_keys)
    for i, key in enumerate(english_keys, 1):
        if key not in already:
            try:
                already[key] = translate_safe(key, code)
                with lock: metrics["translated"] += 1
            except Exception as exc:
                with lock:
                    metrics["failed"] += 1
                    print(f"ERROR {code} {key[:55]}: {exc}", flush=True)
        if i % 25 == 0:
            print(f"{code}: {i}/{total}", flush=True)
            with lock:
                completed[code] = dict(already)
                CACHE.write_text(json.dumps(completed, ensure_ascii=False, indent=2))
    with lock:
        completed[code] = dict(already)
        CACHE.write_text(json.dumps(completed, ensure_ascii=False, indent=2))
    return code, already

def main():
    audit = check()
    required = {code: audit["coverage"][code]["missing"] for code in LOCALES}
    print("Localizable keys:", audit["localizationCallCount"], flush=True)
    print("Draft translations to produce:", sum(map(len, required.values())), flush=True)
    with concurrent.futures.ThreadPoolExecutor(max_workers=3) as executor:
        futures = [executor.submit(translate_locale, code, items) for code, items in required.items()]
        for future in concurrent.futures.as_completed(futures):
            code, results = future.result()
            print(f"DONE {code}: {len(results)}/{len(required[code])}", flush=True)
    # Store only exact key translations. Never fill missing entries with English.
    output = {code: {key: completed.get(code, {}).get(key, "") for key in items
                     if completed.get(code, {}).get(key, "").strip()}
              for code, items in required.items()}
    missed = {code: sorted(set(items)-set(output[code])) for code, items in required.items()}
    DESTINATION.write_text(json.dumps(output, ensure_ascii=False, indent=2)+"\n")
    report = {"missing": missed, "failure_count": sum(map(len, missed.values())),
              "translated_items": sum(map(len, output.values())), "source": "machine draft; technical safety review required"}
    REPORT.write_text(json.dumps(report, ensure_ascii=False, indent=2)+"\n")
    print("OUTPUT", DESTINATION, "failures", report["failure_count"], flush=True)
    if report["failure_count"]:
        raise SystemExit(f"{report['failure_count']} untranslated items; not release-ready.")
    print("All missing key drafts generated. HUMAN QA STILL REQUIRED.", flush=True)

if __name__ == "__main__":
    main()
