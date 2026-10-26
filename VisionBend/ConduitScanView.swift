import SwiftUI
import Vision
import AVFoundation

struct ConduitScanView: View {
    @AppStorage("visionbend.language") private var language = "system"
    private func l(_ key: String) -> String { VisionBendLocalization.text(key, language: language) }
    @State private var image: UIImage?
    @State private var result = "Choose a conduit photo to inspect."
    @State private var showPicker = false
    @State private var showSourceSelection = false
    @State private var pickerSource: UIImagePickerController.SourceType = .photoLibrary
    @State private var referenceWidth = ""
    @State private var referencePixels = ""
    @State private var measuredPixels: Double?
    @State private var useReference = true
    @State private var conduitEdgeMarks: [CGPoint] = []
    @State private var referenceEdgeMarks: [CGPoint] = []
    @State private var markingTarget = "conduit"
    @State private var manualMeasurement = false

    var body: some View {
        VStack(spacing: 16) {
            if let image {
                GeometryReader { geometry in
                    let imageRect = fittedImageRect(imageSize: image.size, container: geometry.size)
                    ZStack {
                        Image(uiImage: image).resizable().scaledToFit()
                            .frame(width: geometry.size.width, height: geometry.size.height)
                        ForEach(conduitEdgeMarks.indices, id: \.self) { index in
                            Circle().fill(.orange).frame(width: 13, height: 13)
                                .overlay(Circle().stroke(.white, lineWidth: 2))
                                .position(x: imageRect.minX + conduitEdgeMarks[index].x * imageRect.width,
                                          y: imageRect.minY + conduitEdgeMarks[index].y * imageRect.height)
                        }
                        ForEach(referenceEdgeMarks.indices, id: \.self) { index in
                            Circle().fill(.cyan).frame(width: 13, height: 13)
                                .overlay(Circle().stroke(.white, lineWidth: 2))
                                .position(x: imageRect.minX + referenceEdgeMarks[index].x * imageRect.width,
                                          y: imageRect.minY + referenceEdgeMarks[index].y * imageRect.height)
                        }
                    }
                    .contentShape(Rectangle())
                    .gesture(SpatialTapGesture().onEnded { value in
                        recordManualMark(at: value.location, image: image, viewSize: geometry.size)
                    })
                }
                .frame(height: 270)
                HStack(spacing: 8) {
                    Button("Mark conduit edges") { markingTarget = "conduit"; conduitEdgeMarks = []; measuredPixels = nil; manualMeasurement = true }
                        .buttonStyle(.bordered).tint(markingTarget == "conduit" ? .orange : .secondary)
                    Button("Mark reference edges") { markingTarget = "reference"; referenceEdgeMarks = []; referencePixels = ""; manualMeasurement = true }
                        .buttonStyle(.bordered).tint(markingTarget == "reference" ? .cyan : .secondary)
                }.font(.caption)
                Text("Tap two edges of the conduit and two edges of a known-size object in the same plane. Orange = conduit; blue = reference. Confirm with calipers.")
                    .font(.caption).foregroundStyle(.secondary)
            }
            Button(l("Scan conduit photo")) { showSourceSelection = true }
            Toggle(l("Use same-plane size reference"), isOn: $useReference)
            if useReference {
                TextField(l("Reference object actual width (mm)"), text: $referenceWidth).keyboardType(.decimalPad)
                TextField(l("Reference object width in photo (pixels)"), text: $referencePixels).keyboardType(.decimalPad)
                if let measuredPixels,
                   let width = Double(referenceWidth.replacingOccurrences(of: ",", with: ".")),
                   let pixels = Double(referencePixels.replacingOccurrences(of: ",", with: ".")),
                   width > 0, pixels > 0 {
                    if let estimate = ConduitDiameterMath.calibratedDiameter(conduitPixels: measuredPixels, referencePixels: pixels, referenceMillimeters: width) {
                        Text(String(format: l("Estimated width: %.1f mm (± %.1f mm pixel error only)"), estimate.millimeters, estimate.uncertaintyMillimeters))
                            .font(.headline)
                        Text(l("This uncertainty excludes perspective and wrong-edge detection. Not a certified diameter."))
                            .font(.caption).foregroundStyle(.secondary)
                    }
                }
            } else {
                Text(l("Experimental estimate requires a known-size reference in the same image plane. Contour thickness is not a verified outer diameter. Confirm with calipers."))
                    .font(.caption).foregroundStyle(.secondary)
            }
            Text(l(result)).font(.callout)
            Text(l("Experimental estimate requires a known-size reference in the same image plane. Contour thickness is not a verified outer diameter. Confirm with calipers."))
                .font(.caption).foregroundStyle(.secondary)
        }
        .padding()
        .navigationTitle(l("Conduit Scan"))
        .confirmationDialog("Conduit photo source", isPresented: $showSourceSelection) {
            if UIImagePickerController.isSourceTypeAvailable(.camera) {
                Button("Take Photo") { pickerSource = .camera; showPicker = true }
            }
            Button("Choose from Library") { pickerSource = .photoLibrary; showPicker = true }
        }
        .sheet(isPresented: $showPicker) {
            ConduitImagePicker(sourceType: pickerSource) { picked in
                image = picked
                measuredPixels = nil
                referencePixels = ""
                conduitEdgeMarks = []
                referenceEdgeMarks = []
                manualMeasurement = false
                result = "Analyzing photo…"
                scan(picked)
            }
        }
    }

