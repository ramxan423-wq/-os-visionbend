import SwiftUI

struct BenderReferenceView: View {
    @AppStorage("visionbend.language") private var language = "system"
    @AppStorage("visionbend.units") private var selectedUnits = 0
    private func l(_ key: String) -> String { VisionBendLocalization.text(key, language: language) }
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
    @State private var referenceMark = "Arrow"
    @State private var message = ""
    private let brands = ["Greenlee", "Klein Tools", "IDEAL", "Gardner Bender", "Other"]
    private let conduitTypes = ["EMT", "IMC", "RMC", "PVC", "Other"]

    var body: some View {
        Form {
            Section(l("Manufacturer-verified starter catalog")) {
                ForEach(VerifiedBenderCatalog.entries) { item in
                    VStack(alignment: .leading, spacing: 4) {
                        Text(item.brand + " " + item.model).font(.headline)
                        Text(item.conduit + " " + item.tradeSize)
                        if let deduct = item.deductInches { Text(String(format: "90° deduct: %.3f in", deduct)) }
                        if let radius = item.radiusInches { Text(String(format: "Centerline radius: %.3f in", radius)) }
                        Text(item.notes).font(.caption)
                        if let url = URL(string: item.sourceURL) { Link("Official manufacturer source", destination: url) }
                    }
                }
                Text("Only the listed model and size combinations are verified. Other models require exact manufacturer documentation.")
                    .font(.caption).foregroundStyle(.secondary)
            }
            Section(l("Bender and conduit")) {
                Picker(l("Manufacturer"), selection: $manufacturer) {
                    ForEach(brands, id: \.self) { Text($0) }
                }
                TextField(l("Exact model / part number"), text: $model)
                Picker(l("Conduit type"), selection: $conduitType) {
                    ForEach(conduitTypes, id: \.self) { Text($0) }
                }
                TextField(l("Conduit trade size"), text: $conduitSize)
                TextField(l("Manual take-up (selected units)"), text: $takeUp).keyboardType(.decimalPad)
                TextField(l("Centerline radius (selected units)"), text: $radius).keyboardType(.decimalPad)
                Picker("Reference mark for first 90°", selection: $referenceMark) {
                    Text("Arrow").tag("Arrow")
                    Text("Hook Front").tag("Hook Front")
                }
                TextField(l("Manufacturer manual / page / URL"), text: $source)
                TextField(l("Calibration and field notes"), text: $notes)
                Button(l("Save Bender Profile")) { saveProfile() }
                if !message.isEmpty { Text(message).font(.caption) }
            }
            Section(l("Saved bender profiles")) {
                if profiles.isEmpty { Text("No saved profiles").foregroundStyle(.secondary) }
                ForEach(profiles) { item in
                    VStack(alignment: .leading, spacing: 4) {
                        Text(item.manufacturer + " " + item.model).font(.headline)
                        Text(item.conduitType + " " + item.conduitSize)
                        Text("Take-up: " + item.takeUp + " · Radius: " + item.radius)
                        Text("Units: " + (item.unitCode.flatMap(MeasurementUnit.init(rawValue:))?.symbol ?? "not recorded — re-enter to calibrate"))
                            .font(.caption).foregroundStyle(.secondary)
                        if !item.source.isEmpty { Text("Source: " + item.source).font(.caption) }
                    }
                }
                .onDelete { offsets in profiles.remove(atOffsets: offsets); persist() }
            }
            Section(l("Important")) {
                Text("These are user-entered values, NOT a manufacturer-verified catalogue. Check exact model, conduit size and the official manual before bending.")
                Text("PVC requires its own heating and minimum-radius instructions. Do not apply metal conduit take-up automatically.")
            }
        }
        .navigationTitle(l("Bender Reference"))
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
        profiles.insert(BenderProfile(manufacturer: manufacturer, model: model, conduitType: conduitType, conduitSize: conduitSize, takeUp: takeUp, radius: radius, notes: notes, source: source, unitCode: selectedUnits, referenceMark: referenceMark), at: 0)
        persist()
        message = "Profile saved on this device."
    }

    private func persist() {
        if let data = try? JSONEncoder().encode(profiles) { storedProfiles = data }
    }
}
