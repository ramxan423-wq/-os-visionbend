import SwiftUI
import UIKit

struct BendMark: Identifiable, Codable {
    var id = UUID()
    var position: Double
    var angle: Double
    var direction: String
}

struct MultiBendPlannerView: View {
    @State private var conduitLength = "3000"
    @State private var minStraight = "100"
    @State private var markPosition = "300"
    @State private var markAngle = "30"
    @State private var direction = "Up"
    @State private var marks: [BendMark] = []
    @State private var message = ""
    @StateObject private var watchSync = PhoneWatchSync.shared
    @State private var verifiedModelID = ""
    @State private var confirmedIMCHardware = false
    @State private var manufacturer = ""
    @State private var benderModel = ""
    @State private var conduitType = "EMT"
    @State private var tradeSize = ""
    @State private var referenceMark = "Arrow"
    @State private var takeUp = ""
    @State private var correction = "0"
    @State private var manualSource = ""
    @State private var desiredStub = ""
    @State private var pdfURL: URL?
    @State private var preset = "Custom"
    @State private var presetRise = "150"
    @State private var presetAngle = "30"
    @State private var presetRun = "300"
    @State private var obstructionDistance = ""
    @State private var centerlineRadius = ""
    @State private var outsideDiameter = ""
    @State private var showARMarks = false
    @State private var guideStep = 0
    @AppStorage("visionbend.units") private var selectedUnits = 0
    private var unitLabel: String { selectedUnits == 0 ? "mm" : selectedUnits == 1 ? "cm" : "in" }
    private let directions = ["Up", "Down", "Left", "Right"]

    private var length: Double { Double(conduitLength) ?? 0 }
    private var clearance: Double { Double(minStraight) ?? 0 }
    private var sorted: [BendMark] { marks.sorted { $0.position < $1.position } }
    private var valid: Bool {
        length > 0 && clearance >= 0 &&
        FieldBendGeometry.isFeasible(markPositions: marks.map(\.position), conduitLength: length, minStraight: clearance) &&
        marks.allSatisfy { $0.angle > 0 && $0.angle <= 90 }
    }

