import SwiftUI

struct BenderProfile: Codable, Identifiable {
    var id = UUID()
    var manufacturer: String
    var model: String
    var conduitType: String
    var conduitSize: String
    var takeUp: String
    var radius: String
    var notes: String
    var source: String
}

struct BenderReferenceView: View {
    @AppStorage("visionbend.benderProfiles.v1") private var storedProfiles = Data()
    @State private var profiles: [BenderProfile] = []
    @State private var manufacturer = "Greenlee"
    @State private var model = ""
    @State private var conduitType = "EMT"
    @State private var conduitSize = ""
    @State private var takeUp = ""
    @State private var radius = ""
    @State private var notes = ""
    @State private var source = ""
    @State private var message = ""
    private let brands = ["Greenlee", "Klein Tools", "IDEAL", "Gardner Bender", "Other"]
    private let conduitTypes = ["EMT", "IMC", "RMC", "PVC", "Other"]

    var body: some View {
        Form {
            Section("Bender and conduit") {
                Picker("Manufacturer", selection: $manufacturer) {
                    ForEach(brands, id: \.self) { Text($0) }
                }
                TextField("Exact model / part number", text: $model)
                Picker("Conduit type", selection: $conduitType) {
                    ForEach(conduitTypes, id: \.self) { Text($0) }
                }
                TextField("Conduit trade size", text: $conduitSize)
                TextField("Manual take-up (selected units)", text: $takeUp).keyboardType(.decimalPad)
                TextField("Centerline radius (selected units)", text: $radius).keyboardType(.decimalPad)
                TextField("Manufacturer manual / page / URL", text: $source)
                TextField("Calibration and field notes", text: $notes)
                Button("Save Bender Profile") { saveProfile() }
                if !message.isEmpty { Text(message).font(.caption) }
            }
            Section("Saved bender profiles") {
                if profiles.isEmpty { Text("No saved profiles").foregroundStyle(.secondary) }
                ForEach(profiles) { item in
                    VStack(alignment: .leading, spacing: 4) {
                        Text(item.manufacturer + " " + item.model).font(.headline)
                        Text(item.conduitType + " " + item.conduitSize)
                        Text("Take-up: " + item.takeUp + " · Radius: " + item.radius)
                        if !item.source.isEmpty { Text("Source: " + item.source).font(.caption) }
                    }
                }
                .onDelete { offsets in profiles.remove(atOffsets: offsets); persist() }
            }
            Section("Important") {
                Text("These are user-entered values, NOT a manufacturer-verified catalogue. Check exact model, conduit size and the official manual before bending.")
                Text("PVC requires its own heating and minimum-radius instructions. Do not apply metal conduit take-up automatically.")
            }
        }
        .navigationTitle("Bender Reference")
        .toolbar { EditButton() }
        .onAppear { profiles = (try? JSONDecoder().decode([BenderProfile].self, from: storedProfiles)) ?? [] }
    }

    private func saveProfile() {
        guard !model.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty,
              !conduitSize.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty,
              let t = Double(takeUp.replacingOccurrences(of: ",", with: ".")), t.isFinite, t >= 0,
              let rad = Double(radius.replacingOccurrences(of: ",", with: ".")), rad.isFinite, rad > 0 else {
            message = "Enter a model, conduit size, nonnegative take-up and positive radius."
            return
        }
        profiles.insert(BenderProfile(manufacturer: manufacturer, model: model, conduitType: conduitType, conduitSize: conduitSize, takeUp: takeUp, radius: radius, notes: notes, source: source), at: 0)
        persist()
        message = "Profile saved on this device."
    }

    private func persist() {
        if let data = try? JSONEncoder().encode(profiles) { storedProfiles = data }
    }
}
