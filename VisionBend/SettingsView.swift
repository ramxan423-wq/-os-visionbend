import SwiftUI

struct SettingsView: View {
    @AppStorage("visionbend.appearance") private var appearance = 0
    @AppStorage("visionbend.units") private var units = 0

    var body: some View {
        NavigationStack {
            Form {
                Section("Appearance") {
                    Picker("Theme", selection: $appearance) {
                        Text("System").tag(0)
                        Text("Light").tag(1)
                        Text("Dark").tag(2)
                    }
                }
                Section("Measurements") {
                    Picker("Units", selection: $units) {
                        Text("Millimeters").tag(0)
                        Text("Centimeters").tag(1)
                        Text("Inches").tag(2)
                    }
                    Text("Changing units converts current calculator measurements; saved records retain their original values.")
                        .font(.caption).foregroundStyle(.secondary)
                }
                Section("Safety") {
                    Text("Bending calculations are theoretical. Confirm the bend radius, take-up and deductions for your exact tool.")
                }
            }
            .navigationTitle("Settings")
        }
    }
}
