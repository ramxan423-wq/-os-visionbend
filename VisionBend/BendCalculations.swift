import Foundation

enum BendCalculationError: LocalizedError {
    case invalidInput
    var errorDescription: String? { "Pozitif ölçüler ve 0–90° arasında bir açı girin." }
}

enum BendCalculations {
    static func offsetSpacing(rise: Double, angleDegrees: Double) throws -> Double {
        guard rise.isFinite, angleDegrees.isFinite, rise > 0, angleDegrees > 0, angleDegrees < 90 else { throw BendCalculationError.invalidInput }
        return rise / sin(angleDegrees * .pi / 180)
    }

    static func offsetShrink(rise: Double, angleDegrees: Double) throws -> Double {
        guard rise > 0, angleDegrees > 0, angleDegrees < 90 else { throw BendCalculationError.invalidInput }
        return rise * tan(angleDegrees * .pi / 360)
    }

    // Symmetric three-point saddle: outer bends at half the center angle.
    static func saddleOuterMarkDistance(height: Double, centerAngleDegrees: Double) throws -> Double {
        guard height.isFinite, centerAngleDegrees.isFinite, height > 0, centerAngleDegrees > 0, centerAngleDegrees < 180 else { throw BendCalculationError.invalidInput }
        return height / sin(centerAngleDegrees * .pi / 360)
    }
}
