import SwiftUI
import ARKit
import Vision
import UIKit

final class DepthConduitScanner: NSObject, ObservableObject, ARSessionDelegate {
    @Published var message = "Point the rear camera at a straight conduit."
    @Published var diameterMM: Double?
    @Published var sampleCount = 0
    let session = ARSession()
    private var busy = false
    private var lastProcessed = Date.distantPast
    private var measurements: [Double] = []

    func start() {
        guard ARWorldTrackingConfiguration.isSupported else {
            message = "AR tracking is unavailable on this device."
            return
        }
        let config = ARWorldTrackingConfiguration()
        guard ARWorldTrackingConfiguration.supportsFrameSemantics(.sceneDepth) else {
            message = "Depth sensor not supported. Use calibrated photo measurement."
            return
        }
        config.frameSemantics.insert(.sceneDepth)
        config.worldAlignment = .gravity
        session.delegate = self
        session.run(config, options: [.resetTracking, .removeExistingAnchors])
    }

    func stop() { session.pause(); session.delegate = nil }

    func session(_ session: ARSession, didUpdate frame: ARFrame) {
        guard !busy, Date().timeIntervalSince(lastProcessed) > 0.6,
              let depth = frame.smoothedSceneDepth ?? frame.sceneDepth else { return }
        busy = true
        lastProcessed = Date()
        let camera = frame.camera
        let image = frame.capturedImage
        let depthBuffer = depth.depthMap
        DispatchQueue.global(qos: .userInitiated).async {
            let request = VNDetectContoursRequest()
            request.maximumImageDimension = 512
            do {
                try VNImageRequestHandler(cvPixelBuffer: image, options: [:]).perform([request])
                let edgePair = try? ConduitEdgeDetector.detect(in: image)
                let contours = request.results?.first?.topLevelContours ?? []
                let candidates = contours.compactMap { contour -> CGRect? in
                    let rect = contour.normalizedPath.boundingBox
                    let aspect = max(rect.width, rect.height) / max(0.0001, min(rect.width, rect.height))
                    return aspect > 5 && max(rect.width, rect.height) > 0.25 ? rect : nil
                }
                let rect = edgePair == nil ? nil : candidates.max { a, b in a.width * a.height < b.width * b.height }
                var estimated: Double?
                if let rect, rect.width > rect.height {
                    let depthWidth = CVPixelBufferGetWidth(depthBuffer)
                    let depthHeight = CVPixelBufferGetHeight(depthBuffer)
                    // Vision normalized coordinates are bottom-left; depth map is top-left.
                    let cx = Int((rect.midX * CGFloat(depthWidth)).rounded())
                    let cy = Int(((1 - rect.midY) * CGFloat(depthHeight)).rounded())
                    if cx >= 0 && cx < depthWidth && cy >= 0 && cy < depthHeight {
                        CVPixelBufferLockBaseAddress(depthBuffer, .readOnly)
                        if let base = CVPixelBufferGetBaseAddress(depthBuffer) {
                            let row = CVPixelBufferGetBytesPerRow(depthBuffer) / MemoryLayout<Float32>.stride
                            let z = base.assumingMemoryBound(to: Float32.self)[cy * row + cx]
                            let imageWidth = Double(CVPixelBufferGetWidth(image))
                            let focalX = Double(camera.intrinsics.columns.0.x)
                            if z.isFinite && z > 0.1 && z < 4 && focalX > 0 {
                                // Rough projected width only; contour may be shadow or edge.
                                if let pair = edgePair, pair.confidence >= 0.35 {
                                    estimated = pair.separationNormalized * imageWidth * Double(z) / focalX * 1000
                                }
                            }
                        }
                        CVPixelBufferUnlockBaseAddress(depthBuffer, .readOnly)
                    }
                }
                DispatchQueue.main.async {
                    if let estimated, estimated > 3, estimated < 200 {
                        self.measurements.append(estimated)
                        if self.measurements.count > 7 { self.measurements.removeFirst() }
                        self.sampleCount = self.measurements.count
                        let ordered = self.measurements.sorted()
                        self.diameterMM = ordered[ordered.count / 2]
                        self.message = "Experimental depth-based width. Verify using calipers."
                    } else {
                        self.message = "No unambiguous paired edges with usable depth. Reposition camera; do not trust a guessed diameter."
                    }
                    self.busy = false
                }
            } catch {
                DispatchQueue.main.async { self.message = error.localizedDescription; self.busy = false }
            }
        }
    }
}

struct DepthConduitScanView: View {
    @StateObject private var scanner = DepthConduitScanner()
    var body: some View {
        VStack(spacing: 16) {
            DepthCameraPreview(session: scanner.session)
                .frame(height: 310)
                .clipShape(RoundedRectangle(cornerRadius: 12))
            Text("Depth-assisted conduit width").font(.headline)
            if let diameter = scanner.diameterMM {
                Text(String(format: "~ %.1f mm", diameter)).font(.largeTitle.monospacedDigit())
            }
            Text(scanner.message).multilineTextAlignment(.center)
            Text("Samples: \(scanner.sampleCount)/7")
            Text("Requires LiDAR scene depth. Not a certified outer-diameter measurement; image contours and depth may misalign.")
                .font(.caption).foregroundStyle(.secondary)
        }
        .padding()
        .navigationTitle("Depth Scan")
        .onAppear { scanner.start() }
        .onDisappear { scanner.stop() }
    }
}


private struct DepthCameraPreview: UIViewRepresentable {
    let session: ARSession
    func makeUIView(context: Context) -> ARSCNView {
        let view = ARSCNView(frame: .zero)
        view.session = session
        view.automaticallyUpdatesLighting = false
        return view
    }
    func updateUIView(_ uiView: ARSCNView, context: Context) {}
}
