import SwiftUI

struct SavedBend: Codable, Identifiable {
    var id: UUID
    var date: Date
    var mode: String
    var firstValue: Double
    var secondValue: Double
    var result: String
    var projectName: String?
    var notes: String?
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

    func update(id: UUID, projectName: String, notes: String) {
        guard let index = items.firstIndex(where: { $0.id == id }) else { return }
        items[index].projectName = projectName
        items[index].notes = notes
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
    @AppStorage("visionbend.language") private var language = "system"
    private func l(_ key: String) -> String { VisionBendLocalization.text(key, language: language) }
    @ObservedObject var history: BendHistory
    @State private var editing: SavedBend?
    @State private var exporting: SavedBend?
    @State private var projectName = ""
    @State private var notes = ""

    var body: some View {
        NavigationStack {
            List {
                if history.items.isEmpty {
                    VStack(spacing: 8) {
                        Image(systemName: "tray").font(.title2)
                        Text(l("No Saved Bends")).font(.headline)
                        Text(l("Save a calculation to see it here.")).font(.caption)
                    }
                    .frame(maxWidth: .infinity)
                    .foregroundStyle(.secondary)
                }
                ForEach(history.items) { bend in
                    VStack(alignment: .leading, spacing: 5) {
                        Text(bend.projectName?.isEmpty == false ? bend.projectName! : bend.mode).font(.headline)
                        Text(bend.mode).font(.caption).foregroundStyle(.secondary)
                        Text(bend.date, style: .date).font(.caption).foregroundStyle(.secondary)
                        Text(bend.result).font(.body.monospacedDigit())
                        Text("Inputs: \(bend.firstValue.formatted()) / \(bend.secondValue.formatted())")
                            .font(.caption).foregroundStyle(.secondary)
                        if let notes = bend.notes, !notes.isEmpty { Text(notes).font(.caption) }
                        Button(l("Export / Share")) { exporting = bend }
                        Button(l("Edit project details")) {
                            editing = bend
                            projectName = bend.projectName ?? ""
                            notes = bend.notes ?? ""
                        }
                    }.padding(.vertical, 4)
                }
                .onDelete(perform: history.remove)
            }
            .navigationTitle(l("Saved Bends"))
            .toolbar { EditButton() }
            .sheet(item: $exporting) { bend in
                NavigationStack {
                    ProjectExportView(project: BendProjectExport(title: bend.projectName ?? bend.mode, mode: bend.mode, firstValue: bend.firstValue, secondValue: bend.secondValue, result: bend.result, notes: bend.notes))
                        .navigationTitle("Export Project")
                        .toolbar { ToolbarItem(placement: .confirmationAction) { Button("Done") { exporting = nil } } }
                }
            }
            .sheet(item: $editing) { bend in
                NavigationStack {
                    Form {
                        TextField("Project name", text: $projectName)
                        TextField("Notes", text: $notes, axis: .vertical)
                    }
                    .navigationTitle("Edit Project")
                    .toolbar {
                        ToolbarItem(placement: .cancellationAction) { Button("Cancel") { editing = nil } }
                        ToolbarItem(placement: .confirmationAction) {
                            Button("Save") {
                                history.update(id: bend.id, projectName: projectName, notes: notes)
                                editing = nil
                            }
                        }
                    }
                }
            }
        }
    }
}
