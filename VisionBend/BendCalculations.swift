import Foundation

enum BendCalculationError: LocalizedError {
    case invalidInput
    var errorDescription: String? { "Enter valid positive measurements and an angle supported by this bend calculation." }
}

enum BendCalculations {
    static func offsetSpacing(rise: Double, angleDegrees: Double) throws -> Double {
        guard rise.isFinite, angleDegrees.isFinite, rise > 0, angleDegrees > 0, angleDegrees < 90 else { throw BendCalculationError.invalidInput }
        let spacing = rise / sin(angleDegrees * .pi / 180)
        guard spacing.isFinite else { throw BendCalculationError.invalidInput }
        return spacing
    }

    static func offsetShrink(rise: Double, angleDegrees: Double) throws -> Double {
        guard rise.isFinite, angleDegrees.isFinite, rise > 0, angleDegrees > 0, angleDegrees < 90 else { throw BendCalculationError.invalidInput }
        let shrink = rise * tan(angleDegrees * .pi / 360)
        guard shrink.isFinite else { throw BendCalculationError.invalidInput }
        return shrink
    }

    // Symmetric three-point saddle: outer bends at half the center angle.
    static func saddleOuterMarkDistance(height: Double, centerAngleDegrees: Double) throws -> Double {
        guard height.isFinite, centerAngleDegrees.isFinite, height > 0, centerAngleDegrees > 0, centerAngleDegrees < 180 else { throw BendCalculationError.invalidInput }
        let spacing = height / sin(centerAngleDegrees * .pi / 360)
        guard spacing.isFinite else { throw BendCalculationError.invalidInput }
        return spacing
    }
}
