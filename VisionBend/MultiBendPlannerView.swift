import SwiftUI
import UIKit

struct BendMark: Identifiable, Codable {
    var id = UUID()
    var position: Double
    var angle: Double
    var direction: String
}

struct MultiBendPlannerView: View {
    @AppStorage("visionbend.language") private var language = "system"
    private func l(_ key: String) -> String { VisionBendLocalization.text(key, language: language) }
    @State private var conduitLength = "3000"
    @State private var minStraight = "100"
    @State private var markPosition = "300"
    @State private var markAngle = "30"
    @State private var direction = "Up"
    @State private var marks: [BendMark] = []
    @State private var message = ""
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
    @State private var presetStart = "300"
    @State private var segmentCount = "5"
    @State private var backToBackInstructions = ""
    @State private var confirmedStarReference = false
    @State private var selectedSavedProfileID = ""
    @AppStorage("visionbend.benderProfiles.v1") private var storedBenderProfiles = Data()
    @State private var obstructionDistance = ""
    @State private var saddleZ = ""
    @State private var saddleL1 = ""
    @State private var saddleL2 = ""
    @State private var saddleStraight = ""
    @State private var saddleTableKey = ""
    @State private var centerlineRadius = ""
    @State private var outsideDiameter = ""
    @State private var showARMarks = false
    @State private var guideStep = 0
    @AppStorage("visionbend.units") private var selectedUnits = 0
    // The initial planner examples are in millimeters, whatever the saved user unit.
    @State private var inputUnits = 0
    @State private var showAdvancedBenderOptions = false
    private var unitLabel: String { selectedUnits == 0 ? "mm" : selectedUnits == 1 ? "cm" : "in" }
    private let directions = ["Up", "Down", "Left", "Right"]
    private var savedBenderProfiles: [BenderProfile] {
        (try? JSONDecoder().decode([BenderProfile].self, from: storedBenderProfiles)) ?? []
    }

    private var currentUnit: MeasurementUnit { MeasurementUnit(rawValue: selectedUnits) ?? .millimeters }
    private func dimension(_ text: String) -> Double? { FieldInputNumber.parse(text, unit: currentUnit) }
    private var length: Double { dimension(conduitLength) ?? 0 }
    private var clearance: Double { dimension(minStraight) ?? 0 }
    private var sorted: [BendMark] { marks.sorted { $0.position < $1.position } }
    private var valid: Bool {
        length > 0 && clearance >= 0 &&
        FieldBendGeometry.isFeasible(markPositions: marks.map(\.position), conduitLength: length, minStraight: clearance) &&
        marks.allSatisfy { $0.angle > 0 && $0.angle <= 90 }
    }

