import Foundation

struct BenderProfile: Codable, Identifiable {
    var id = UUID()
    var manufacturer: String
    var model: String
    var conduitType: String
    var conduitSize: String
    var takeUp: String
    var radius: String
    var notes: String
    var source: String
    // Optional to decode profiles created before units and reference metadata existed.
    // Legacy values must be checked manually instead of guessing their units.
    var unitCode: Int? = nil
    var referenceMark: String? = nil

    func calibratedValues(in unit: MeasurementUnit) -> (takeUp: Double, radius: Double, referenceMark: String)? {
        guard let code = unitCode, let from = MeasurementUnit(rawValue: code),
              let savedTakeUp = FieldInputNumber.parse(takeUp, unit: from), savedTakeUp >= 0,
              let savedRadius = FieldInputNumber.parse(radius, unit: from), savedRadius > 0,
              let referenceMark, ["arrow", "hook front"].contains(referenceMark.lowercased()) else { return nil }
        let convertedTakeUp = from.convert(savedTakeUp, to: unit)
        let convertedRadius = from.convert(savedRadius, to: unit)
        guard convertedTakeUp.isFinite, convertedRadius.isFinite else { return nil }
        return (convertedTakeUp, convertedRadius, referenceMark)
    }
}
