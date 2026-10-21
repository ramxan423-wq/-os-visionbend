import Foundation

/// Host-independent numerical smoke test of the same Swift production sources
/// compiled below. This does not simulate camera/AR or iOS UI.
@main struct FieldMathSmoke {
    static func main() throws {
        func near(_ actual: Double, _ expected: Double) {
            precondition(actual.isFinite && abs(actual - expected) < 0.000001,
                         "Expected \(expected), received \(actual)")
        }
        let marks = try AdvancedFieldPatterns.matchingBendsOffset(
            start: 100, rise: 50, angle: 30, betweenPairs: 80)
        precondition(marks.count == 4)
        near(marks[1].position, 200)
        near(marks[2].position, 280)

        let parallel = try AdvancedFieldPatterns.parallelOffsets(
            firstStart: 80, rise: 50, angle: 45, conduitSeparation: 20, count: 3)
        precondition(parallel.count == 3)
        near(parallel[2][0].position, 120)

        let kicks = try AdvancedFieldPatterns.parallelKicks(
            firstStart: 60, rise: 25, angle: 45, conduitSeparation: 25,
            count: 3, forward: true)
        near(kicks[2].position, 110)
        precondition(kicks[1].direction == "Down")

        let compound = try AdvancedFieldPatterns.compound90(
            shape: .rectangle, width: 100, height: 200, clearance: 10,
            centerlineRadius: 60)
        near(compound.diagonalTravel, hypot(120, 220))
        near(compound.arcLength90!, .pi * 30)

        let impossible = FieldQuickCheck.evaluate(
            length: 300,
            marks: [.init(position: 100, angle: 30, direction: "Up"),
                    .init(position: 108, angle: 30, direction: "Down")],
            minimumStraight: 20)
        precondition(impossible.severity == .impossible && !impossible.canProceed)

        let caution = FieldQuickCheck.evaluate(
            length: 300,
            marks: [.init(position: 100, angle: 30, direction: "Up")],
            minimumStraight: 20)
        precondition(caution.severity == .caution && caution.canProceed)

        let reversed = try AdvancedFieldPatterns.reversedMeasurements(
            [.init(position: 25, angle: 30, direction: "Left")], conduitLength: 200)
        near(reversed[0].position, 175)
        precondition(AdvancedFieldPatterns.oppositeDirection("Left") == "Right")
        let manufacturerIDs = VerifiedBenderCatalog.entries.map(\.id)
        precondition(Set(manufacturerIDs).count == manufacturerIDs.count,
                     "Manufacturer catalog must not contain duplicate shoe/model IDs")
        let gardner = VerifiedBenderCatalog.entries.first {
            $0.id == "gardner-bigben-960-emt-half"
        }
        precondition(gardner?.deductInches == 5)
        near(gardner?.radiusInches ?? .nan, 3.69)
        for model in ["milwaukee-4080-emt-half",
                      "milwaukee-4081-emt-threequarter",
                      "milwaukee-4082-emt-one"] {
            let row = VerifiedBenderCatalog.entries.first { $0.id == model }
            precondition(row != nil && row?.deductInches == nil && row?.radiusInches == nil,
                         "Never claim undocumented Milwaukee shoe dimensions")
        }
        let bender = BenderCalibration(manufacturer: "Gardner Bender", model: "960",
                                       conduit: "EMT", tradeSize: "1/2 in",
                                       referenceMark: "Arrow", takeUp: 5,
                                       fieldCorrection: 0, source: "manufacturer guide")
        near(bender.stubPosition(for: 25) ?? .nan, 20)
        print("PASS: 10 Swift numerical, manufacturer catalog and QuickCheck smoke-test groups")
    }
}
