#!/usr/bin/env python3
"""Generate opaque App Store icon assets without any external dependencies."""
import json
import pathlib
import struct
import zlib

ROOT = pathlib.Path(__file__).resolve().parents[1]
DEST = ROOT / "VisionBend" / "Assets.xcassets" / "AppIcon.appiconset"
DEST.mkdir(parents=True, exist_ok=True)
SIZE = 1024

def capsule(x, y, x1, y1, x2, y2, radius):
    dx, dy = x2 - x1, y2 - y1
    f = max(0.0, min(1.0, ((x - x1) * dx + (y - y1) * dy) / (dx * dx + dy * dy)))
    return (x - x1 - f * dx) ** 2 + (y - y1 - f * dy) ** 2 <= radius ** 2

def ink(x, y):
    if capsule(x, y, 248, 630, 415, 630, 46): return True
    if capsule(x, y, 415, 630, 490, 610, 46): return True
    if capsule(x, y, 490, 610, 661, 368, 46): return True
    if capsule(x, y, 655, 568, 743, 482, 15): return True
    if capsule(x, y, 731, 518, 820, 605, 17): return True
    if capsule(x, y, 793, 579, 892, 672, 24): return True
    if capsule(x, y, 644, 566, 698, 512, 21): return True
    if 600 < y < 610 and 540 < x < 735 and int(x / 32) % 2 == 0: return True
    return False

def png_rgb(width, height, pixels):
    def chunk(kind, data):
        return struct.pack(">I", len(data)) + kind + data + struct.pack(">I", zlib.crc32(kind + data) & 0xFFFFFFFF)
    ihdr = struct.pack(">IIBBBBB", width, height, 8, 2, 0, 0, 0)
    return b"\x89PNG\r\n\x1a\n" + chunk(b"IHDR", ihdr) + chunk(b"IDAT", zlib.compress(pixels, 9)) + chunk(b"IEND", b"")

def render(px):
    raw = bytearray()
    for y in range(px):
        raw.append(0)
        yy = y * (SIZE / px)
        for x in range(px):
            xx = x * (SIZE / px)
            if ink(xx, yy):
                raw.extend((255, 255, 255))
            else:
                d = ((xx - 515) / 1024) ** 2 + ((yy - 520) / 1024) ** 2
                glow = max(0, int(19 - 120 * d))
                raw.extend((51 + glow, 5 + glow // 3, 98 + glow))
    return png_rgb(px, px, bytes(raw))

master = DEST / "AppIcon-1024.png"
master.write_bytes(render(SIZE))
images = []
slots = [
    ("iphone","20x20",2),("iphone","20x20",3),
    ("iphone","29x29",2),("iphone","29x29",3),
    ("iphone","40x40",2),("iphone","40x40",3),
    ("iphone","60x60",2),("iphone","60x60",3),
    ("ipad","20x20",1),("ipad","20x20",2),
    ("ipad","29x29",1),("ipad","29x29",2),
    ("ipad","40x40",1),("ipad","40x40",2),
    ("ipad","76x76",1),("ipad","76x76",2),
    ("ipad","83.5x83.5",2),
]
for idiom, size, scale in slots:
    px = int(float(size.split("x")[0]) * scale)
    filename = "AppIcon-{}-{}-{}x.png".format(idiom, size.replace(".", "_"), scale)
    (DEST / filename).write_bytes(render(px))
    images.append({"size": size, "idiom": idiom, "scale": "{}x".format(scale), "filename": filename})
images.append({"size": "1024x1024", "idiom": "ios-marketing", "scale": "1x", "filename": master.name})
(DEST / "Contents.json").write_text(json.dumps({"images": images, "info": {"author": "xcode", "version": 1}}, indent=2) + "\n")
print("Generated {} opaque VisionBend icons.".format(len(images)))
