import Foundation

struct BenderCalibration: Codable {
    var manufacturer: String
    var model: String
    var conduit: String
    var tradeSize: String
    var referenceMark: String
    var takeUp: Double
    var fieldCorrection: Double
    var source: String

    func stubPosition(for desiredLength: Double) -> Double? {
        guard desiredLength.isFinite, takeUp.isFinite, fieldCorrection.isFinite,
              desiredLength > 0, takeUp >= 0 else { return nil }
        let position = desiredLength - takeUp + fieldCorrection
        return position >= 0 && position.isFinite ? position : nil
    }
}
