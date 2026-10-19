import SwiftUI

struct SettingsView: View {
    @AppStorage("visionbend.appearance") private var appearance = 1
    @AppStorage("visionbend.units") private var units = 0

    var body: some View {
        NavigationStack {
            Form {
                Section("Görünüm / Appearance") {
                    Picker("Tema / Theme", selection: $appearance) {
                        Text("Sistem / System").tag(0)
                        Text("Beyaz / Light").tag(1)
                        Text("Siyah / Dark").tag(2)
                    }
                }
                Section("Ölçüler / Measurements") {
                    Picker("Birimler / Units", selection: $units) {
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
