import SwiftUI

struct ContentView: View {
    @StateObject private var history = BendHistory()
    @AppStorage("visionbend.appearance") private var appearance = 0
    @AppStorage("visionbend.units") private var units = 0
    @State private var previousUnit = 0
    @State private var showHistory = false
    @State private var showSettings = false
    @State private var showCamera = false
    @State private var showAR = false
    @State private var showPremium = false
    @AppStorage("visionbend.mode") private var mode = 0
    @AppStorage("visionbend.lastHeight") private var height = "10"
    @AppStorage("visionbend.lastAngle") private var angle = "30"
    @State private var output = ""
    @State private var errorMessage = ""
    private let accent = Color(red: 1, green: 0.45, blue: 0.08)

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(alignment: .leading, spacing: 18) {
                    Text("VISIONBEND")
                        .font(.system(size: 30, weight: .black, design: .rounded))
                        .foregroundStyle(accent)
                    Text("Conduit Bending Calculator").foregroundStyle(.secondary)
                    HStack {
                        Button("Saved Bends") { showHistory = true }
                        Spacer()
                        Button("Settings") { showSettings = true }
                    }
                    .tint(accent)
                    Text("Units: " + (units == 0 ? "mm" : units == 1 ? "cm" : "in"))
                        .font(.caption).foregroundStyle(.secondary)
                    Button { showCamera = true } label: {
                        Label("Camera Level", systemImage: "camera.viewfinder")
                            .frame(maxWidth: .infinity)
                    }
                    .buttonStyle(.bordered)
                    .tint(accent)
                    HStack {
                        Button("AR Measure") { showAR = true }
                        Spacer()
                        Button("Premium") { showPremium = true }
                    }.tint(accent)
                    Picker("Mode", selection: $mode) {
                        Text("Offset").tag(0)
                        Text("3-Point Saddle").tag(1)
                        Text("Kick").tag(2)
                        Text("Arc").tag(3)
                        Text("Rolling").tag(4)
                        Text("90° Stub").tag(5)
                        Text("4-Point Saddle").tag(6)
                    }.pickerStyle(.menu)
                    Text(mode == 3 ? "Centerline Radius" : mode == 4 ? "Horizontal Offset" : mode == 5 ? "Desired Stub Length" : "Rise / Height")
                    TextField("Measurement", text: $height)
                        .keyboardType(.decimalPad).textFieldStyle(.roundedBorder)
                    Text(mode == 4 ? "Vertical Offset" : mode == 5 ? "Bender Take-Up" : mode == 1 ? "Center Angle (degrees)" : "Bend Angle (degrees)")
                    TextField("Angle", text: $angle)
                        .keyboardType(.decimalPad).textFieldStyle(.roundedBorder)
                    Button("CALCULATE", action: calculate)
                        .fontWeight(.bold)
                        .frame(maxWidth: .infinity)
                        .buttonStyle(.borderedProminent)
                        .tint(accent)
                    if !errorMessage.isEmpty { Text(errorMessage).foregroundStyle(.red) }
                    if !output.isEmpty {
                        Button("Save Calculation") {
                            guard let first = Double(height.replacingOccurrences(of: ",", with: ".")),
                                  let second = Double(angle.replacingOccurrences(of: ",", with: ".")) else { return }
                            let names = ["Offset", "3-Point Saddle", "Kick", "Arc", "Rolling Offset", "90° Stub", "4-Point Saddle"]
                            history.add(mode: names[mode], first: first, second: second, result: output)
                        }
                        .tint(accent)
                        Text(output)
                            .font(.title3.monospacedDigit())
                            .frame(maxWidth: .infinity, alignment: .leading)
                            .padding()
                            .background(Color.white.opacity(0.09), in: RoundedRectangle(cornerRadius: 12))
                    }
                    Text("Use consistent units. Verify conduit take-up and bender-specific allowances before bending.")
                        .font(.footnote).foregroundStyle(.secondary)
                }.padding()
            }
            .background(Color(uiColor: .systemBackground))
            .onAppear { previousUnit = units }
            .onChange(of: units) { newValue in
                guard let oldUnit = MeasurementUnit(rawValue: previousUnit),
                      let newUnit = MeasurementUnit(rawValue: newValue) else {
                    previousUnit = newValue
                    return
                }
                if let first = Double(height.replacingOccurrences(of: ",", with: ".")), first.isFinite {
                    height = String(format: "%.4f", oldUnit.convert(first, to: newUnit))
                }
                if (mode == 4 || mode == 5), let second = Double(angle.replacingOccurrences(of: ",", with: ".")), second.isFinite {
                    angle = String(format: "%.4f", oldUnit.convert(second, to: newUnit))
                }
                output = ""
                previousUnit = newValue
            }
            .navigationTitle("VisionBend")
            .preferredColorScheme(appearance == 0 ? nil : appearance == 1 ? .light : .dark)
            .sheet(isPresented: $showAR) { NavigationStack { ARMeasureView() } }
            .sheet(isPresented: $showPremium) { NavigationStack { SubscriptionView() } }
            .sheet(isPresented: $showHistory) { ProjectHistoryView(history: history) }
            .sheet(isPresented: $showSettings) { SettingsView() }
            .sheet(isPresented: $showCamera) {
                NavigationStack {
                    CameraLevelView()
                        .toolbar { ToolbarItem(placement: .topBarTrailing) { Button("Done") { showCamera = false } } }
                }
            }
        }
    }

    private func calculate() {
        output = ""
        errorMessage = ""
        guard let rise = Double(height.replacingOccurrences(of: ",", with: ".")),
              let degrees = Double(angle.replacingOccurrences(of: ",", with: ".")),
              rise.isFinite, degrees.isFinite else {
            errorMessage = "Enter valid numeric values."
            return
        }
        do {
            if mode == 0 {
                let spacing = try BendCalculations.offsetSpacing(rise: rise, angleDegrees: degrees)
                let shrink = try BendCalculations.offsetShrink(rise: rise, angleDegrees: degrees)
                output = String(format: "Mark spacing: %.2f\nTheoretical shrink: %.2f", spacing, shrink)
            } else if mode == 1 {
                let distance = try BendCalculations.saddleOuterMarkDistance(height: rise, centerAngleDegrees: degrees)
                output = String(format: "Center to outer mark: %.2f\nOuter bend angle: %.1f°", distance, degrees / 2)
            } else if mode == 2 {
                let travel = try MoreBendCalculations.kickTravel(rise: rise, angleDegrees: degrees)
                output = String(format: "Kick horizontal travel: %.2f", travel)
            } else if mode == 3 {
                let arc = try MoreBendCalculations.arcLength(centerlineRadius: rise, angleDegrees: degrees)
                output = String(format: "Centerline arc length: %.2f", arc)
            } else if mode == 4 {
                let roll = try MoreBendCalculations.rollingOffset(horizontal: rise, vertical: degrees)
                output = String(format: "True rolling offset: %.2f", roll)
            } else if mode == 5 {
                let mark = try ExtraBendCalculations.ninetyDegreeStubMark(desiredStub: rise, takeUp: degrees)
                output = String(format: "Stub mark: %.2f", mark)
            } else if mode == 6 {
                let spacing = try ExtraBendCalculations.fourPointSaddleMarkSpacing(clearance: rise, bendAngleDegrees: degrees)
                output = String(format: "Each offset mark spacing: %.2f", spacing)
            }
        } catch {
            errorMessage = error.localizedDescription
        }
    }
}
