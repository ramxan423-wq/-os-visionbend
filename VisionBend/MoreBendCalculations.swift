import Foundation

enum MoreBendCalculations {
    static func degreesToRadians(_ angle: Double) -> Double { angle * .pi / 180 }

    /// Horizontal distance needed for a kick bend, ignoring bender-specific take-up.
    static func kickTravel(rise: Double, angleDegrees: Double) throws -> Double {
        guard rise.isFinite, angleDegrees.isFinite, rise > 0,
              angleDegrees > 0, angleDegrees < 90 else { throw BendCalculationError.invalidInput }
        let travel = rise / tan(degreesToRadians(angleDegrees))
        guard travel.isFinite else { throw BendCalculationError.invalidInput }
        return travel
    }

    /// Centerline arc length of a bend, with radius measured to conduit centerline.
    static func arcLength(centerlineRadius: Double, angleDegrees: Double) throws -> Double {
        guard centerlineRadius.isFinite, angleDegrees.isFinite,
              centerlineRadius > 0, angleDegrees > 0, angleDegrees <= 180
        else { throw BendCalculationError.invalidInput }
        let length = centerlineRadius * degreesToRadians(angleDegrees)
        guard length.isFinite else { throw BendCalculationError.invalidInput }
        return length
    }

    /// Distance between two parallel conduit centerlines after an offset.
    static func rollingOffset(horizontal: Double, vertical: Double) throws -> Double {
        guard horizontal.isFinite, vertical.isFinite, horizontal >= 0, vertical >= 0,
              horizontal > 0 || vertical > 0 else { throw BendCalculationError.invalidInput }
        let offset = hypot(horizontal, vertical)
        guard offset.isFinite else { throw BendCalculationError.invalidInput }
        return offset
    }

    static func rollingOffsetMarkSpacing(horizontal: Double, vertical: Double, angleDegrees: Double) throws -> Double {
        let rise = try rollingOffset(horizontal: horizontal, vertical: vertical)
        return try BendCalculations.offsetSpacing(rise: rise, angleDegrees: angleDegrees)
    }
}
