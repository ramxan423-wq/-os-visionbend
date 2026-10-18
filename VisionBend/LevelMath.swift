import Foundation

enum LevelMath {
    static func degrees(radians: Double) -> Double {
        radians * 180 / .pi
    }

    static func isLevel(pitchRadians: Double, rollRadians: Double, toleranceDegrees: Double = 1.0) -> Bool {
        guard pitchRadians.isFinite, rollRadians.isFinite, toleranceDegrees.isFinite,
              toleranceDegrees >= 0 else { return false }
        return abs(degrees(radians: pitchRadians)) <= toleranceDegrees &&
               abs(degrees(radians: rollRadians)) <= toleranceDegrees
    }
}
