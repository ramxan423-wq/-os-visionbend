import Foundation

/// Validated theoretical centerline stations. These are not manufacturer arrow/star marks.
enum BendPlanGeometry {
    struct SegmentedArc {
        let anglePerBend: Double
        let stationSpacing: Double
        let stations: [Double]
    }

    static func segmentedArc(radius: Double, totalAngle: Double, segments: Int, arcStart: Double) throws -> SegmentedArc {
        guard radius.isFinite, totalAngle.isFinite, arcStart.isFinite,
              radius > 0, totalAngle > 0, totalAngle <= 180,
              (2...30).contains(segments), arcStart >= 0 else { throw BendCalculationError.invalidInput }
        let developed = try MoreBendCalculations.arcLength(centerlineRadius: radius, angleDegrees: totalAngle)
        let spacing = developed / Double(segments)
        let stations = (0..<segments).map { arcStart + (Double($0) + 0.5) * spacing }
        guard spacing.isFinite, stations.allSatisfy({ $0.isFinite }) else { throw BendCalculationError.invalidInput }
        return SegmentedArc(anglePerBend: totalAngle / Double(segments), stationSpacing: spacing, stations: stations)
    }

    /// Two 90° bends with a straight tangent between the arcs; ideal centerline only.
    static func compoundNinetyStations(firstStation: Double, tangentBetweenArcs: Double, radius: Double) throws -> (Double, Double) {
        guard firstStation.isFinite, tangentBetweenArcs.isFinite, radius.isFinite,
              firstStation >= 0, tangentBetweenArcs >= 0, radius > 0 else { throw BendCalculationError.invalidInput }
        let firstArc = try MoreBendCalculations.arcLength(centerlineRadius: radius, angleDegrees: 90)
        let second = firstStation + firstArc + tangentBetweenArcs
        guard second.isFinite else { throw BendCalculationError.invalidInput }
        return (firstStation, second)
    }

    /// First stub uses an arrow/hook-front deduct; the next bend must be measured
    /// from the back of the *completed* first bend using the bender's star mark.
    /// It is intentionally NOT an absolute second mark on the unbent conduit.
    static func backToBackGuide(firstStub: Double, takeUp: Double, backToBackDistance: Double, fieldCorrection: Double = 0) throws -> (firstArrow: Double, starFromFirstBack: Double) {
        guard backToBackDistance.isFinite, backToBackDistance > 0, fieldCorrection.isFinite else { throw BendCalculationError.invalidInput }
        let first = try ExtraBendCalculations.ninetyDegreeStubMark(desiredStub: firstStub, takeUp: takeUp)
        let calibrated = first + fieldCorrection
        guard calibrated.isFinite, calibrated >= 0 else { throw BendCalculationError.invalidInput }
        return (calibrated, backToBackDistance)
    }
}
