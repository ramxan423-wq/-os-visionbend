import Foundation
import WatchConnectivity

final class PhoneWatchSync: NSObject, ObservableObject, WCSessionDelegate {
    static let shared = PhoneWatchSync()
    @Published var status = "Not connected"

    override init() {
        super.init()
        if WCSession.isSupported() {
            WCSession.default.delegate = self
            WCSession.default.activate()
        }
    }

    func send(projectName: String, marks: [BendMark], units: String) {
        guard WCSession.isSupported() else { status = "Watch not supported"; return }
        let payload: [String: Any] = [
            "name": projectName,
            "language": UserDefaults.standard.string(forKey: "visionbend.language") ?? "system",
            "units": units,
            "marks": marks.sorted { $0.position < $1.position }.map {
                ["position": $0.position, "angle": $0.angle, "direction": $0.direction] as [String: Any]
            }
        ]
        do {
            try WCSession.default.updateApplicationContext(payload)
            status = "Latest plan queued for Watch"
        } catch {
            status = error.localizedDescription
        }
    }

    func session(_ session: WCSession, activationDidCompleteWith state: WCSessionActivationState, error: Error?) {
        DispatchQueue.main.async { self.status = error?.localizedDescription ?? (state == .activated ? "Watch sync ready" : "Watch unavailable") }
    }
    func sessionDidBecomeInactive(_ session: WCSession) {}
    func sessionDidDeactivate(_ session: WCSession) { session.activate() }
}