    var body: some View {
        Form {
            Section("Conduit (all values in " + unitLabel + ")") {
                TextField("Conduit length", text: $conduitLength).keyboardType(.decimalPad)
                TextField("Minimum straight between marks", text: $minStraight).keyboardType(.decimalPad)
            }
            Section("Bender geometry") {
                TextField("Centerline radius (" + unitLabel + ")", text: $centerlineRadius).keyboardType(.decimalPad)
                TextField("Actual outside diameter (" + unitLabel + ")", text: $outsideDiameter).keyboardType(.decimalPad)
            }
            Section("Shape") {
                Picker("Shape", selection: $preset) {
                    ForEach(["Custom", "Offset", "90° Stub", "3-Point Saddle", "4-Point Saddle", "Kick", "Rolling Offset", "Back-to-Back 90°", "Compound 90°", "Segmented Arc"], id: \.self) { Text($0) }
                }
                TextField("Rise / desired stub", text: $presetRise).keyboardType(.decimalPad)
                TextField("Angle", text: $presetAngle).keyboardType(.decimalPad)
                TextField("Run / clearance", text: $presetRun).keyboardType(.decimalPad)
                if preset == "Offset" && verifiedModelID.hasPrefix("greenlee-555") {
                    TextField("Distance to obstruction", text: $obstructionDistance).keyboardType(.decimalPad)
                }
                Button("Generate Marks") { generatePreset() }
                Text("Offset marks are theoretical. A 90° stub requires the calibrated bender arrow take-up below.")
                    .font(.caption).foregroundStyle(.secondary)
            }
            Section("Add bend") {
                TextField("Mark position from start", text: $markPosition).keyboardType(.decimalPad)
                TextField("Bend angle", text: $markAngle).keyboardType(.decimalPad)
                Picker("Direction", selection: $direction) {
                    ForEach(directions, id: \.self) { Text($0) }
                }
                Button("Add Mark") { addMark() }
                if !message.isEmpty { Text(message).foregroundStyle(.red).font(.caption) }
            }
            Section("Verified manufacturer profile") {
                Picker("Bender model", selection: $verifiedModelID) {
                    Text("Manual / unsupported model").tag("")
                    ForEach(VerifiedBenderCatalog.entries) { item in
                        Text("\(item.brand) \(item.model) · \(item.conduit) \(item.tradeSize)").tag(item.id)
                    }
                }
                .onChange(of: verifiedModelID) { id in applyVerifiedModel(id) }
                if verifiedModelID.hasPrefix("greenlee-555cx-imc-onehalf") || verifiedModelID.hasPrefix("greenlee-555cx-imc-two") {
                    Toggle("28008 shoe group and 13856 IMC squeeze roller installed", isOn: $confirmedIMCHardware)
                    Text("Required together for 1-1/2 and 2 inch IMC. Confirm physical equipment before generating marks.")
                        .font(.caption).foregroundStyle(.orange)
                }
                if let item = VerifiedBenderCatalog.entries.first(where: { $0.id == verifiedModelID }) {
                    Text("Official profile: \(item.brand) \(item.model) · \(item.conduit) \(item.tradeSize)")
                    if let url = URL(string: item.sourceURL) { Link("Manufacturer source", destination: url) }
                    Text("Only the exact model, conduit and size are covered. Greenlee 555 entries apply only to the listed 28008 rigid shoe and size. Other shoes require separate tables.")
                        .font(.caption).foregroundStyle(.secondary)
                }
            }
            Section("Model-calibrated 90° stub mark") {
                TextField("Manufacturer", text: $manufacturer)
                TextField("Exact bender model", text: $benderModel)
                TextField("Conduit type", text: $conduitType)
                TextField("Conduit trade size", text: $tradeSize)
                TextField("Reference mark from manual", text: $referenceMark)
                TextField("Verified take-up", text: $takeUp).keyboardType(.decimalPad)
                TextField("Field correction", text: $correction).keyboardType(.decimalPad)
                TextField("Manual source", text: $manualSource)
                TextField("Desired stub length", text: $desiredStub).keyboardType(.decimalPad)
                Button("Add Calibrated Stub Mark") { addCalibratedMark() }
                Text("Use only exact-model values confirmed in the manufacturer manual. Reference marks differ between benders.")
                    .font(.caption).foregroundStyle(.secondary)
            }
            Section("2D marking diagram (schematic)") {
                BendMarkDiagram(marks: sorted, conduitLength: length)
                    .frame(height: 145)
                Text("Marks are measured from the starting end. The drawing shows mark positions, not actual post-bend shape.")
                    .font(.caption).foregroundStyle(.secondary)
            }
            Section("3D preview") {
                BendShapePreview(marks: sorted, length: length, centerlineRadius: Double(centerlineRadius) ?? 0, conduitOutsideDiameter: Double(outsideDiameter) ?? 0).frame(height: 280)
                Text("Theoretical shape only. Confirm bend radius and equipment calibration.")
            }
            Section("Bend sequence") {
                ForEach(sorted) { mark in
                    HStack {
                        Text(String(format: "%.2f", mark.position)).monospacedDigit()
                        Spacer()
                        Text(String(format: "%.1f° %@", mark.angle, mark.direction))
                    }
                }
                .onDelete { indices in
                    let ids = Set(indices.map { sorted[$0].id })
                    marks.removeAll { ids.contains($0.id) }
                }
                Text(valid ? "Mark spacing passes the entered minimum." : "Invalid layout: check lengths, angles and minimum straight spacing.")
                    .foregroundStyle(valid ? .green : .red)
            }
            Section("Camera marking (experimental)") {
                Button("Show Marks on Camera") { showARMarks = true }
                    .disabled(!valid || marks.isEmpty)
                Text("Tap conduit start and end in AR; verify marker locations manually.")
                    .font(.caption).foregroundStyle(.secondary)
            }
            Section("Step-by-step bend assistant") {
                let steps = sorted
                if steps.isEmpty {
                    Text("Generate or add bend marks to begin.")
                } else {
                    Text("Step \(min(guideStep + 1, steps.count)) of \(steps.count)")
                        .font(.headline)
                    let mark = steps[min(guideStep, steps.count - 1)]
                    Text(String(format: "Measure %.2f %@ from the starting end. Mark the conduit. Align the verified bender reference. Bend %.1f degrees %@.", mark.position, unitLabel, mark.angle, mark.direction))
                    Text("Confirm bender radius, reference marks and springback before bending.")
                        .font(.caption).foregroundStyle(.secondary)
                    HStack {
                        Button("Previous") { guideStep = max(0, guideStep - 1) }.disabled(guideStep == 0)
                        Spacer()
                        Button("Next") { guideStep = min(steps.count - 1, guideStep + 1) }.disabled(guideStep >= steps.count - 1)
                    }
                }
            }
            Section("Apple Watch") {
                Button("Send Marks to Watch") { watchSync.send(projectName: "VisionBend Plan", marks: sorted, units: unitLabel) }
                    .disabled(marks.isEmpty || !valid)
                Text(watchSync.status).font(.caption)
            }
            Section("Export") {
                Button("Create PDF marking sheet") { makePDF() }.disabled(!valid || marks.isEmpty)
                if let pdfURL {
                    ShareLink(item: pdfURL) { Label("Share PDF", systemImage: "square.and.arrow.up") }
                }
            }
            Section("Field verification") {
                Text("Theoretical centerline marks only. Actual bender arrow/star references, take-up, springback and required tangent lengths depend on the exact bender and conduit. Verify the manufacturer's manual and make a test bend.")
                    .font(.footnote)
            }
        }
        .navigationTitle("Multi-Bend Planner")
        .onChange(of: selectedUnits) { _ in
            if !verifiedModelID.isEmpty { applyVerifiedModel(verifiedModelID) }
        }
        .toolbar { EditButton() }
        .sheet(isPresented: $showARMarks) {
            NavigationStack {
                ARBendMarkView(marks: sorted, conduitLength: length,
                               unitToMeters: selectedUnits == 0 ? 0.001 : selectedUnits == 1 ? 0.01 : 0.0254)
            }
        }
    }

