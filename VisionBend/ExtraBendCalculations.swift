import Foundation

/// Additional geometry-only calculators; verify marking conventions with the actual bender.
enum ExtraBendCalculations {
    static func ninetyDegreeStubMark(desiredStub: Double, takeUp: Double) throws -> Double {
        guard desiredStub.isFinite, takeUp.isFinite, desiredStub > 0, takeUp >= 0,
              desiredStub > takeUp else { throw BendCalculationError.invalidInput }
        return desiredStub - takeUp
    }

    static func fourPointSaddleMarkSpacing(clearance: Double, bendAngleDegrees: Double) throws -> Double {
        try BendCalculations.offsetSpacing(rise: clearance, angleDegrees: bendAngleDegrees)
    }

    static func parallelOffsetSpacing(offset: Double, angleDegrees: Double) throws -> Double {
        try BendCalculations.offsetSpacing(rise: offset, angleDegrees: angleDegrees)
    }

    static func developedBendLength(radius: Double, angleDegrees: Double) throws -> Double {
        try MoreBendCalculations.arcLength(centerlineRadius: radius, angleDegrees: angleDegrees)
    }
}