    var body: some View {
        Form {
            Section("Conduit (all values in " + unitLabel + ")") {
                TextField(l("Conduit length"), text: $conduitLength).keyboardType(.decimalPad)
                TextField(l("Minimum straight between marks"), text: $minStraight).keyboardType(.decimalPad)
            }
            Section(l("Shape")) {
                Picker(l("Shape"), selection: $preset) {
                    ForEach(["Custom", "Offset", "90° Stub", "3-Point Saddle", "4-Point Saddle", "Kick", "Rolling Offset", "Back-to-Back 90°", "Compound 90°", "Segmented Arc"], id: \.self) { Text($0) }
                }
                .onChange(of: preset) { newPreset in
                    backToBackInstructions = ""
                    if ["90° Stub", "Back-to-Back 90°", "Compound 90°"].contains(newPreset) { presetAngle = "90" }
                }
                TextField(l("Rise / desired stub"), text: $presetRise).keyboardType(.decimalPad)
                TextField(l("Angle"), text: $presetAngle).keyboardType(.decimalPad)
                TextField(l("Run / clearance"), text: $presetRun).keyboardType(.decimalPad)
                if !["Custom", "90° Stub", "Back-to-Back 90°"].contains(preset) {
                    TextField("First theoretical station from conduit start (" + unitLabel + ")", text: $presetStart)
                        .keyboardType(.decimalPad)
                }
                if preset == "Segmented Arc" {
                    TextField("Number of equal bends (2–30)", text: $segmentCount)
                        .keyboardType(.numberPad)
                    Text("Requires a verified centerline radius. Positions are centerline stations, not shoe reference marks.")
                        .font(.caption).foregroundStyle(.secondary)
                }
                if preset == "Back-to-Back 90°" {
                    Toggle("I confirmed the second 90° star mark in my bender manual", isOn: $confirmedStarReference)
                    Text("First bend uses a calibrated arrow mark. The second mark is measured AFTER bending, from the back edge of the first 90°.")
                        .font(.caption).foregroundStyle(.secondary)
                }
                if ["90° Stub", "Back-to-Back 90°"].contains(preset) {
                    Picker("Saved bender calibration", selection: $selectedSavedProfileID) {
                        Text("Select saved profile or enter below").tag("")
                        ForEach(savedBenderProfiles) { profile in
                            Text("\(profile.manufacturer) \(profile.model) · \(profile.conduitSize)").tag(profile.id.uuidString)
                        }
                    }
                    .onChange(of: selectedSavedProfileID) { _ in applySavedBenderProfile() }
                }
                if preset == "Offset" && verifiedModelID.hasPrefix("greenlee-555") {
                    TextField(l("Distance to obstruction"), text: $obstructionDistance).keyboardType(.decimalPad)
                }
                if (preset == "3-Point Saddle" || preset == "4-Point Saddle") && verifiedModelID.hasPrefix("greenlee-555") {
                    TextField(l("Manufacturer table Z"), text: $saddleZ).keyboardType(.decimalPad)
                    TextField(l("Manufacturer table L1"), text: $saddleL1).keyboardType(.decimalPad)
                    TextField(l("Manufacturer table L2"), text: $saddleL2).keyboardType(.decimalPad)
                    if preset == "4-Point Saddle" {
                        TextField(l("Straight section length"), text: $saddleStraight).keyboardType(.decimalPad)
                    }
                    Button(l("Load Exact Greenlee Table Values")) {
                        let conversion = selectedUnits == 0 ? 25.4 : selectedUnits == 1 ? 2.54 : 1.0
                        guard let height = dimension(presetRise),
                              let bendAngle = Double(presetAngle.replacingOccurrences(of: ",", with: ".")),
                              let row = GreenleeSaddleTable.exact(modelID: verifiedModelID, angle: bendAngle, heightInches: height / conversion) else {
                            message = "No exact published table cell installed for this model, angle and height. Enter verified Z/L1/L2 manually."
                            return
                        }
                        saddleZ = String(format: "%.4f", row.z * conversion)
                        saddleL1 = String(format: "%.4f", row.l1 * conversion)
                        saddleL2 = String(format: "%.4f", row.l2 * conversion)
                        saddleTableKey = "\(verifiedModelID)|\(bendAngle)|\(row.heightInches)"
                        message = "Exact Greenlee manufacturer table cell loaded."
                    }
                    Text(l("Only exact installed table cells auto-load. No interpolation.")).font(.caption)
                }
                Button(l("Generate Marks")) { generatePreset() }
                Text(l("Offset marks are theoretical. A 90° stub uses your verified bender take-up, not a guessed deduction."))
                    .font(.caption).foregroundStyle(.secondary)
            }
            Section(l("Add bend")) {
                TextField(l("Mark position from start"), text: $markPosition).keyboardType(.decimalPad)
                TextField(l("Bend angle"), text: $markAngle).keyboardType(.decimalPad)
                Picker(l("Direction"), selection: $direction) {
                    ForEach(directions, id: \.self) { Text($0) }
                }
                Button(l("Add Mark")) { addMark() }
                if !message.isEmpty { Text(message).foregroundStyle(.red).font(.caption) }
                if !backToBackInstructions.isEmpty {
                    Text(backToBackInstructions).font(.callout).foregroundStyle(.primary)
                        .padding(10).background(Color.orange.opacity(0.12), in: RoundedRectangle(cornerRadius: 10))
                }
            }
            Section {
                Toggle(VisionBendLocalization.text("Advanced bender options", turkish: "Gelişmiş bükücü ayarları", language: language), isOn: $showAdvancedBenderOptions)
            }
            if showAdvancedBenderOptions {
                Section(l("Bender geometry")) {
                    TextField("Centerline radius (" + unitLabel + ")", text: $centerlineRadius).keyboardType(.decimalPad)
                    TextField("Actual outside diameter (" + unitLabel + ")", text: $outsideDiameter).keyboardType(.decimalPad)
                }
            Section(l("Verified manufacturer profile")) {
                Picker(l("Bender model"), selection: $verifiedModelID) {
                    Text(l("Manual / unsupported model")).tag("")
                    ForEach(VerifiedBenderCatalog.entries) { item in
                        Text("\(item.brand) \(item.model) · \(item.conduit) \(item.tradeSize)").tag(item.id)
                    }
                }
                .onChange(of: verifiedModelID) { id in applyVerifiedModel(id) }
                if requiresIMCHardware {
                    Toggle(l("28008 shoe group and 13856 IMC squeeze roller installed"), isOn: $confirmedIMCHardware)
                    Text(l("Required together for 1-1/2 and 2 inch IMC. Confirm physical equipment before generating marks."))
                        .font(.caption).foregroundStyle(.orange)
                }
                if let item = VerifiedBenderCatalog.entries.first(where: { $0.id == verifiedModelID }) {
                    Text("Official profile: \(item.brand) \(item.model) · \(item.conduit) \(item.tradeSize)")
                    if let url = URL(string: item.sourceURL) { Link("Manufacturer source", destination: url) }
                    Text(l("Only the exact model, conduit and size are covered. Greenlee 555 entries apply only to the listed 28008 rigid shoe and size. Other shoes require separate tables."))
                        .font(.caption).foregroundStyle(.secondary)
                }
            }
            Section(l("Model-calibrated 90° stub mark")) {
                TextField(l("Manufacturer"), text: $manufacturer)
                TextField(l("Exact bender model"), text: $benderModel)
                TextField(l("Conduit type"), text: $conduitType)
                TextField(l("Conduit trade size"), text: $tradeSize)
                TextField(l("Reference mark from manual"), text: $referenceMark)
                TextField(l("Verified take-up"), text: $takeUp).keyboardType(.decimalPad)
                TextField(l("Field correction"), text: $correction).keyboardType(.decimalPad)
                TextField(l("Manual source"), text: $manualSource)
                TextField(l("Desired stub length"), text: $desiredStub).keyboardType(.decimalPad)
                Button(l("Add Calibrated Stub Mark")) { addCalibratedMark() }
                Text(l("Use only exact-model values confirmed in the manufacturer manual. Reference marks differ between benders."))
                    .font(.caption).foregroundStyle(.secondary)
            }
            }
            Section(l("2D marking diagram (schematic)")) {
                BendMarkDiagram(marks: sorted, conduitLength: length)
                    .frame(height: 145)
                Text(l("Marks are measured from the starting end. The drawing shows mark positions, not actual post-bend shape."))
                    .font(.caption).foregroundStyle(.secondary)
            }
            Section(l("3D preview")) {
                BendShapePreview(marks: sorted, length: length, centerlineRadius: dimension(centerlineRadius) ?? 0, conduitOutsideDiameter: dimension(outsideDiameter) ?? 0).frame(height: 280)
                Text(l("Theoretical shape only. Confirm bend radius and equipment calibration."))
            }
            Section(l("Bend sequence")) {
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
            Section(l("Camera marking (experimental)")) {
                Button(l("Show Marks on Camera")) { showARMarks = true }
                    .disabled(!valid || marks.isEmpty)
                Text(l("Tap conduit start and end in AR; verify marker locations manually."))
                    .font(.caption).foregroundStyle(.secondary)
            }
            Section(l("Step-by-step bend assistant")) {
                let steps = sorted
                if steps.isEmpty {
                    Text(l("Generate or add bend marks to begin."))
                } else {
                    Text("Step \(min(guideStep + 1, steps.count)) of \(steps.count)")
                        .font(.headline)
                    let mark = steps[min(guideStep, steps.count - 1)]
                    Text(String(format: "Measure %.2f %@ from the starting end. Mark the conduit. Align the verified bender reference. Bend %.1f degrees %@.", mark.position, unitLabel, mark.angle, mark.direction))
                    Text(l("Confirm bender radius, reference marks and springback before bending."))
                        .font(.caption).foregroundStyle(.secondary)
                    HStack {
                        Button(l("Previous")) { guideStep = max(0, guideStep - 1) }.disabled(guideStep == 0)
                        Spacer()
                        Button(l("Next")) { guideStep = min(steps.count - 1, guideStep + 1) }.disabled(guideStep >= steps.count - 1)
                    }
                }
            }
            Section(l("Export")) {
                Button(l("Create PDF marking sheet")) { makePDF() }.disabled(!valid || marks.isEmpty)
                if let pdfURL {
                    ShareLink(item: pdfURL) { Label("Share PDF", systemImage: "square.and.arrow.up") }
                }
            }
            Section(l("Field verification")) {
                Text(l("Theoretical centerline marks only. Actual bender arrow/star references, take-up, springback and required tangent lengths depend on the exact bender and conduit. Verify the manufacturer's manual and make a test bend."))
                    .font(.footnote)
            }
        }
        .navigationTitle(l("Multi-Bend Planner"))
        .onAppear { adaptDimensionsToCurrentUnits() }
        .onChange(of: selectedUnits) { _ in
            adaptDimensionsToCurrentUnits()
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

    private func adaptDimensionsToCurrentUnits() {
        guard let from = MeasurementUnit(rawValue: inputUnits), from != currentUnit else { return }
        func change(_ text: inout String) {
            text = FieldInputNumber.convertedText(text, from: from, to: currentUnit)
        }
        change(&conduitLength)
        change(&minStraight)
        change(&markPosition)
        change(&presetRise)
        change(&presetRun)
        change(&presetStart)
        change(&obstructionDistance)
        change(&saddleZ)
        change(&saddleL1)
        change(&saddleL2)
        change(&saddleStraight)
        change(&centerlineRadius)
        change(&outsideDiameter)
        change(&takeUp)
        change(&correction)
        change(&desiredStub)
        marks = marks.map { mark in
            var copy = mark
            copy.position = from.convert(mark.position, to: currentUnit)
            return copy
        }
        inputUnits = currentUnit.rawValue
        saddleTableKey = ""
        pdfURL = nil
    }

    private func applyVerifiedModel(_ id: String) {
        guard let item = VerifiedBenderCatalog.entries.first(where: { $0.id == id }) else { return }
        selectedSavedProfileID = ""
        let factor = selectedUnits == 0 ? 25.4 : selectedUnits == 1 ? 2.54 : 1.0
        confirmedIMCHardware = false
        confirmedStarReference = false
        backToBackInstructions = ""
        saddleTableKey = ""
        saddleZ = ""; saddleL1 = ""; saddleL2 = ""
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

    private func applySavedBenderProfile() {
        guard let profile = savedBenderProfiles.first(where: { $0.id.uuidString == selectedSavedProfileID }) else { return }
        guard let code = profile.unitCode, let originalUnit = MeasurementUnit(rawValue: code),
              let savedTakeUp = FieldInputNumber.parse(profile.takeUp, unit: originalUnit), savedTakeUp >= 0,
              let savedRadius = FieldInputNumber.parse(profile.radius, unit: originalUnit), savedRadius > 0,
              let originalMark = profile.referenceMark, ["arrow", "hook front"].contains(originalMark.lowercased()) else {
            message = "This saved profile has missing units, values or reference mark. Re-enter and save it in Bender Reference before using it for physical marks."
            showAdvancedBenderOptions = true
            return
        }
        verifiedModelID = ""
        confirmedStarReference = false
        backToBackInstructions = ""
        manufacturer = profile.manufacturer
        benderModel = profile.model
        conduitType = profile.conduitType
        tradeSize = profile.conduitSize
        referenceMark = originalMark
        takeUp = String(format: "%.4f", originalUnit.convert(savedTakeUp, to: currentUnit))
        centerlineRadius = String(format: "%.4f", originalUnit.convert(savedRadius, to: currentUnit))
        correction = "0"
        manualSource = profile.source
        message = "Saved field profile loaded. Confirm the exact model, manual, reference marks and springback on the real bender."
    }

    private var requiresIMCHardware: Bool {
        verifiedModelID == "greenlee-555cx-imc-onehalf" || verifiedModelID == "greenlee-555cx-imc-two" || (verifiedModelID.contains("-12580-imc-") && (tradeSize == "1-1/2 in" || tradeSize == "2 in"))
    }

    private func generatePreset() {
        backToBackInstructions = ""
        if requiresIMCHardware && !confirmedIMCHardware {
            message = "Install and confirm both 28008 shoe group and 13856 IMC squeeze roller first."
            return
        }
        func number(_ value: String) -> Double? { dimension(value) }
        guard let rise = number(presetRise), let angle = number(presetAngle) else {
            message = "Enter valid dimensions and angle for this preset."
            return
        }
        let run = number(presetRun) ?? (preset == "90° Stub" ? 0 : .nan)
        guard
              rise.isFinite, angle.isFinite, run.isFinite,
              rise > 0, angle > 0, angle <= (preset == "Segmented Arc" ? 180 : 90),
              (run > 0 || preset == "90° Stub"), length > 0 else {
            message = "Enter valid positive dimensions and an angle supported by this preset."
            return
        }
        if ["90° Stub", "Back-to-Back 90°", "Compound 90°"].contains(preset) && abs(angle - 90) > 0.001 {
            message = "This preset requires a 90-degree bend."
            return
        }
        if (preset == "3-Point Saddle" || preset == "4-Point Saddle") && !saddleTableKey.isEmpty {
            let expectedKey = "\(verifiedModelID)|\(angle)|\(rise / (selectedUnits == 0 ? 25.4 : selectedUnits == 1 ? 2.54 : 1.0))"
            if saddleTableKey != expectedKey {
                message = "Angle, height or model changed. Reload exact manufacturer saddle table values."; return
            }
        }
        if preset == "90° Stub" {
            desiredStub = presetRise
            guard let position = calibratedStubPosition(for: rise) else {
                showAdvancedBenderOptions = true
                return
            }
            guard FieldBendGeometry.isFeasible(markPositions: [position], conduitLength: length, minStraight: clearance) else {
                message = "The calibrated stub mark is outside the entered conduit length."
                return
            }
            marks = [BendMark(position: position, angle: 90, direction: "Up")]
            pdfURL = nil
            message = "90° stub mark generated using the recorded bender take-up and reference mark. Confirm the real bender and springback."
            return
        }
        if preset == "Back-to-Back 90°" {
            desiredStub = presetRise
            guard confirmedStarReference else {
                message = "Confirm the manufacturer's star reference on your exact bender before laying out the second 90°."
                return
            }
            guard !verifiedModelID.hasPrefix("greenlee-555"), !benderModel.lowercased().contains("555") else {
                message = "The 555 shoe's star-reference back-to-back method is not verified. Use its exact machine manual; no fabricated mark will be generated."
                return
            }
            guard let first = calibratedStubPosition(for: rise),
                  let take = number(takeUp),
                  let fieldCorrection = number(correction),
                  let plan = try? BendPlanGeometry.backToBackGuide(firstStub: rise, takeUp: take, backToBackDistance: run, fieldCorrection: fieldCorrection),
                  abs(plan.firstArrow - first) < 0.0001 else {
                showAdvancedBenderOptions = true
                return
            }
            guard FieldBendGeometry.isFeasible(markPositions: [first], conduitLength: length, minStraight: clearance) else {
                message = "First arrow mark is outside the entered conduit length."
                return
            }
            marks = [BendMark(position: first, angle: 90, direction: "Up")]
            backToBackInstructions = String(format: "STEP 1: Mark %.2f %@ from the conduit start; align your documented %@ reference and make the first 90°. STEP 2: On the BENT conduit, measure %.2f %@ from the BACK EDGE of that first 90°. Align the manufacturer's STAR symbol with this new mark and bend the other leg in the opposite direction. The second mark is RELATIVE and cannot safely be drawn as a pre-bend absolute mark.", first, unitLabel, referenceMark, plan.starFromFirstBack, unitLabel)
            pdfURL = nil
            message = "Back-to-back guide ready: first absolute arrow mark plus second post-bend star instruction."
            return
        }
        guard let first = number(presetStart), first.isFinite, first >= 0 else {
            message = "Enter a valid theoretical starting station from the conduit end."
            return
        }
        let spacing = rise / sin(angle * .pi / 180)
        guard spacing.isFinite else { message = "Calculated mark spacing is too large."; return }
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
            guard angle <= 45 else { message = "Three-bend saddle outer angle must be at most 45 degrees; middle bend cannot exceed 90 degrees."; return }
            if verifiedModelID.hasPrefix("greenlee-555") {
                guard let z = number(saddleZ), let l1 = number(saddleL1), let l2 = number(saddleL2), z.isFinite, l1.isFinite, l2.isFinite, z >= 0, l1 > 0, l2 > 0 else {
                    message = "Enter Greenlee saddle table Z, L1 and L2."; return
                }
                let firstMark = run - z
                steps = [(firstMark, angle, "Up"), (firstMark + l1, 2 * angle, "Down"), (firstMark + l1 + l2, angle, "Up")]
                break
            }
            guard angle <= 45 else { message = "Outer saddle angle must be at most 45 degrees."; return }
            let middle = run // Obstruction center measured from conduit start.
            steps = [(middle - spacing, angle, "Up"), (middle, 2 * angle, "Down"), (middle + spacing, angle, "Up")]
        case "4-Point Saddle":
            if verifiedModelID.hasPrefix("greenlee-555") {
                guard let z = number(saddleZ), let l1 = number(saddleL1), let l2 = number(saddleL2), z.isFinite, l1.isFinite, l2.isFinite, z >= 0, l1 > 0, l2 > 0 else {
                    message = "Enter Greenlee saddle table Z, L1 and L2."; return
                }
                guard let straight = number(saddleStraight), straight.isFinite, straight >= 0 else { message = "Enter saddle straight-section length."; return }
                let start = run - z
                let thirdMark = start + l2 + straight
                steps = [(start, angle, "Up"), (start + l1, angle, "Down"), (thirdMark, angle, "Down"), (thirdMark + l1, angle, "Up")]
                break
            }
            let third = first + spacing + run
            steps = [(first, angle, "Up"), (first + spacing, angle, "Down"), (third, angle, "Down"), (third + spacing, angle, "Up")]
        case "Kick":
            guard (try? MoreBendCalculations.kickTravel(rise: rise, angleDegrees: angle)) != nil else {
                message = "Kick rise or angle is invalid."; return
            }
            steps = [(first, angle, "Up")]
        case "Rolling Offset":
            let trueRise = hypot(rise, run)
            steps = [(first, angle, "Up"), (first + trueRise / sin(angle * .pi / 180), angle, "Down")]
        case "Segmented Arc":
            guard let radius = number(centerlineRadius), let count = Int(segmentCount),
                  let plan = try? BendPlanGeometry.segmentedArc(radius: radius, totalAngle: angle, segments: count, arcStart: first) else {
                showAdvancedBenderOptions = true
                message = "Enter a verified centerline radius and 2–30 segments. Arc stations are theoretical, not bender arrow marks."
                return
            }
            steps = plan.stations.map { ($0, plan.anglePerBend, "Up") }
        case "Compound 90°":
            guard let radius = number(centerlineRadius),
                  let stations = try? BendPlanGeometry.compoundNinetyStations(firstStation: first, tangentBetweenArcs: run, radius: radius) else {
                showAdvancedBenderOptions = true
                message = "Enter a documented centerline bend radius to calculate compound-90 centerline geometry."
                return
            }
            steps = [(stations.0, 90, "Up"), (stations.1, 90, "Right")]
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
        if preset == "Offset" && verifiedModelID.hasPrefix("greenlee-555") {
            message = "Greenlee 555 X-table marks: align each mark with front hook edge, rotate conduit 180 degrees for second bend. Approximate multiplier; verify minimum offset and springback."
        } else if preset == "Compound 90°" {
            message = "Radius-based 90 + 90 centerline stations generated. NOT bender arrow marks; confirm model-specific references and test bend."
        } else if preset == "Segmented Arc" {
            message = "Radius-based segmented centerline stations generated. The exact shoe marks and tangent lengths require a verified segment-bender manual."
        } else if preset == "Rolling Offset" {
            message = String(format: "Roll orientation %.1f degrees. Verify orientation and bender calibration.", atan2(run, rise) * 180 / .pi)
        } else if preset == "Kick" {
            let travel = (try? MoreBendCalculations.kickTravel(rise: rise, angleDegrees: angle)) ?? 0
            message = String(format: "Kick starts at %.2f %@ (user supplied); theoretical horizontal travel %.2f %@. Confirm reference mark and springback.", first, unitLabel, travel, unitLabel)
        } else {
            message = "Theoretical marks ready. Confirm reference marks, bend direction, radius and springback."
        }
    }

    private func addMark() {
        guard let position = dimension(markPosition),
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

    private func calibratedStubPosition(for desired: Double) -> Double? {
        if requiresIMCHardware && !confirmedIMCHardware {
            message = "Confirm 28008 shoe group AND 13856 IMC squeeze roller before marking."
            return nil
        }
        guard !manufacturer.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty,
              !benderModel.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty,
              !tradeSize.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty,
              !manualSource.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty,
              ["arrow", "hook front"].contains(referenceMark.lowercased()),
              let take = dimension(takeUp),
              let offset = dimension(correction), desired.isFinite, desired > 0 else {
            message = "Select a verified bender profile or enter an exact model, manual source, arrow/hook-front deduct and field correction in Advanced bender options."
            return nil
        }
        if (verifiedModelID.hasPrefix("greenlee-555") || (manufacturer.lowercased().contains("greenlee") && benderModel.contains("555"))),
           desired < take + (selectedUnits == 0 ? 50.8 : selectedUnits == 1 ? 5.08 : 2) {
            message = "Greenlee 555 minimum stub is deduct + 2 inches. Increase the desired stub."; return nil
        }
        let calibration = BenderCalibration(manufacturer: manufacturer, model: benderModel, conduit: conduitType, tradeSize: tradeSize, referenceMark: referenceMark, takeUp: take, fieldCorrection: offset, source: manualSource)
        guard let position = calibration.stubPosition(for: desired), position > 0 else {
            message = "Desired stub is shorter than the documented bender take-up or field correction is invalid."
            return nil
        }
        return position
    }

    private func addCalibratedMark() {
        guard let desired = dimension(desiredStub),
              let position = calibratedStubPosition(for: desired),
              FieldBendGeometry.isFeasible(markPositions: marks.map(\.position) + [position], conduitLength: length, minStraight: clearance) else {
            if message.isEmpty { message = "Calibrated mark is invalid or conflicts with existing marks." }
            return
        }
        marks.append(BendMark(position: position, angle: 90, direction: direction))
        pdfURL = nil
        message = "Stub mark added using your manual-supplied calibration."
    }

    private func makePDF() {
        let page = CGRect(x: 0, y: 0, width: 595, height: 842)
        let renderer = UIGraphicsPDFRenderer(bounds: page)
        let marksPerPage = 20
        let pageCount = max(1, (sorted.count + marksPerPage - 1) / marksPerPage)
        let allMarks = sorted
        let data = renderer.pdfData { context in
            for page in 0..<pageCount {
                context.beginPage()
                let title = "VisionBend - Multi-Bend Marking Sheet (\(page + 1)/\(pageCount))"
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
            for mark in allMarks {
                let x = left + width * CGFloat(mark.position / length)
                let tick = UIBezierPath()
                tick.move(to: CGPoint(x: x, y: baseline - 14))
                tick.addLine(to: CGPoint(x: x, y: baseline + 14))
                tick.lineWidth = 1
                tick.stroke()
            }
            for (index, mark) in allMarks.enumerated() where index / marksPerPage == page {
                let line = String(format: "%d. From start: %.2f  |  Angle: %.1f deg  |  %@", index + 1, mark.position, mark.angle, mark.direction)
                line.draw(at: CGPoint(x: 36, y: 225 + CGFloat(index % marksPerPage) * 23), withAttributes: [.font: UIFont.systemFont(ofSize: 11)])
            }
            if !backToBackInstructions.isEmpty {
                backToBackInstructions.draw(in: CGRect(x: 36, y: 685, width: 520, height: 74),
                                            withAttributes: [.font: UIFont.systemFont(ofSize: 10)])
            }
            let caution = "SCHEMATIC ONLY. Verify bender reference and calibration before field use."
            caution.draw(in: CGRect(x: 36, y: 760, width: 520, height: 55), withAttributes: [.font: UIFont.systemFont(ofSize: 10)])
            }
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
