import SwiftUI
import AVFoundation
import CoreMotion

struct CameraLevelView: View {
    @State private var permissionGranted = false
    @State private var permissionChecked = false
    @State private var pitch = 0.0
    @State private var roll = 0.0
    @State private var motionAvailable = true
    @State private var pitchZero = 0.0
    @State private var rollZero = 0.0
    @State private var calibrated = false
    private let motion = CMMotionManager()

    var body: some View {
        ZStack {
            if permissionGranted {
                CameraPreview().ignoresSafeArea()
            } else {
                Color.black
                VStack(spacing: 12) {
                    Image(systemName: "camera.fill").font(.largeTitle)
                    Text(permissionChecked ? "Camera access is required. Enable it in Settings." : "Checking camera permission…")
                        .multilineTextAlignment(.center)
                    if permissionChecked {
                        Button("Open Settings") {
                            guard let url = URL(string: UIApplication.openSettingsURLString) else { return }
                            UIApplication.shared.open(url)
                        }
                    }
                }.padding()
            }
            VStack {
                Spacer()
                VStack(spacing: 8) {
                    Text("CAMERA LEVEL").font(.headline)
                    Text(String(format: "Pitch: %.1f°  Roll: %.1f°", pitch - pitchZero, roll - rollZero))
                        .font(.title3.monospacedDigit())
                    HStack(spacing: 14) {
                        Button("Set Zero") {
                            pitchZero = pitch
                            rollZero = roll
                            calibrated = true
                        }
                        Button("Reset") {
                            pitchZero = 0
                            rollZero = 0
                            calibrated = false
                        }
                    }
                    .buttonStyle(.bordered)
                    .disabled(!motionAvailable)
                    Text(calibrated ? "Relative level (zeroed)" : "Device-relative level")
                        .font(.caption)
                    if !motionAvailable { Text("Motion sensor unavailable").font(.caption) }
                    Text("For reference only; calibrate with a physical level.")
                        .font(.caption)
                }
                .padding()
                .frame(maxWidth: .infinity)
                .background(.black.opacity(0.75))
            }
        }
        .onAppear {
            checkPermission()
            startMotion()
        }
        .onDisappear { motion.stopDeviceMotionUpdates() }
    }

    private func checkPermission() {
        switch AVCaptureDevice.authorizationStatus(for: .video) {
        case .authorized: permissionGranted = true; permissionChecked = true
        case .notDetermined:
            AVCaptureDevice.requestAccess(for: .video) { allowed in
                DispatchQueue.main.async { permissionGranted = allowed; permissionChecked = true }
            }
        default: permissionGranted = false; permissionChecked = true
        }
    }

    private func startMotion() {
        guard motion.isDeviceMotionAvailable else { motionAvailable = false; return }
        motion.deviceMotionUpdateInterval = 0.1
        motion.startDeviceMotionUpdates(to: .main) { data, _ in
            guard let data = data else { return }
            pitch = data.attitude.pitch * 180 / .pi
            roll = data.attitude.roll * 180 / .pi
        }
    }
}

private struct CameraPreview: UIViewRepresentable {
    func makeUIView(context: Context) -> PreviewView {
        let view = PreviewView()
        let session = AVCaptureSession()
        session.sessionPreset = .high
        guard let device = AVCaptureDevice.default(for: .video),
              let input = try? AVCaptureDeviceInput(device: device),
              session.canAddInput(input) else { return view }
        session.addInput(input)
        let output = AVCaptureVideoDataOutput()
        if session.canAddOutput(output) { session.addOutput(output) }
        view.previewLayer.session = session
        context.coordinator.session = session
        DispatchQueue.global(qos: .userInitiated).async { session.startRunning() }
        return view
    }

    func updateUIView(_ uiView: PreviewView, context: Context) {}

    func makeCoordinator() -> Coordinator { Coordinator() }

    static func dismantleUIView(_ uiView: PreviewView, coordinator: Coordinator) {
        let session = coordinator.session
        DispatchQueue.global(qos: .userInitiated).async { session?.stopRunning() }
        uiView.previewLayer.session = nil
    }

    final class Coordinator {
        var session: AVCaptureSession?
    }
}

private final class PreviewView: UIView {
    override class var layerClass: AnyClass { AVCaptureVideoPreviewLayer.self }
    var previewLayer: AVCaptureVideoPreviewLayer { layer as! AVCaptureVideoPreviewLayer }
    override init(frame: CGRect) {
        super.init(frame: frame)
        previewLayer.videoGravity = .resizeAspectFill
    }
    required init?(coder: NSCoder) { fatalError("init(coder:) has not been implemented") }
}