    private func applyVerifiedModel(_ id: String) {
        guard let item = VerifiedBenderCatalog.entries.first(where: { $0.id == id }) else { return }
        let factor = selectedUnits == 0 ? 25.4 : selectedUnits == 1 ? 2.54 : 1.0
        confirmedIMCHardware = false
        manufacturer = item.brand
        benderModel = item.model
        conduitType = item.conduit
        tradeSize = item.tradeSize
        referenceMark = item.id.hasPrefix("greenlee-555") ? "Hook Front" : "Arrow"
        if let deduct = item.deductInches { takeUp = String(format: "%.4f", deduct * factor) }
        if let radius = item.radiusInches {
            centerlineRadius = String(format: "%.4f", radius * factor)
        } else {
            centerlineRadius = "" // Never retain a different shoe\'s radius.
        }
        correction = "0"
        manualSource = item.sourceURL
        message = item.radiusInches == nil
            ? "Verified deduct loaded. This shoe radius is NOT verified; enter a documented radius for 3D and compound geometry."
            : "Verified deduct and radius loaded. Check reference mark and field springback."
    }

    private var requiresIMCHardware: Bool {
        verifiedModelID == "greenlee-555cx-imc-onehalf" || verifiedModelID == "greenlee-555cx-imc-two"
    }

