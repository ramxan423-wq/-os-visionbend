import SwiftUI
import SceneKit

/// Geometric preview: bend stations are idealized centerline pivots, not mandrel-radius simulations.
struct BendShapePreview: View {
    let marks: [BendMark]
    let length: Double
    var centerlineRadius: Double = 0
    var conduitOutsideDiameter: Double = 0

    var body: some View {
        SceneView(scene: makeScene(), options: [.allowsCameraControl, .autoenablesDefaultLighting])
            .background(Color(uiColor: .secondarySystemBackground))
            .accessibilityLabel("Rotatable theoretical three-dimensional bend centerline")
    }

    private func makeScene() -> SCNScene {
        let scene = SCNScene()
        guard length > 0 else { return scene }
        let scale = Float(2.5 / length)
        let sorted = marks.filter { $0.position >= 0 && $0.position <= length && $0.angle > 0 && $0.angle <= 90 }
            .sorted { $0.position < $1.position }
        var point = SIMD3<Float>(0, 0, 0)
        var heading = SIMD3<Float>(1, 0, 0)
        var previous: Double = 0
        let pipeRadius: CGFloat = CGFloat(max(0.007, min(0.08, conduitOutsideDiameter > 0 ? conduitOutsideDiameter * Double(scale) / 2 : 0.014)))
        func segment(_ distance: Double) {
            let end = point + heading * Float(distance) * scale
            let startV = SCNVector3(point.x, point.y, point.z)
            let endV = SCNVector3(end.x, end.y, end.z)
            let delta = end - point
            let magnitude = sqrt(delta.x * delta.x + delta.y * delta.y + delta.z * delta.z)
            if magnitude > 0.0001 {
                let cylinder = SCNCylinder(radius: pipeRadius, height: CGFloat(magnitude))
                cylinder.radialSegmentCount = 12
                cylinder.firstMaterial?.diffuse.contents = UIColor.systemOrange
                let node = SCNNode(geometry: cylinder)
                node.position = SCNVector3((point.x + end.x) / 2, (point.y + end.y) / 2, (point.z + end.z) / 2)
                node.simdOrientation = simd_quatf(from: SIMD3<Float>(0, 1, 0), to: simd_normalize(delta))
                scene.rootNode.addChildNode(node)
            }
            point = end
            _ = startV
            _ = endV
        }
        for mark in sorted {
            let arcLength = centerlineRadius > 0 ? centerlineRadius * mark.angle * .pi / 180 : 0
            let startArc = max(previous, mark.position - arcLength / 2)
            segment(startArc - previous)
            previous = startArc
            let radians = Float(mark.angle * .pi / 180)
            let axis: SIMD3<Float>
            switch mark.direction {
            case "Down": axis = SIMD3<Float>(0, 0, -1)
            case "Left": axis = SIMD3<Float>(0, 1, 0)
            case "Right": axis = SIMD3<Float>(0, -1, 0)
            default: axis = SIMD3<Float>(0, 0, 1)
            }
            if centerlineRadius > 0 {
                let pieces = 20
                for _ in 0..<pieces {
                    heading = simd_normalize(simd_act(simd_quatf(angle: radians / Float(pieces), axis: axis), heading))
                    segment(arcLength / Double(pieces))
                }
                previous = startArc + arcLength
            } else {
                heading = simd_normalize(simd_act(simd_quatf(angle: radians, axis: axis), heading))
                previous = mark.position
            }
            let marker = SCNSphere(radius: 0.026)
            marker.firstMaterial?.diffuse.contents = UIColor.systemBlue
            let markerNode = SCNNode(geometry: marker)
            markerNode.position = SCNVector3(point.x, point.y, point.z)
            scene.rootNode.addChildNode(markerNode)
        }
        segment(max(0, length - previous))
        let camera = SCNNode()
        camera.camera = SCNCamera()
        camera.position = SCNVector3(2, 2, 5)
        camera.look(at: SCNVector3(1, 0, 0))
        scene.rootNode.addChildNode(camera)
        return scene
    }
}
