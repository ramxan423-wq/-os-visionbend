import Foundation
import CoreGraphics
import Vision
import CoreVideo

struct ConduitEdgePair {
    let first: CGPoint
    let second: CGPoint
    let separationNormalized: Double
    let parallelism: Double
    let confidence: Double
}

/// Conservative candidate detector. Rejects ambiguous images instead of returning a false diameter.
enum ConduitEdgeDetector {
    static func detect(in pixelBuffer: CVPixelBuffer) throws -> ConduitEdgePair? {
        let request = VNDetectContoursRequest()
        request.maximumImageDimension = 1024
        request.contrastAdjustment = 1
        try VNImageRequestHandler(cvPixelBuffer: pixelBuffer, options: [:]).perform([request])
        guard let observation = request.results?.first else { return nil }
        let width = Double(CVPixelBufferGetWidth(pixelBuffer))
        let height = Double(CVPixelBufferGetHeight(pixelBuffer))
        guard width > 0, height > 0 else { return nil }
        struct Segment {
            let start: CGPoint
            let end: CGPoint
            let angle: Double
            let length: Double
        }
        var segments: [Segment] = []
        for contour in observation.topLevelContours {
            let path = contour.normalizedPath
            let box = path.boundingBox
            let longSide = max(Double(box.width) * width, Double(box.height) * height)
            let shortSide = min(Double(box.width) * width, Double(box.height) * height)
            guard longSide > min(width, height) * 0.28, shortSide < longSide * 0.16 else { continue }
            // Bounding box orientation is reliable only for near-horizontal/vertical elongated contours.
            let horizontal = Double(box.width) * width > Double(box.height) * height
            let a: CGPoint
            let b: CGPoint
            if horizontal {
                a = CGPoint(x: box.minX, y: box.midY)
                b = CGPoint(x: box.maxX, y: box.midY)
            } else {
                a = CGPoint(x: box.midX, y: box.minY)
                b = CGPoint(x: box.midX, y: box.maxY)
            }
            segments.append(Segment(start: a, end: b, angle: horizontal ? 0 : .pi / 2, length: longSide))
        }
        guard segments.count >= 2 else { return nil }
        var matches: [(ConduitEdgePair, Double)] = []
        for i in 0..<segments.count {
            for j in (i + 1)..<segments.count {
                let a = segments[i], b = segments[j]
                guard abs(a.angle - b.angle) < 0.05 else { continue }
                let horizontal = a.angle == 0
                let distance = horizontal ? abs(Double(a.start.y - b.start.y)) : abs(Double(a.start.x - b.start.x))
                let overlap = horizontal
                    ? max(0, min(Double(a.end.x), Double(b.end.x)) - max(Double(a.start.x), Double(b.start.x)))
                    : max(0, min(Double(a.end.y), Double(b.end.y)) - max(Double(a.start.y), Double(b.start.y)))
                let lengthNorm = horizontal ? width : height
                let separationPx = distance * (horizontal ? height : width)
                guard overlap * lengthNorm > min(a.length, b.length) * 0.55,
                      separationPx >= 5, separationPx < min(width, height) * 0.22 else { continue }
                let score = min(1, overlap * lengthNorm / max(a.length, b.length))
                let pair = ConduitEdgePair(first: a.start, second: b.start,
                                           separationNormalized: distance, parallelism: 1,
                                           confidence: score * 0.6)
                matches.append((pair, score))
            }
        }
        let sorted = matches.sorted { $0.1 > $1.1 }
        guard let best = sorted.first, best.1 > 0.6 else { return nil }
        // Competing candidates mean the actual conduit edges are ambiguous.
        if sorted.count > 1 && sorted[1].1 > best.1 * 0.9 { return nil }
        return best.0
    }
}
