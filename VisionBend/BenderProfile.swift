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
}
