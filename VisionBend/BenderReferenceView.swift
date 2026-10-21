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
    @AppStorage("visionbend.language") private var language = "system"
    private func l(_ key: String) -> String { VisionBendLocalization.text(key, language: language) }
    @AppStorage("visionbend.benderProfiles.v1") private var storedProfiles = Data()
    @State private var profiles: [BenderProfile] = []
    @State private var catalogSearch = ""
    @AppStorage("visionbend.pinnedBenderIDs") private var pinnedBenderIDs = ""
    @State private var manufacturer = "Greenlee"
    @State private var model = ""
    @State private var conduitType = "EMT"
    @State private var conduitSize = ""
    @State private var takeUp = ""
    @State private var radius = ""
    @State private var notes = ""
    @State private var source = ""
    @State private var message = ""
    private let brands = ["Greenlee", "Klein Tools", "Milwaukee", "IDEAL", "Gardner Bender", "Other"]
    private var pins: Set<String> {
        Set(pinnedBenderIDs.split(separator: "|").map(String.init))
    }
    private var visibleCatalog: [VerifiedBender] {
        VerifiedBenderCatalog.entries.filter { item in
            catalogSearch.isEmpty ||
            (item.brand + " " + item.model + " " + item.tradeSize + " " + item.conduit)
                .localizedCaseInsensitiveContains(catalogSearch)
        }.sorted {
            let firstPinned = pins.contains($0.id), secondPinned = pins.contains($1.id)
            if firstPinned != secondPinned { return firstPinned }
            return ($0.brand + $0.model + $0.tradeSize) < ($1.brand + $1.model + $1.tradeSize)
        }
    }
    private func toggleFavorite(_ id: String) {
        var selected = pins
        if !selected.insert(id).inserted { selected.remove(id) }
        pinnedBenderIDs = selected.sorted().joined(separator: "|")
    }
    private let conduitTypes = ["EMT", "IMC", "RMC", "PVC", "Other"]

    var body: some View {
        Form {
            Section(l("Manufacturer-verified starter catalog")) {
                TextField(l("Search brand, model or conduit size"), text: $catalogSearch)
                ForEach(visibleCatalog) { item in
                    VStack(alignment: .leading, spacing: 4) {
                        HStack {
                            Text(item.brand + " " + item.model).font(.headline)
                            Spacer()
                            Button {
                                toggleFavorite(item.id)
                            } label: {
                                Image(systemName: pins.contains(item.id) ? "star.fill" : "star")
                            }
                            .buttonStyle(.borderless)
                            .accessibilityLabel(l("Pin favorite bender"))
                        }
                        Text(item.conduit + " " + item.tradeSize)
                        if let deduct = item.deductInches { Text(String(format: "90° deduct: %.3f in", deduct)) }
                        if let radius = item.radiusInches { Text(String(format: "Centerline radius: %.3f in", radius)) }
                        Text(item.notes).font(.caption)
                        if item.deductInches == nil || item.radiusInches == nil {
                            Label(l("Model listed, but some shoe measurements are not verified."),
                                  systemImage: "exclamationmark.triangle")
                                .font(.caption).foregroundStyle(.orange)
                        }
                        if let url = URL(string: item.sourceURL) { Link("Official manufacturer source", destination: url) }
                    }
                }
                Text("Only listed model/size combinations are supported; verify ALL numeric values against the exact manufacturer manual.")
                Link(l("Gardner Bender official bending guide"),
                     destination: URL(string: "https://www.gardnerbender.com/-/media/inriver/INSTR_ZX000300.pdf")!)
                    .font(.caption)
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
        profiles.insert(BenderProfile(manufacturer: manufacturer, model: model, conduitType: conduitType, conduitSize: conduitSize, takeUp: takeUp, radius: radius, notes: notes, source: source), at: 0)
        persist()
        message = "Profile saved on this device."
    }

    private func persist() {
        if let data = try? JSONEncoder().encode(profiles) { storedProfiles = data }
    }
}
