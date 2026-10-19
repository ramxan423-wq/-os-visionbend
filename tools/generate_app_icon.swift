import AppKit
import Foundation

let folder = URL(fileURLWithPath: "VisionBend/Assets.xcassets/AppIcon.appiconset")
try FileManager.default.createDirectory(at: folder, withIntermediateDirectories: true)
let side = 1024
guard let bitmap = NSBitmapImageRep(bitmapDataPlanes: nil, pixelsWide: side, pixelsHigh: side, bitsPerSample: 8, samplesPerPixel: 3, hasAlpha: false, isPlanar: false, colorSpaceName: .deviceRGB, bytesPerRow: 0, bitsPerPixel: 0), let context = NSGraphicsContext(bitmapImageRep: bitmap) else { fatalError("bitmap") }
NSGraphicsContext.saveGraphicsState()
NSGraphicsContext.current = context
NSColor(calibratedRed: 0.28, green: 0.09, blue: 0.49, alpha: 1).setFill()
NSRect(x: 0, y: 0, width: side, height: side).fill()
let conduit = NSBezierPath()
conduit.lineWidth = 115
conduit.lineCapStyle = .round
conduit.lineJoinStyle = .round
conduit.move(to: NSPoint(x: 215, y: 365))
conduit.line(to: NSPoint(x: 455, y: 365))
conduit.curve(to: NSPoint(x: 570, y: 460), controlPoint1: NSPoint(x: 530, y: 365), controlPoint2: NSPoint(x: 520, y: 390))
conduit.line(to: NSPoint(x: 760, y: 730))
NSColor.white.setStroke()
conduit.stroke()
context.flushGraphics()
NSGraphicsContext.restoreGraphicsState()
guard let data = bitmap.representation(using: .png, properties: [:]) else { fatalError("png") }
let base = folder.appendingPathComponent("icon-1024.png")
try data.write(to: base)
struct Slot: Encodable { let size: String; let idiom: String; let scale: String; let filename: String }
struct Info: Encodable { let author = "xcode"; let version = 1 }
struct Catalog: Encodable { let images: [Slot]; let info = Info() }
var images: [Slot] = []
for (idiom, size, scale) in [
    ("iphone","20x20",2),("iphone","20x20",3),
    ("iphone","29x29",2),("iphone","29x29",3),
    ("iphone","40x40",2),("iphone","40x40",3),
    ("iphone","60x60",2),("iphone","60x60",3),
    ("ipad","20x20",1),("ipad","20x20",2),
    ("ipad","29x29",1),("ipad","29x29",2),
    ("ipad","40x40",1),("ipad","40x40",2),
    ("ipad","76x76",1),("ipad","76x76",2),
    ("ipad","83.5x83.5",2)
] {
    let value = Double(size.components(separatedBy: "x")[0])!
    let pixels = Int(value * Double(scale))
    let filename = "\(idiom)-\(pixels).png"
    let cmd = Process()
    cmd.executableURL = URL(fileURLWithPath: "/usr/bin/sips")
    cmd.arguments = ["-z","\(pixels)","\(pixels)",base.path,"--out",folder.appendingPathComponent(filename).path]
    cmd.standardOutput = FileHandle.nullDevice
    try cmd.run()
    cmd.waitUntilExit()
    if cmd.terminationStatus != 0 { fatalError("sips") }
    images.append(Slot(size: size, idiom: idiom, scale: "\(scale)x", filename: filename))
}
images.append(Slot(size: "1024x1024", idiom: "ios-marketing", scale: "1x", filename: "icon-1024.png"))
try JSONEncoder().encode(Catalog(images: images)).write(to: folder.appendingPathComponent("Contents.json"))
print("Created VisionBend app icon assets")
