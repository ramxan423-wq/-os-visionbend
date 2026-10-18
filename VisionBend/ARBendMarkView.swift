import SwiftUI
import RealityKit
import ARKit

/// AR placement needs two manually identified conduit endpoints.
struct ARBendMarkView: View {
    let marks: [BendMark]
    let conduitLength: Double
    let unitToMeters: Double
    @State private var endpoints: [SIMD3<Float>] = []
    @State private var notice = "Tap the conduit START, then END on a tracked surface."
    var body: some View {
        VStack(spacing: 8) {
            if ARWorldTrackingConfiguration.isSupported {
                ARBendMarkCamera(endpoints: $endpoints, notice: $notice, marks: marks, conduitLength: conduitLength, unitToMeters: unitToMeters)
                Text(notice).font(.footnote).padding(.horizontal)
                if endpoints.count == 2 {
                    Text(String(format: "AR measured length: %.1f %@", Double(simd_distance(endpoints[0], endpoints[1])) / unitToMeters, unitToMeters == 0.001 ? "mm" : unitToMeters == 0.01 ? "cm" : "in"))
                        .font(.caption.monospacedDigit())
                }
                Button("Reset endpoints") { endpoints = []; notice = "Tap the conduit START, then END." }
            } else {
                Text("AR tracking is unavailable on this device.")
            }
            Text("Experimental: select endpoints manually. AR tracking and surface raycasts do not automatically detect the conduit. Check every physical mark with a tape measure.")
                .font(.caption).foregroundStyle(.secondary).padding()
        }.navigationTitle("Camera Bend Marks")
    }
}

private struct ARBendMarkCamera: UIViewRepresentable {
    @Binding var endpoints: [SIMD3<Float>]
    @Binding var notice: String
    let marks: [BendMark]
    let conduitLength: Double
    let unitToMeters: Double

    func makeCoordinator() -> Coordinator { Coordinator(self) }
    func makeUIView(context: Context) -> ARView {
        let view = ARView(frame: .zero)
        let config = ARWorldTrackingConfiguration()
        config.planeDetection = [.horizontal, .vertical]
        view.session.run(config)
        view.addGestureRecognizer(UITapGestureRecognizer(target: context.coordinator, action: #selector(Coordinator.tap(_:))))
        context.coordinator.view = view
        return view
    }
    func updateUIView(_ view: ARView, context: Context) {
        context.coordinator.parent = self
        context.coordinator.redraw()
    }
    static func dismantleUIView(_ view: ARView, coordinator: Coordinator) {
        view.session.pause()
    }
    final class Coordinator: NSObject {
        var parent: ARBendMarkCamera
        weak var view: ARView?
        private var anchors: [AnchorEntity] = []
        init(_ parent: ARBendMarkCamera) { self.parent = parent }

        @objc func tap(_ recognizer: UITapGestureRecognizer) {
            guard let view, recognizer.state == .ended,
                  let hit = view.raycast(from: recognizer.location(in: view), allowing: .estimatedPlane, alignment: .any).first else {
                parent.notice = "No tracked surface. Move slowly and retry."
                return
            }
            let t = hit.worldTransform.columns.3
            let point = SIMD3<Float>(t.x, t.y, t.z)
            if parent.endpoints.count == 2 { parent.endpoints = [] }
            parent.endpoints.append(point)
            parent.notice = parent.endpoints.count == 1 ? "Start recorded. Tap the conduit END." : "AR markers placed. Verify against physical measurements."
            redraw()
        }
        func redraw() {
            guard let view else { return }
            anchors.forEach { view.scene.removeAnchor($0) }
            anchors.removeAll()
            guard parent.endpoints.count == 2, parent.conduitLength > 0 else { return }
            let start = parent.endpoints[0]
            let end = parent.endpoints[1]
            let vector = end - start
            let measured = simd_length(vector)
            guard measured > 0.01 else { return }
            let expected = parent.conduitLength * parent.unitToMeters
            if abs(measured - Float(expected)) / Float(expected) > 0.1 {
                parent.notice = "Warning: AR endpoint distance differs by over 10% from entered conduit length."
            }
            for mark in parent.marks where mark.position >= 0 && mark.position <= parent.conduitLength {
                let fraction = Float(mark.position / parent.conduitLength)
                let point = start + vector * fraction
                let anchor = AnchorEntity(world: point)
                let ball = ModelEntity(mesh: .generateSphere(radius: 0.012), materials: [SimpleMaterial(color: .orange, isMetallic: false)])
                anchor.addChild(ball)
                view.scene.addAnchor(anchor)
                anchors.append(anchor)
            }
        }
    }
}
