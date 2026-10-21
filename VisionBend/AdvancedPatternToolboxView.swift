import SwiftUI

/// A field worksheet for additional theoretical bend patterns.
/// All marks are centerline layout stations, not shoe/arrow instructions.
struct AdvancedPatternToolboxView: View {
    @AppStorage("visionbend.language") private var language = "system"
    @AppStorage("visionbend.units") private var units = 0
    @AppStorage("visionbend.inputStyle.slider") private var useSliders = false
    @State private var inputUnits = 0
    @State private var kind = "Matching Bends Offset"
    @State private var shape = AdvancedFieldPatterns.ObstacleShape.circle
    @State private var length = "3000"
    @State private var rise = "150"
    @State private var angle = "30"
    @State private var start = "200"
    @State private var spacing = "200"
    @State private var width = "250"
    @State private var height = "150"
    @State private var clearance = "30"
    @State private var radius = ""
    @State private var desiredStub = "450"
    @State private var documentedTakeUp = ""
    @State private var manualConfirmed = false
    @State private var quantity = 3
    @State private var rows: [PatternRow] = []
    @State private var output = ""
    @State private var fatalError = false

    private struct PatternRow: Identifiable {
        let id = UUID()
        let title: String
        let stations: [AdvancedFieldPatterns.Station]
    }

    private func l(_ english: String) -> String {
        VisionBendLocalization.text(english, language: language)
    }
    private var unit: MeasurementUnit { MeasurementUnit(rawValue: units) ?? .millimeters }
    private func number(_ input: String) -> Double? { FieldInputNumber.parse(input, unit: unit) }
    private func parsedAngle() -> Double? {
        guard let value = Double(angle.replacingOccurrences(of: ",", with: ".")), value.isFinite else { return nil }
        return value
    }
    private var unitLabel: String { unit.symbol }
    private let kinds = [
        "Matching Bends Offset", "Matching Centers Offset", "Parallel Offset",
        "Kick with 90°", "Matching Bend Kick", "Matching Center Kick",
        "Parallel Kick", "Parallel Kick Forward", "Compound 90° Obstruction"
    ]
    private var possibleLength: Double { max(1, number(length) ?? 1) }
    private var report: FieldQuickCheck.Report {
        let checks = rows.map {
            FieldQuickCheck.evaluate(length: possibleLength, marks: $0.stations,
                                     minimumStraight: 0, centerlineRadius: number(radius),
                                     hasVerifiedReference: false)
        }
        if checks.contains(where: { $0.severity == .impossible }) {
            return FieldQuickCheck.Report(severity: .impossible,
                                          findings: checks.flatMap(\.findings))
        }
        return FieldQuickCheck.Report(severity: .caution,
                                      findings: checks.flatMap(\.findings))
    }

