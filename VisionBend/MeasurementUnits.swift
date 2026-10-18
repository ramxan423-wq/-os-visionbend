import Foundation

enum MeasurementUnit: Int, CaseIterable, Identifiable {
    case millimeters = 0, centimeters = 1, inches = 2
    var id: Int { rawValue }
    var symbol: String {
        switch self {
        case .millimeters: return "mm"
        case .centimeters: return "cm"
        case .inches: return "in"
        }
    }
    var millimetersPerUnit: Double {
        switch self {
        case .millimeters: return 1
        case .centimeters: return 10
        case .inches: return 25.4
        }
    }
    func convert(_ value: Double, to target: MeasurementUnit) -> Double {
        value * millimetersPerUnit / target.millimetersPerUnit
    }
}
