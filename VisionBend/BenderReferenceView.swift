import SwiftUI

/// Reference-only catalogue: never substitute assumed take-up values for manufacturer specifications.
struct BenderReferenceView: View {
    @State private var manufacturer = "Greenlee"
    @State private var model = ""
    @State private var takeUp = ""
    @State private var radius = ""
    @State private var notes = ""
    private let brands = ["Greenlee", "Klein Tools", "IDEAL", "Gardner Bender", "Other"]
    var body: some View {
        Form {
            Section("Manufacturer and model") {
                Picker("Manufacturer", selection: $manufacturer) {
                    ForEach(brands, id: \.self) { Text($0) }
                }
                TextField("Exact model / part number", text: $model)
                TextField("Verified take-up (your selected unit)", text: $takeUp)
                    .keyboardType(.decimalPad)
                TextField("Verified centerline radius", text: $radius)
                    .keyboardType(.decimalPad)
                TextField("Calibration notes", text: $notes)
            }
            Section("Safety and sources") {
                Text("Manufacturer-specific take-up and radius values are not preloaded. Enter values from the manual for your exact bender and conduit size. This screen does not claim manufacturer certification.")
                Text("For PVC, follow the pipe manufacturer's heating and minimum bend-radius guidance; never use metal-conduit deductions without verification.")
            }
        }
        .navigationTitle("Bender Reference")
    }
}
