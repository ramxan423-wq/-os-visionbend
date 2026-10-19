import SwiftUI
import Vision
import AVFoundation

struct ConduitScanView: View {
    @AppStorage("visionbend.language") private var language = "system"
    private func l(_ key: String) -> String { VisionBendLocalization.text(key, language: language) }
    @State private var image: UIImage?
    @State private var result = "Choose a conduit photo to inspect."
    @State private var showPicker = false
    @State private var referenceWidth = ""
    @State private var referencePixels = ""
    @State private var measuredPixels: Double?
    @State private var useReference = true

    var body: some View {
        VStack(spacing: 16) {
            if let image {
                Image(uiImage: image).resizable().scaledToFit()
            }
            Button(l("Scan conduit photo")) { showPicker = true }
            Toggle(l("Use same-plane size reference"), isOn: $useReference)
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
            Text(l(result)).font(.callout)
            Text(l("Experimental estimate requires a known-size reference in the same image plane. Contour thickness is not a verified outer diameter. Confirm with calipers."))
                .font(.caption).foregroundStyle(.secondary)
        }
        .padding()
        .navigationTitle(l("Conduit Scan"))
        .sheet(isPresented: $showPicker) {
            ConduitImagePicker { picked in
                image = picked
                scan(picked)
            }
        }
    }

    private func scan(_ image: UIImage) {
        guard let cgImage = image.cgImage else { result = "Image unavailable"; return }
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
                    measuredPixels = widthPixels
                    result = candidates.isEmpty ? "No elongated object detected." : "Possible conduit shape detected (\(candidates.count) candidates). Confirm manually."
                }
            } catch {
                DispatchQueue.main.async { result = error.localizedDescription }
            }
        }
    }
}

private struct ConduitImagePicker: UIViewControllerRepresentable {
    let onImage: (UIImage) -> Void

    func makeUIViewController(context: Context) -> UIImagePickerController {
        let picker = UIImagePickerController()
        picker.sourceType = .photoLibrary
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
