import SwiftUI

@main
struct VisionBendWatchApp: App {
    var body: some Scene {
        WindowGroup { WatchMarksView() }
    }
}

struct WatchMarksView: View {
    @State private var steps: [String] = ["Open VisionBend on iPhone to prepare your bend plan."]
    var body: some View {
        NavigationStack {
            List {
                Section("Bend marks") {
                    ForEach(steps, id: \.self) { step in Text(step).font(.caption) }
                }
                Section {
                    Text("Watch companion preview. Automatic iPhone synchronization is not yet configured.")
                        .font(.caption2).foregroundStyle(.secondary)
                }
            }
            .navigationTitle("VisionBend")
        }
    }
}
