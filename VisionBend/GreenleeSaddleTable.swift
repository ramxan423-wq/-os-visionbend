import Foundation

/// Exact published Greenlee 555 single-shoe table cells. No interpolation.
enum GreenleeSaddleTable {
    struct Row {
        let modelID: String
        let angle: Double
        let heightInches: Double
        let z: Double
        let l1: Double
        let l2: Double
    }
    static let source = "https://cdn.greenlee.com/resources/media?key=ef718feb-3f4e-434a-95f2-a90e3199e8df&languageCode=en&type=document"
    // Manufacturer manual p.16, 1/2-inch EMT, 15 degrees, H 2–12 inches.
    static let rows: [Row] = [
        Row(modelID: "greenlee-555cx-emt-half", angle: 15, heightInches: 2, z: 10.70, l1: 7.72, l2: 8.94),
        Row(modelID: "greenlee-555cx-emt-half", angle: 15, heightInches: 4, z: 18.16, l1: 15.45, l2: 16.66),
        Row(modelID: "greenlee-555cx-emt-half", angle: 15, heightInches: 6, z: 25.62, l1: 23.18, l2: 24.39),
        Row(modelID: "greenlee-555cx-emt-half", angle: 15, heightInches: 8, z: 33.09, l1: 30.90, l2: 32.12),
        Row(modelID: "greenlee-555cx-emt-half", angle: 15, heightInches: 10, z: 40.55, l1: 38.63, l2: 39.84),
        Row(modelID: "greenlee-555cx-emt-half", angle: 15, heightInches: 12, z: 48.02, l1: 46.36, l2: 47.57),
        Row(modelID: "greenlee-555cx-emt-half", angle: 22.5, heightInches: 2, z: 8.68, l1: 5.2, l2: 7.02),
        Row(modelID: "greenlee-555cx-emt-half", angle: 22.5, heightInches: 4, z: 13.51, l1: 10.43, l2: 12.25),
        Row(modelID: "greenlee-555cx-emt-half", angle: 22.5, heightInches: 6, z: 18.34, l1: 15.65, l2: 17.48),
        Row(modelID: "greenlee-555cx-emt-half", angle: 22.5, heightInches: 8, z: 23.17, l1: 20.88, l2: 22.7),
        Row(modelID: "greenlee-555cx-emt-half", angle: 22.5, heightInches: 10, z: 28, l1: 26.11, l2: 27.93),
        Row(modelID: "greenlee-555cx-emt-half", angle: 22.5, heightInches: 12, z: 32.83, l1: 31.33, l2: 33.16)
,
        Row(modelID: "greenlee-555cx-imc-half", angle: 30, heightInches: 4, z: 11.78, l1: 7.95, l2: 10.24),
        Row(modelID: "greenlee-555cx-imc-half", angle: 30, heightInches: 6, z: 15.24, l1: 11.95, l2: 14.24),
        Row(modelID: "greenlee-555cx-imc-half", angle: 30, heightInches: 8, z: 18.7, l1: 15.95, l2: 18.24),
        Row(modelID: "greenlee-555cx-imc-half", angle: 30, heightInches: 10, z: 22.17, l1: 19.95, l2: 22.24),
        Row(modelID: "greenlee-555cx-imc-half", angle: 30, heightInches: 12, z: 25.63, l1: 23.95, l2: 26.24),
        Row(modelID: "greenlee-555cx-imc-half", angle: 45, heightInches: 6, z: 12.13, l1: 8.3, l2: 11.74),
        Row(modelID: "greenlee-555cx-imc-half", angle: 45, heightInches: 8, z: 14.13, l1: 11.13, l2: 14.57),
        Row(modelID: "greenlee-555cx-imc-half", angle: 45, heightInches: 10, z: 16.13, l1: 13.95, l2: 17.39),
        Row(modelID: "greenlee-555cx-imc-half", angle: 45, heightInches: 12, z: 18.13, l1: 16.78, l2: 20.22),
        Row(modelID: "greenlee-555cx-imc-half", angle: 60, heightInches: 8, z: 12.18, l1: 8.77, l2: 13.35),
        Row(modelID: "greenlee-555cx-imc-half", angle: 60, heightInches: 10, z: 13.33, l1: 11.08, l2: 15.66),
        Row(modelID: "greenlee-555cx-imc-half", angle: 60, heightInches: 12, z: 14.49, l1: 13.39, l2: 17.97),
        Row(modelID: "greenlee-555cx-28008-rigid-half", angle: 30, heightInches: 4, z: 11.78, l1: 7.95, l2: 10.24),
        Row(modelID: "greenlee-555cx-28008-rigid-half", angle: 30, heightInches: 6, z: 15.24, l1: 11.95, l2: 14.24),
        Row(modelID: "greenlee-555cx-28008-rigid-half", angle: 30, heightInches: 8, z: 18.7, l1: 15.95, l2: 18.24),
        Row(modelID: "greenlee-555cx-28008-rigid-half", angle: 30, heightInches: 10, z: 22.17, l1: 19.95, l2: 22.24),
        Row(modelID: "greenlee-555cx-28008-rigid-half", angle: 30, heightInches: 12, z: 25.63, l1: 23.95, l2: 26.24),
        Row(modelID: "greenlee-555cx-28008-rigid-half", angle: 45, heightInches: 6, z: 12.13, l1: 8.3, l2: 11.74),
        Row(modelID: "greenlee-555cx-28008-rigid-half", angle: 45, heightInches: 8, z: 14.13, l1: 11.13, l2: 14.57),
        Row(modelID: "greenlee-555cx-28008-rigid-half", angle: 45, heightInches: 10, z: 16.13, l1: 13.95, l2: 17.39),
        Row(modelID: "greenlee-555cx-28008-rigid-half", angle: 45, heightInches: 12, z: 18.13, l1: 16.78, l2: 20.22),
        Row(modelID: "greenlee-555cx-28008-rigid-half", angle: 60, heightInches: 8, z: 12.18, l1: 8.77, l2: 13.35),
        Row(modelID: "greenlee-555cx-28008-rigid-half", angle: 60, heightInches: 10, z: 13.33, l1: 11.08, l2: 15.66),
        Row(modelID: "greenlee-555cx-28008-rigid-half", angle: 60, heightInches: 12, z: 14.49, l1: 13.39, l2: 17.97)
    ]
    static func exact(modelID: String, angle: Double, heightInches: Double) -> Row? {
        rows.first { $0.modelID == modelID && abs($0.angle - angle) < 0.0001 && abs($0.heightInches - heightInches) < 0.0001 }
    }
}