    var body: some View {
        Form {
            Section(l("Bend family")) {
                Picker(l("Pattern"), selection: $kind) {
                    ForEach(kinds, id: \.self) { name in Text(l(name)).tag(name) }
                }
                Text(l("Centerline geometry only; never substitute these stations for manufacturer-specific arrow or hook marks."))
                    .font(.caption).foregroundStyle(.orange)
            }
            Section(l("Measurements") + " (" + unitLabel + ")") {
                TextField(l("Total conduit length"), text: $length).keyboardType(.decimalPad)
                TextField(l("Starting position"), text: $start).keyboardType(.decimalPad)
                TextField(l("Rise / height"), text: $rise).keyboardType(.decimalPad)
                TextField(l("Angle (degrees)"), text: $angle).keyboardType(.decimalPad)
                if useSliders {
                    Slider(value: Binding(get: { parsedAngle() ?? 30 },
                                          set: { angle = String(format: "%.1f", $0) }),
                           in: 5...85, step: 1)
                    Slider(value: Binding(get: { min(possibleLength, max(0, number(start) ?? 0)) },
                                          set: { start = String(format: "%.1f", $0) }),
                           in: 0...possibleLength)
                }
                Toggle(l("Use sliders as well as numeric input"), isOn: $useSliders)
                TextField(l("Gap / conduit separation"), text: $spacing).keyboardType(.decimalPad)
                if kind.contains("Parallel") {
                    Stepper(l("Number of conduits") + ": \(quantity)",
                            value: $quantity, in: 1...20)
                }
                if kind == "Compound 90° Obstruction" {
                    Picker(l("Obstacle shape"), selection: $shape) {
                        ForEach(AdvancedFieldPatterns.ObstacleShape.allCases) { item in
                            Text(l(item.rawValue)).tag(item)
                        }
                    }
                    TextField(l("Obstacle width / diameter"), text: $width).keyboardType(.decimalPad)
                    if shape == .rectangle {
                        TextField(l("Obstacle height"), text: $height).keyboardType(.decimalPad)
                    }
                    TextField(l("Required clearance"), text: $clearance).keyboardType(.decimalPad)
                }
                if kind == "Kick with 90°" {
                    TextField(l("Desired 90° stub length"), text: $desiredStub).keyboardType(.decimalPad)
                    TextField(l("Documented take-up from exact manual"), text: $documentedTakeUp)
                        .keyboardType(.decimalPad)
                    Toggle(l("I verified this shoe and arrow reference in its manual"), isOn: $manualConfirmed)
                }
                if kind == "Compound 90° Obstruction" {
                    TextField(l("Documented centerline radius (optional)"), text: $radius)
                        .keyboardType(.decimalPad)
                }
                Button(l("Calculate pattern")) { calculate() }
                    .buttonStyle(.borderedProminent)
            }
            if !output.isEmpty {
                Section(l("Calculation result")) {
                    Text(output).textSelection(.enabled)
                    if fatalError {
                        Label(l("Invalid input; no stations generated."),
                              systemImage: "xmark.octagon.fill").foregroundStyle(.red)
                    } else {
                        ForEach(rows) { row in
                            VStack(alignment: .leading, spacing: 5) {
                                Text(row.title).font(.headline)
                                ForEach(row.stations.indices, id: \.self) { index in
                                    let item = row.stations[index]
                                    Text(String(format: "%.2f %@ · %.1f° · %@",
                                                item.position, unitLabel, item.angle, l(item.direction)))
                                        .font(.system(.subheadline, design: .monospaced))
                                }
                            }
                        }
                        if !rows.isEmpty {
                            Label(l("QuickCheck") + ": " + l(report.severity == .impossible ? "Impossible" : "Caution"),
                                  systemImage: report.severity == .impossible ? "xmark.octagon" : "exclamationmark.triangle")
                                .foregroundStyle(report.severity == .impossible ? .red : .orange)
                            ForEach(report.findings.indices, id: \.self) { i in
                                Text(l(report.findings[i].text)).font(.caption)
                            }
                        }
                        ShareLink(item: exportText) {
                            Label(l("Share theoretical layout"), systemImage: "square.and.arrow.up")
                        }
                    }
                }
            }
            Section(l("Field verification required")) {
                Text(l("Confirm shoe take-up, reference mark, real centerline radius, conduit type and springback against the EXACT manufacturer's manual. Test-bend before field use. Camera and AR results are not calibrated."))
                    .font(.footnote).foregroundStyle(.secondary)
            }
        }
        .navigationTitle(l("Advanced bend patterns"))
        .onAppear { adjustUnits() }
        .onChange(of: units) { _ in adjustUnits() }
    }

