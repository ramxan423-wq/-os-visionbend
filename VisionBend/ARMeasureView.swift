import SwiftUI
import RealityKit
import ARKit

/// Measures between two user-selected world points. Requires a supported ARKit device.
struct ARMeasureView: View {
    @State private var points: [SIMD3<Float>] = []
    @State private var message = "Tap two tracked surfaces to measure."
    var body: some View {
        VStack(spacing: 12) {
            if ARWorldTrackingConfiguration.isSupported {
                ARMeasureRepresentable(points: $points, message: $message)
                    .overlay(alignment: .center) {
                        Image(systemName: "plus").font(.title).foregroundStyle(.orange)
                            .allowsHitTesting(false)
                    }
                Text(message).font(.footnote)
                if points.count == 2 {
                    Text(String(format: "Distance: %.1f mm", simd_distance(points[0], points[1]) * 1000))
                        .font(.title3.monospacedDigit())
                }
                Button("Reset measurement") { points = []; message = "Tap two tracked surfaces to measure." }
            } else {
                ContentUnavailableAR()
            }
        }
        .navigationTitle("AR Measurement")
        .navigationBarTitleDisplayMode(.inline)
    }
}

private struct ContentUnavailableAR: View {
    var body: some View {
        VStack(spacing: 12) {
            Image(systemName: "iphone.slash").font(.largeTitle)
            Text("AR world tracking is not available on this device.")
        }.padding()
    }
}

private struct ARMeasureRepresentable: UIViewRepresentable {
    @Binding var points: [SIMD3<Float>]
    @Binding var message: String

    func makeCoordinator() -> Coordinator { Coordinator(self) }

    func makeUIView(context: Context) -> ARView {
        let view = ARView(frame: .zero)
        let config = ARWorldTrackingConfiguration()
        config.planeDetection = [.horizontal, .vertical]
        view.session.run(config)
        let tap = UITapGestureRecognizer(target: context.coordinator, action: #selector(Coordinator.tapped(_:)))
        view.addGestureRecognizer(tap)
        context.coordinator.view = view
        return view
    }

    func updateUIView(_ view: ARView, context: Context) {
        context.coordinator.parent = self
    }

    static func dismantleUIView(_ view: ARView, coordinator: Coordinator) {
        view.session.pause()
    }

    final class Coordinator: NSObject {
        var parent: ARMeasureRepresentable
        weak var view: ARView?
        init(_ parent: ARMeasureRepresentable) { self.parent = parent }

        @objc func tapped(_ recognizer: UITapGestureRecognizer) {
            guard let view = view, recognizer.state == .ended else { return }
            let location = recognizer.location(in: view)
            guard let result = view.raycast(from: location, allowing: .estimatedPlane, alignment: .any).first else {
                parent.message = "No tracked surface here. Move the camera slowly and retry."
                return
            }
            let t = result.worldTransform.columns.3
            let point = SIMD3<Float>(t.x, t.y, t.z)
            if parent.points.count >= 2 { parent.points = [] }
            parent.points.append(point)
            parent.message = parent.points.count == 1 ? "First point set. Tap the second point." : "Two points recorded."
        }
    }
}