    private func generatePreset() {
        if requiresIMCHardware && !confirmedIMCHardware {
            message = "Install and confirm both 28008 shoe group and 13856 IMC squeeze roller first."
            return
        }
        func number(_ value: String) -> Double? { Double(value.replacingOccurrences(of: ",", with: ".")) }
        guard let rise = number(presetRise), let angle = number(presetAngle), let run = number(presetRun),
              rise.isFinite, angle.isFinite, run.isFinite,
              rise > 0, angle > 0, angle <= 90, run > 0, length > 0 else {
            message = "Enter valid positive dimensions and angle up to 90 degrees."
            return
        }
        if preset == "90° Stub" {
            desiredStub = presetRise
            message = "Use verified bender take-up and Add Calibrated Stub Mark."
            return
        }
        let first = length * 0.1
        let spacing = rise / sin(angle * .pi / 180)
        var steps: [(Double, Double, String)] = []
        switch preset {
        case "Offset":
            if verifiedModelID.hasPrefix("greenlee-555") {
                let sizes = ["1/2 in", "3/4 in", "1 in", "1-1/4 in", "1-1/2 in", "2 in"]
                let xs = [3.0625, 3.0625, 3.1875, 4, 4.25, 4.5]
                let multipliers: [(Double, Double)] = [(10, 5.8), (15, 3.9), (22.5, 2.6), (30, 2), (45, 1.4)]
                guard let index = sizes.firstIndex(of: tradeSize),
                      let factor = multipliers.first(where: { abs($0.0 - angle) < 0.001 })?.1,
                      let distance = number(obstructionDistance), distance.isFinite else {
                    message = "Greenlee offset requires obstruction distance and 10, 15, 22.5, 30 or 45 degrees."
                    return
                }
                let conversion = selectedUnits == 0 ? 25.4 : selectedUnits == 1 ? 2.54 : 1.0
                let firstMark = distance - xs[index] * conversion
                guard firstMark >= 0 else { message = "Obstruction too close for X dimension."; return }
                steps = [(firstMark, angle, "Up"), (firstMark + rise * factor, angle, "Down")]
            } else {
                steps = [(first, angle, "Up"), (first + spacing, angle, "Down")]
            }
        case "3-Point Saddle":
            guard angle <= 45 else { message = "Outer saddle angle must be at most 45 degrees."; return }
            let middle = length / 2
            steps = [(middle - spacing, angle, "Up"), (middle, 2 * angle, "Down"), (middle + spacing, angle, "Up")]
        case "4-Point Saddle":
            let third = first + spacing + run
            steps = [(first, angle, "Up"), (first + spacing, angle, "Down"), (third, angle, "Down"), (third + spacing, angle, "Up")]
        case "Kick":
            steps = [(first, angle, "Up")]
        case "Rolling Offset":
            let trueRise = hypot(rise, run)
            steps = [(first, angle, "Up"), (first + trueRise / sin(angle * .pi / 180), angle, "Down")]
        case "Back-to-Back 90°":
            steps = [(first, 90, "Up"), (first + run, 90, "Down")]
        case "Segmented Arc":
            let n = 5
            steps = (0..<n).map { (first + Double($0) * run / Double(n - 1), angle / Double(n), "Up") }
        case "Compound 90°":
            guard let radius = number(centerlineRadius), radius > 0 else { message = "Enter verified bend radius."; return }
            steps = [(rise, 90, "Up"), (rise + run + radius * .pi / 2, 90, "Right")]
        default:
            message = "Choose a preset or add custom marks."
            return
        }
        let proposed = steps.map { BendMark(position: $0.0, angle: $0.1, direction: $0.2) }
        guard FieldBendGeometry.isFeasible(markPositions: proposed.map { $0.position },
                                          conduitLength: length, minStraight: clearance) else {
            message = "Marks exceed conduit length or violate minimum spacing."
            return
        }
        marks = proposed
        pdfURL = nil
        message = preset == "Offset" && verifiedModelID.hasPrefix("greenlee-555") ? "Greenlee 555 X-table marks: align each mark with front hook edge, rotate conduit 180 degrees for second bend. Approximate multiplier; verify minimum offset and springback." : preset == "Compound 90°" ? "Theoretical 90 + 90 bend stations generated. NOT bender arrow marks; confirm model-specific references and test bend." : preset == "Rolling Offset"
            ? String(format: "Roll orientation %.1f degrees. Verify orientation and bender calibration.", atan2(run, rise) * 180 / .pi)
            : "Theoretical marks ready. Confirm reference marks, bend direction, radius and springback."
    }

    private func addMark() {
        guard let position = Double(markPosition.replacingOccurrences(of: ",", with: ".")),
              let angle = Double(markAngle.replacingOccurrences(of: ",", with: ".")),
              position.isFinite, angle.isFinite, position >= 0, angle > 0, angle <= 90 else {
            message = "Enter a valid position and angle (0–90°)."
            return
        }
        let proposed = marks.map(\.position) + [position]
        guard FieldBendGeometry.isFeasible(markPositions: proposed, conduitLength: length, minStraight: clearance) else {
            message = "Mark outside conduit or too close to another mark."
            return
        }
        marks.append(BendMark(position: position, angle: angle, direction: direction))
        pdfURL = nil
        message = ""
    }