    private var exportText: String {
        let lines = rows.flatMap { row in
            [row.title] + row.stations.map { String(format: "%.3f %@ · %.1f° · %@",
                                                     $0.position, unitLabel, $0.angle, $0.direction) }
        }
        return (["VisionBend", kind, output] + lines +
                ["THEORETICAL CENTERLINE ONLY — verify actual equipment and test-bend."])
            .joined(separator: "\n")
    }
    private func adjustUnits() {
        guard let previous = MeasurementUnit(rawValue: inputUnits), previous != unit else { return }
        length = FieldInputNumber.convertedText(length, from: previous, to: unit)
        rise = FieldInputNumber.convertedText(rise, from: previous, to: unit)
        start = FieldInputNumber.convertedText(start, from: previous, to: unit)
        spacing = FieldInputNumber.convertedText(spacing, from: previous, to: unit)
        width = FieldInputNumber.convertedText(width, from: previous, to: unit)
        height = FieldInputNumber.convertedText(height, from: previous, to: unit)
        clearance = FieldInputNumber.convertedText(clearance, from: previous, to: unit)
        radius = FieldInputNumber.convertedText(radius, from: previous, to: unit)
        desiredStub = FieldInputNumber.convertedText(desiredStub, from: previous, to: unit)
        documentedTakeUp = FieldInputNumber.convertedText(documentedTakeUp, from: previous, to: unit)
        inputUnits = unit.rawValue
        rows = []
        output = ""
    }
    private func calculate() {
        rows = []
        output = ""
        fatalError = false
        guard let overall = number(length), overall > 0,
              let origin = number(start), origin >= 0,
              let r = number(rise), r > 0,
              let a = parsedAngle(), a > 0, a < 90,
              let gap = number(spacing), gap >= 0 else {
            fatalError = true
            output = l("Enter positive finite conduit, rise, angle and spacing values.")
            return
        }
        do {
            func row(_ title: String, _ items: [AdvancedFieldPatterns.Station]) {
                rows.append(PatternRow(title: l(title), stations: items))
            }
            switch kind {
            case "Matching Bends Offset":
                row(kind, try AdvancedFieldPatterns.matchingBendsOffset(
                    start: origin, rise: r, angle: a, betweenPairs: gap))
            case "Matching Centers Offset":
                row(kind, try AdvancedFieldPatterns.matchingCentersOffset(
                    center: origin, rise: r, angle: a, centerGap: gap))
            case "Parallel Offset":
                let layouts = try AdvancedFieldPatterns.parallelOffsets(
                    firstStart: origin, rise: r, angle: a,
                    conduitSeparation: gap, count: quantity)
                for (i, items) in layouts.enumerated() {
                    row("Conduit " + String(i + 1), items)
                }
            case "Kick with 90°":
                let travel = try MoreBendCalculations.kickTravel(rise: r, angleDegrees: a)
                row(kind, [AdvancedFieldPatterns.Station(position: origin, angle: a, direction: "Up")])
                output = String(format: l("Theoretical kick horizontal travel: %.2f %@."),
                                travel, unitLabel)
                if manualConfirmed {
                    guard let desired = number(desiredStub),
                          let takeUp = number(documentedTakeUp) else {
                        throw BendCalculationError.invalidInput
                    }
                    let stubFromOtherEnd = try ExtraBendCalculations.ninetyDegreeStubMark(
                        desiredStub: desired, takeUp: takeUp)
                    guard stubFromOtherEnd <= overall else { throw BendCalculationError.invalidInput }
                    output += "\n" + String(format: l("Calibrated 90° mark from the opposite end: %.2f %@."),
                                               stubFromOtherEnd, unitLabel)
                    output += "\n" + l("Do NOT combine marks measured from opposite ends without a physical reference.")
                } else {
                    output += "\n" + l("To calculate the 90° arrow mark, confirm exact-model manual take-up above.")
                }
            case "Matching Bend Kick", "Matching Center Kick":
                row(kind, try AdvancedFieldPatterns.matchingKick(
                    start: origin, rise: r, angle: a, separation: gap,
                    alignCenters: kind == "Matching Center Kick"))
            case "Parallel Kick", "Parallel Kick Forward":
                let kicks = try AdvancedFieldPatterns.parallelKicks(
                    firstStart: origin, rise: r, angle: a,
                    conduitSeparation: gap, count: quantity,
                    forward: kind == "Parallel Kick Forward")
                for (i, kick) in kicks.enumerated() {
                    row("Conduit " + String(i + 1), [kick])
                }
            case "Compound 90° Obstruction":
                guard let w = number(width), let h = number(height),
                      let c = number(clearance) else { throw BendCalculationError.invalidInput }
                let solution = try AdvancedFieldPatterns.compound90(
                    shape: shape, width: w, height: h, clearance: c,
                    centerlineRadius: radius.isEmpty ? nil : number(radius))
                output = String(format: l("Clearance envelope: %.2f × %.2f %@. Diagonal: %.2f %@. Rotation: %.1f°."),
                                solution.clearWidth, solution.clearHeight, unitLabel,
                                solution.diagonalTravel, unitLabel, solution.rotationDegrees)
                output += "\n" + l("Compound 90 shoe reference stations require calibrated manufacturer values; no unverified physical marks generated.")
            default: throw BendCalculationError.invalidInput
            }
            if !rows.isEmpty {
                let checks = rows.map {
                    FieldQuickCheck.evaluate(length: overall, marks: $0.stations,
                                             minimumStraight: 0,
                                             centerlineRadius: nil,
                                             hasVerifiedReference: false)
                }
                if checks.contains(where: { !$0.canProceed }) {
                    fatalError = true
                    rows = []
                    output = l("The selected pattern does not fit the available conduit length.")
                    return
                }
            }
            if output.isEmpty { output = l("Theoretical stations calculated. Check every marking against the bender manual.") }
        } catch {
            fatalError = true
            rows = []
            output = l("Cannot calculate these dimensions; check the conduit length, bend angle and clearances.")
        }
    }
}
