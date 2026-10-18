import XCTest
@testable import VisionBend

final class MoreBendCalculationsTests: XCTestCase {
    func testKick() throws {
        XCTAssertEqual(try MoreBendCalculations.kickTravel(rise: 10, angleDegrees: 45), 10, accuracy: 0.0001)
    }

    func testArc() throws {
        XCTAssertEqual(try MoreBendCalculations.arcLength(centerlineRadius: 100, angleDegrees: 90), 50 * .pi, accuracy: 0.0001)
    }

    func testRollingOffset() throws {
        XCTAssertEqual(try MoreBendCalculations.rollingOffset(horizontal: 3, vertical: 4), 5, accuracy: 0.0001)
        XCTAssertEqual(try MoreBendCalculations.rollingOffsetMarkSpacing(horizontal: 3, vertical: 4, angleDegrees: 30), 10, accuracy: 0.0001)
    }

    func testInvalid() {
        XCTAssertThrowsError(try MoreBendCalculations.kickTravel(rise: 10, angleDegrees: 90))
        XCTAssertThrowsError(try MoreBendCalculations.arcLength(centerlineRadius: 0, angleDegrees: 90))
        XCTAssertThrowsError(try MoreBendCalculations.rollingOffset(horizontal: 0, vertical: 0))
    }
}
