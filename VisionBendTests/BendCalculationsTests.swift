import XCTest
@testable import VisionBend

final class BendCalculationsTests: XCTestCase {
    func testThirtyDegreeOffset() throws {
        XCTAssertEqual(try BendCalculations.offsetSpacing(rise: 10, angleDegrees: 30), 20, accuracy: 0.0001)
        XCTAssertEqual(try BendCalculations.offsetShrink(rise: 10, angleDegrees: 30), 2.6794919, accuracy: 0.0001)
    }

    func testSaddleOuterMark() throws {
        XCTAssertEqual(try BendCalculations.saddleOuterMarkDistance(height: 10, centerAngleDegrees: 60), 20, accuracy: 0.0001)
    }

    func testStandardOffsetAngles() throws {
        XCTAssertEqual(try BendCalculations.offsetSpacing(rise: 12, angleDegrees: 30), 24, accuracy: 0.0001)
        XCTAssertEqual(try BendCalculations.offsetSpacing(rise: 10, angleDegrees: 45), 14.1421356, accuracy: 0.0001)
        XCTAssertEqual(try BendCalculations.offsetSpacing(rise: 10, angleDegrees: 60), 11.5470054, accuracy: 0.0001)
    }

    func testInvalidAngles() {
        XCTAssertThrowsError(try BendCalculations.offsetSpacing(rise: 10, angleDegrees: 0))
        XCTAssertThrowsError(try BendCalculations.offsetSpacing(rise: -1, angleDegrees: 30))
        XCTAssertThrowsError(try BendCalculations.saddleOuterMarkDistance(height: 10, centerAngleDegrees: 180))
    }
}