    private func scan(_ image: UIImage) {
        guard let cgImage = image.cgImage else { measuredPixels = nil; result = "Image unavailable"; return }
        let request = VNDetectContoursRequest()
        request.maximumImageDimension = 512
        DispatchQueue.global(qos: .userInitiated).async {
            do {
                try VNImageRequestHandler(cgImage: cgImage, options: [:]).perform([request])
                let contours = request.results?.first?.topLevelContours ?? []
                let candidates = contours.filter {
                    let rect = $0.normalizedPath.boundingBox
                    return max(rect.width, rect.height) > 0.2 &&
                           max(rect.width, rect.height) / max(0.001, min(rect.width, rect.height)) > 3.5
                }
                let candidate = candidates.max { a, b in
                    let aa = a.normalizedPath.boundingBox
                    let bb = b.normalizedPath.boundingBox
                    return max(aa.width, aa.height) < max(bb.width, bb.height)
                }
                let imageWidth = Double(cgImage.width)
                let imageHeight = Double(cgImage.height)
                let widthPixels = candidate.map { item -> Double in
                    let rect = item.normalizedPath.boundingBox
                    return min(Double(rect.width) * imageWidth, Double(rect.height) * imageHeight)
                }
                DispatchQueue.main.async {
                    if !manualMeasurement {
                        measuredPixels = widthPixels
                        result = candidates.isEmpty ? "No elongated object detected. You can mark both edges manually." : String(format: l("Possible conduit shape detected (%d candidates). Confirm manually."), candidates.count)
                    }
                }
            } catch {
                DispatchQueue.main.async {
                    if !manualMeasurement {
                        measuredPixels = nil
                        result = "Unable to analyze this photo. Mark its edges manually or try another image."
                    }
                }
            }
        }
    }

    private func fittedImageRect(imageSize: CGSize, container: CGSize) -> CGRect {
        guard imageSize.width > 0, imageSize.height > 0, container.width > 0, container.height > 0 else { return .zero }
        let scale = min(container.width / imageSize.width, container.height / imageSize.height)
        let width = imageSize.width * scale
        let height = imageSize.height * scale
        return CGRect(x: (container.width - width) / 2, y: (container.height - height) / 2, width: width, height: height)
    }

    private func recordManualMark(at location: CGPoint, image: UIImage, viewSize: CGSize) {
        let bounds = fittedImageRect(imageSize: image.size, container: viewSize)
        guard bounds.width > 0, bounds.height > 0, bounds.contains(location) else { return }
        let point = CGPoint(x: (location.x - bounds.minX) / bounds.width,
                            y: (location.y - bounds.minY) / bounds.height)
        manualMeasurement = true
        if markingTarget == "conduit" {
            if conduitEdgeMarks.count >= 2 { conduitEdgeMarks.removeAll() }
            conduitEdgeMarks.append(point)
        } else {
            if referenceEdgeMarks.count >= 2 { referenceEdgeMarks.removeAll() }
            referenceEdgeMarks.append(point)
        }
        guard conduitEdgeMarks.count == 2, referenceEdgeMarks.count == 2 else {
            result = "Mark two orange conduit edges and two blue reference edges."
            return
        }
        let conduitWidth = hypot((conduitEdgeMarks[0].x - conduitEdgeMarks[1].x) * image.size.width,
                                 (conduitEdgeMarks[0].y - conduitEdgeMarks[1].y) * image.size.height)
        let referenceWidthPixels = hypot((referenceEdgeMarks[0].x - referenceEdgeMarks[1].x) * image.size.width,
                                         (referenceEdgeMarks[0].y - referenceEdgeMarks[1].y) * image.size.height)
        guard conduitWidth.isFinite, referenceWidthPixels.isFinite, conduitWidth > 1, referenceWidthPixels > 1 else {
            result = "Selected edges are too close together. Mark the opposite sides of each object."
            measuredPixels = nil
            return
        }
        measuredPixels = conduitWidth
        referencePixels = String(format: "%.3f", referenceWidthPixels)
        useReference = true
        result = "Manual edge-to-edge ratio is ready. Enter the reference object's actual width in mm. Calipers are still required for verification."
    }
}

private struct ConduitImagePicker: UIViewControllerRepresentable {
    let sourceType: UIImagePickerController.SourceType
    let onImage: (UIImage) -> Void

    func makeUIViewController(context: Context) -> UIImagePickerController {
        let picker = UIImagePickerController()
        picker.sourceType = sourceType
        picker.delegate = context.coordinator
        return picker
    }
    func updateUIViewController(_ uiViewController: UIImagePickerController, context: Context) {}
    func makeCoordinator() -> Coordinator { Coordinator(onImage: onImage) }

    final class Coordinator: NSObject, UINavigationControllerDelegate, UIImagePickerControllerDelegate {
        let onImage: (UIImage) -> Void
        init(onImage: @escaping (UIImage) -> Void) { self.onImage = onImage }
        func imagePickerController(_ picker: UIImagePickerController, didFinishPickingMediaWithInfo info: [UIImagePickerController.InfoKey: Any]) {
            if let image = info[.originalImage] as? UIImage { onImage(image) }
            picker.dismiss(animated: true)
        }
        func imagePickerControllerDidCancel(_ picker: UIImagePickerController) { picker.dismiss(animated: true) }
    }
}
