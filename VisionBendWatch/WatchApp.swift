import SwiftUI
import WatchConnectivity

final class WatchPlanStore: NSObject, ObservableObject, WCSessionDelegate {
    @Published var name = "No synced project"
    @Published var units = ""
    @Published var marks: [String] = []

    override init() {
        super.init()
        restore()
        if WCSession.isSupported() {
            WCSession.default.delegate = self
            WCSession.default.activate()
        }
    }

    private func restore() {
        guard let payload = UserDefaults.standard.dictionary(forKey: "lastWatchPlan") else { return }
        apply(payload)
    }

    private func apply(_ payload: [String: Any]) {
        name = payload["name"] as? String ?? "Project"
        units = payload["units"] as? String ?? ""
        let values = payload["marks"] as? [[String: Any]] ?? []
        marks = values.map { item in
            let position = item["position"] as? Double ?? 0
            let angle = item["angle"] as? Double ?? 0
            let direction = item["direction"] as? String ?? ""
            return String(format: "%.2f %@ · %.1f° %@", position, units, angle, direction)
        }
    }

    func session(_ session: WCSession, didReceiveApplicationContext applicationContext: [String: Any]) {
        DispatchQueue.main.async {
            UserDefaults.standard.set(applicationContext, forKey: "lastWatchPlan")
            self.apply(applicationContext)
        }
    }

    func session(_ session: WCSession, activationDidCompleteWith state: WCSessionActivationState, error: Error?) {
        let context = session.receivedApplicationContext
        if !context.isEmpty {
            DispatchQueue.main.async {
                UserDefaults.standard.set(context, forKey: "lastWatchPlan")
                self.apply(context)
            }
        }
    }
}

@main
struct VisionBendWatchApp: App {
    var body: some Scene { WindowGroup { WatchMarksView() } }
}

struct WatchMarksView: View {
    @StateObject private var store = WatchPlanStore()
    var body: some View {
        NavigationStack {
            List {
                Section(store.name) {
                    if store.marks.isEmpty { Text("Send a plan from VisionBend on iPhone.") }
                    ForEach(store.marks, id: \.self) { Text($0).font(.caption) }
                }
                Text("The latest received plan remains available offline.")
                    .font(.caption2).foregroundStyle(.secondary)
            }
            .navigationTitle("VisionBend")
        }
    }
}
