import Foundation

/// Theoretical centerline geometry. Machine-specific bend marks require calibrated profiles.
enum FieldBendGeometry {
    static func backToBackMark(firstStub: Double, secondStub: Double, takeUp: Double) throws -> (Double, Double) {
        guard firstStub.isFinite, secondStub.isFinite, takeUp.isFinite, firstStub > takeUp, secondStub > takeUp, takeUp >= 0 else { throw BendCalculationError.invalidInput }
        return (firstStub - takeUp, secondStub - takeUp)
    }

    static func kickedNinety(kickRise: Double, kickAngle: Double, stub: Double, takeUp: Double) throws -> (Double, Double) {
        let travel = try MoreBendCalculations.kickTravel(rise: kickRise, angleDegrees: kickAngle)
        let mark = try ExtraBendCalculations.ninetyDegreeStubMark(desiredStub: stub, takeUp: takeUp)
        return (travel, mark)
    }

    static func segmentedNinety(radius: Double, segments: Int) throws -> (Double, Double) {
        guard radius.isFinite, radius > 0, (2...30).contains(segments) else { throw BendCalculationError.invalidInput }
        let angle = 90.0 / Double(segments)
        let centerlineStep = radius * (.pi / 2) / Double(segments)
        return (angle, centerlineStep)
    }

    static func parallelKick(rise: Double, angle: Double, separation: Double) throws -> (Double, Double) {
        let travel = try MoreBendCalculations.kickTravel(rise: rise, angleDegrees: angle)
        guard separation.isFinite, separation >= 0 else { throw BendCalculationError.invalidInput }
        return (travel, separation / sin(angle * .pi / 180))
    }

    static func setback(radius: Double, angle: Double) throws -> Double {
        guard radius.isFinite, angle.isFinite, radius > 0, angle > 0, angle <= 90 else { throw BendCalculationError.invalidInput }
        return radius * tan(angle * .pi / 360)
    }

    static func gain(radius: Double, angle: Double) throws -> Double {
        let setbackValue = try setback(radius: radius, angle: angle)
        let arc = try MoreBendCalculations.arcLength(centerlineRadius: radius, angleDegrees: angle)
        return 2 * setbackValue - arc
    }

    static func obstacleClearance(width: Double, height: Double, clearance: Double, circular: Bool) throws -> (Double, Double) {
        guard width.isFinite, height.isFinite, clearance.isFinite, width > 0, height > 0, clearance >= 0 else { throw BendCalculationError.invalidInput }
        return (width + 2 * clearance, (circular ? width : height) + 2 * clearance)
    }

    static func isFeasible(markPositions: [Double], conduitLength: Double, minStraight: Double) -> Bool {
        guard conduitLength.isFinite, minStraight.isFinite, conduitLength > 0, minStraight >= 0,
              markPositions.allSatisfy({ $0.isFinite && $0 >= 0 && $0 <= conduitLength }) else { return false }
        let sorted = markPositions.sorted()
        return zip(sorted, sorted.dropFirst()).allSatisfy { $1 - $0 >= minStraight }
    }
}