    private func addCalibratedMark() {
        if requiresIMCHardware && !confirmedIMCHardware {
            message = "Confirm 28008 shoe group AND 13856 IMC squeeze roller before marking."
            return
        }
        guard !manufacturer.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty,
              !benderModel.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty,
              !tradeSize.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty,
              !manualSource.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty,
              ["arrow", "hook front"].contains(referenceMark.lowercased()),
              let take = Double(takeUp.replacingOccurrences(of: ",", with: ".")),
              let offset = Double(correction.replacingOccurrences(of: ",", with: ".")),
              let desired = Double(desiredStub.replacingOccurrences(of: ",", with: ".")) else {
            message = "Enter documented arrow or hook-front deduct and exact model. Star/other marks need a different formula."
            return
        }
        if verifiedModelID.hasPrefix("greenlee-555"), desired < take + (selectedUnits == 0 ? 50.8 : selectedUnits == 1 ? 5.08 : 2) {
            message = "Greenlee 555 minimum stub is deduct + 2 inches. Increase the desired stub."; return
        }
        let calibration = BenderCalibration(manufacturer: manufacturer, model: benderModel, conduit: conduitType, tradeSize: tradeSize, referenceMark: referenceMark, takeUp: take, fieldCorrection: offset, source: manualSource)
        guard let position = calibration.stubPosition(for: desired),
              FieldBendGeometry.isFeasible(markPositions: marks.map(\.position) + [position], conduitLength: length, minStraight: clearance) else {
            message = "Calibrated mark is invalid or conflicts with existing marks."
            return
        }
        marks.append(BendMark(position: position, angle: 90, direction: direction))
        pdfURL = nil
        message = "Stub mark added using your manual-supplied calibration."
    }

    private func makePDF() {
        let page = CGRect(x: 0, y: 0, width: 595, height: 842)
        let renderer = UIGraphicsPDFRenderer(bounds: page)
        let data = renderer.pdfData { context in
            context.beginPage()
            let title = "VisionBend - Multi-Bend Marking Sheet"
            title.draw(at: CGPoint(x: 36, y: 38), withAttributes: [.font: UIFont.boldSystemFont(ofSize: 18)])
            let info = String(format: "Conduit length: %.2f %@   Minimum mark spacing: %.2f %@", length, unitLabel, clearance, unitLabel)
            info.draw(at: CGPoint(x: 36, y: 76), withAttributes: [.font: UIFont.systemFont(ofSize: 12)])
            let left: CGFloat = 50
            let width: CGFloat = 495
            let baseline: CGFloat = 175
            let path = UIBezierPath()
            path.move(to: CGPoint(x: left, y: baseline))
            path.addLine(to: CGPoint(x: left + width, y: baseline))
            path.lineWidth = 3
            UIColor.black.setStroke()
            path.stroke()
            for mark in sorted {
                let x = left + width * CGFloat(mark.position / length)
                let tick = UIBezierPath()
                tick.move(to: CGPoint(x: x, y: baseline - 14))
                tick.addLine(to: CGPoint(x: x, y: baseline + 14))
                tick.lineWidth = 1
                tick.stroke()
            }
            for (index, mark) in sorted.enumerated() {
                let line = String(format: "%d. From start: %.2f  |  Angle: %.1f deg  |  %@", index + 1, mark.position, mark.angle, mark.direction)
                line.draw(at: CGPoint(x: 36, y: 225 + CGFloat(index) * 23), withAttributes: [.font: UIFont.systemFont(ofSize: 11)])
            }
            let caution = "SCHEMATIC ONLY. Verify bender reference and calibration before field use."
            caution.draw(in: CGRect(x: 36, y: 760, width: 520, height: 55), withAttributes: [.font: UIFont.systemFont(ofSize: 10)])
        }
        let url = FileManager.default.temporaryDirectory.appendingPathComponent("VisionBend-Marks-\(UUID().uuidString).pdf")
        do { try data.write(to: url); pdfURL = url; message = "" }
        catch { message = "PDF export failed: \(error.localizedDescription)" }
    }
}

private struct BendMarkDiagram: View {
    let marks: [BendMark]
    let conduitLength: Double

    var body: some View {
        GeometryReader { geo in
            let width = max(1, geo.size.width - 36)
            let baseY = geo.size.height / 2
            Path { path in
                path.move(to: CGPoint(x: 18, y: baseY))
                path.addLine(to: CGPoint(x: 18 + width, y: baseY))
            }
            .stroke(.primary, lineWidth: 3)
            ForEach(marks) { mark in
                let x = 18 + width * CGFloat(conduitLength > 0 ? mark.position / conduitLength : 0)
                Path { path in
                    path.move(to: CGPoint(x: x, y: baseY - 14))
                    path.addLine(to: CGPoint(x: x, y: baseY + 14))
                }
                .stroke(.orange, lineWidth: 2)
                Text(String(format: "%.0f", mark.position))
                    .font(.system(size: 9))
                    .position(x: x, y: baseY - 25)
            }
        }
    }
}
