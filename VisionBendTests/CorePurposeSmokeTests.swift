import XCTest
@testable import VisionBend

/// The eight calculators accessible from Home must keep returning coherent values.
/// Values are theoretical geometry; physical bend marks require bender-specific calibration.
final class CorePurposeSmokeTests: XCTestCase {
    func testAllEightHomeCalculations() throws {
        // Offset: spacing and shrink
        XCTAssertEqual(try BendCalculations.offsetSpacing(rise: 10, angleDegrees: 30), 20, accuracy: 0.0001)
        XCTAssertEqual(try BendCalculations.offsetShrink(rise: 10, angleDegrees: 30), 2.6794919, accuracy: 0.0001)

        // 3-point saddle: distance from the center to an outer mark
        XCTAssertEqual(try BendCalculations.saddleOuterMarkDistance(height: 10, centerAngleDegrees: 60), 20, accuracy: 0.0001)

        // Kick: horizontal run
        XCTAssertEqual(try MoreBendCalculations.kickTravel(rise: 10, angleDegrees: 45), 10, accuracy: 0.0001)

        // Arc: centerline developed length
        XCTAssertEqual(try MoreBendCalculations.arcLength(centerlineRadius: 10, angleDegrees: 90), 5 * Double.pi, accuracy: 0.0001)

        // Rolling offset: true rise and two-bend mark spacing
        XCTAssertEqual(try MoreBendCalculations.rollingOffset(horizontal: 3, vertical: 4), 5, accuracy: 0.0001)
        XCTAssertEqual(try MoreBendCalculations.rollingOffsetMarkSpacing(horizontal: 3, vertical: 4, angleDegrees: 30), 10, accuracy: 0.0001)

        // 90-degree stub: calibrated take-up must be supplied by the user
        XCTAssertEqual(try ExtraBendCalculations.ninetyDegreeStubMark(desiredStub: 100, takeUp: 15), 85, accuracy: 0.0001)

        // 4-point saddle: the distance between the two marks of each offset
        XCTAssertEqual(try ExtraBendCalculations.fourPointSaddleMarkSpacing(clearance: 10, bendAngleDegrees: 30), 20, accuracy: 0.0001)

        // Compound 90: geometry only, not final physical marks
        XCTAssertEqual(try AdvancedBendCalculations.compoundNinetyTravel(firstLeg: 3, secondLeg: 4), 5, accuracy: 0.0001)
        XCTAssertEqual(try AdvancedBendCalculations.compoundNinetyRotation(firstLeg: 3, secondLeg: 4), 53.13010235, accuracy: 0.0001)
    }

    func testInvalidFieldInputsAreRejected() {
        XCTAssertThrowsError(try BendCalculations.offsetSpacing(rise: -10, angleDegrees: 30))
        XCTAssertThrowsError(try MoreBendCalculations.kickTravel(rise: 10, angleDegrees: 90))
        XCTAssertThrowsError(try MoreBendCalculations.arcLength(centerlineRadius: 0, angleDegrees: 90))
        XCTAssertThrowsError(try ExtraBendCalculations.ninetyDegreeStubMark(desiredStub: 10, takeUp: 15))
        XCTAssertThrowsError(try ExtraBendCalculations.fourPointSaddleMarkSpacing(clearance: 10, bendAngleDegrees: 90))
        XCTAssertThrowsError(try AdvancedBendCalculations.compoundNinetyTravel(firstLeg: -3, secondLeg: 4))
    }
}
