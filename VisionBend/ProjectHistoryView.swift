import SwiftUI

struct SavedBend: Codable, Identifiable {
    var id: UUID
    var date: Date
    var mode: String
    var firstValue: Double
    var secondValue: Double
    var result: String
}

@MainActor
final class BendHistory: ObservableObject {
    @Published private(set) var items: [SavedBend] = []
    private let storageKey = "visionbend.savedBends.v1"

    init() { load() }

    func add(mode: String, first: Double, second: Double, result: String) {
        items.insert(SavedBend(id: UUID(), date: Date(), mode: mode,
                               firstValue: first, secondValue: second, result: result), at: 0)
        save()
    }

    func remove(at offsets: IndexSet) {
        items.remove(atOffsets: offsets)
        save()
    }

    private func load() {
        guard let data = UserDefaults.standard.data(forKey: storageKey),
              let decoded = try? JSONDecoder().decode([SavedBend].self, from: data)
        else { return }
        items = decoded
    }

    private func save() {
        guard let data = try? JSONEncoder().encode(items) else { return }
        UserDefaults.standard.set(data, forKey: storageKey)
    }
}

struct ProjectHistoryView: View {
    @ObservedObject var history: BendHistory

    var body: some View {
        NavigationStack {
            List {
                if history.items.isEmpty {
                    VStack(spacing: 8) {
                        Image(systemName: "tray").font(.title2)
                        Text("No Saved Bends").font(.headline)
                        Text("Save a calculation to see it here.").font(.caption)
                    }
                    .frame(maxWidth: .infinity)
                    .foregroundStyle(.secondary)
                }
                ForEach(history.items) { bend in
                    VStack(alignment: .leading, spacing: 5) {
                        Text(bend.mode).font(.headline)
                        Text(bend.date, style: .date).font(.caption).foregroundStyle(.secondary)
                        Text(bend.result).font(.body.monospacedDigit())
                        Text("Inputs: \(bend.firstValue.formatted()) / \(bend.secondValue.formatted())")
                            .font(.caption).foregroundStyle(.secondary)
                    }.padding(.vertical, 4)
                }
                .onDelete(perform: history.remove)
            }
            .navigationTitle("Saved Bends")
            .toolbar { EditButton() }
        }
    }
}
