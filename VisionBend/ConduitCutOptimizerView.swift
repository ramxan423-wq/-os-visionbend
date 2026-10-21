import SwiftUI

struct ConduitCutOptimizerView: View {
    @AppStorage("visionbend.language") private var language = "system"
    @AppStorage("visionbend.units") private var selectedUnits = 0
    @State private var inputUnits = 0
    private var currentUnit: MeasurementUnit { MeasurementUnit(rawValue: selectedUnits) ?? .millimeters }
    private func l(_ key: String) -> String { VisionBendLocalization.text(key, language: language) }
    @State private var stock = "3000"
    @State private var kerf = "3"
    @State private var cuts = "850, 850, 420, 300"
    @State private var result = ""
    var body: some View {
        Form {
            Section(l("Stock cutting")) {
                TextField(l("Stock length (same units)"), text: $stock).keyboardType(.decimalPad)
                TextField(l("Saw kerf per cut"), text: $kerf).keyboardType(.decimalPad)
                TextField(l("Required pieces, comma separated"), text: $cuts)
                Text(VisionBendLocalization.text("Use semicolons between lengths when entering decimal commas.", turkish: "Ondalık sayılarda virgül kullanıyorsanız uzunlukları noktalı virgülle ayırın.", language: language))
                    .font(.caption).foregroundStyle(.secondary)
                Text(l("Stock length (same units)") + ": " + currentUnit.symbol)
                    .font(.caption).foregroundStyle(.secondary)
                Button(l("Optimize cuts")) { calculate() }
            }
            Section(l("Cut plan")) {
                Text(result.isEmpty ? l("Enter piece lengths to generate a first-fit decreasing cut plan.") : result)
                    .font(.system(.body, design: .monospaced))
            }
            Section(l("Important")) {
                Text(l("Simple straight-stock cutting plan. Does not calculate bend developed lengths or account for damaged stock."))
            }
        }
        .navigationTitle(l("Conduit Cut Planner"))
        .onAppear { updateUnits() }
        .onChange(of: selectedUnits) { _ in updateUnits() }
    }
    private func updateUnits() {
        guard let from = MeasurementUnit(rawValue: inputUnits), from != currentUnit else { return }
        stock = FieldInputNumber.convertedText(stock, from: from, to: currentUnit)
        kerf = FieldInputNumber.convertedText(kerf, from: from, to: currentUnit)
        cuts = ConduitCutInput.convertedText(cuts, from: from, to: currentUnit)
        result = ""
        inputUnits = currentUnit.rawValue
    }
    private func calculate() {
        func parse(_ s: String) -> Double? { FieldInputNumber.parse(s, unit: currentUnit) }
        guard let length = parse(stock), let blade = parse(kerf),
              length.isFinite, blade.isFinite, length > 0, blade >= 0 else {
            result = l("Invalid stock length or saw kerf."); return
        }
        guard let enteredPieces = ConduitCutInput.lengths(cuts, unit: currentUnit) else {
            result = l("Invalid piece length. Check every entered value."); return
        }
        let pieces = enteredPieces.sorted(by: >)
        guard !pieces.isEmpty, pieces.count <= 500, pieces.allSatisfy({ $0.isFinite && $0 > 0 && $0 + blade <= length }) else {
            result = l("Enter 1–500 positive pieces, each fitting the stock."); return
        }
        var bins: [[Double]] = []
        var remaining: [Double] = []
        for piece in pieces {
            if let i = remaining.firstIndex(where: { $0 >= piece + blade }) {
                bins[i].append(piece)
                remaining[i] -= piece + blade
            } else {
                bins.append([piece])
                remaining.append(length - piece - blade)
            }
        }
        result = bins.enumerated().map { i, parts in
            l("Stock") + " \(i + 1): " + parts.map { String(format: "%.1f", $0) }.joined(separator: " + ") +
            String(format: "\n%@: %.1f", l("Remaining"), remaining[i])
        }.joined(separator: "\n\n") + String(format: "\n\n%@: %d | %@: %.1f", l("Total stock"), bins.count, l("Total leftover"), remaining.reduce(0, +))
    }
}
