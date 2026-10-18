import SwiftUI
import Vision
import AVFoundation

struct ConduitScanView: View {
    @State private var image: UIImage?
    @State private var result = "Choose a conduit photo to inspect."
    @State private var showPicker = false

    var body: some View {
        VStack(spacing: 16) {
            if let image {
                Image(uiImage: image).resizable().scaledToFit()
            }
            Button("Scan conduit photo") { showPicker = true }
            Text(result).font(.callout)
            Text("Experimental shape detection. Material and diameter must be confirmed manually.")
                .font(.caption).foregroundStyle(.secondary)
        }
        .padding()
        .navigationTitle("Conduit Scan")
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
                DispatchQueue.main.async {
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
