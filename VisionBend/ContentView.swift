import SwiftUI

struct ContentView: View {
    @State private var mode = 0
    @State private var height = "10"
    @State private var angle = "30"
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
                    Picker("Mode", selection: $mode) {
                        Text("Offset").tag(0)
                        Text("3-Point Saddle").tag(1)
                    }.pickerStyle(.segmented)
                    Text("Rise / Height")
                    TextField("Rise / Height", text: $height)
                        .keyboardType(.decimalPad).textFieldStyle(.roundedBorder)
                    Text(mode == 0 ? "Bend Angle (degrees)" : "Center Angle (degrees)")
                    TextField("Angle", text: $angle)
                        .keyboardType(.decimalPad).textFieldStyle(.roundedBorder)
                    Button("CALCULATE", action: calculate)
                        .fontWeight(.bold)
                        .frame(maxWidth: .infinity)
                        .buttonStyle(.borderedProminent)
                        .tint(accent)
                    if !errorMessage.isEmpty { Text(errorMessage).foregroundStyle(.red) }
                    if !output.isEmpty {
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
            .background(Color.black)
            .navigationTitle("VisionBend")
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
            } else {
                let distance = try BendCalculations.saddleOuterMarkDistance(height: rise, centerAngleDegrees: degrees)
                output = String(format: "Center to outer mark: %.2f\nOuter bend angle: %.1f°", distance, degrees / 2)
            }
        } catch {
            errorMessage = error.localizedDescription
        }
    }
}
