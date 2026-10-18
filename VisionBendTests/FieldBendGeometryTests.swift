import XCTest
@testable import VisionBend

final class FieldBendGeometryTests: XCTestCase {
    func testBackToBack() throws {
        let marks = try FieldBendGeometry.backToBackMark(firstStub: 30, secondStub: 40, takeUp: 6)
        XCTAssertEqual(marks.0, 24)
        XCTAssertEqual(marks.1, 34)
    }
    func testSegmented() throws {
        let result = try FieldBendGeometry.segmentedNinety(radius: 10, segments: 6)
        XCTAssertEqual(result.0, 15)
        XCTAssertEqual(result.1, Double.pi * 10 / 12, accuracy: 0.00001)
    }
    func testFeasibility() {
        XCTAssertTrue(FieldBendGeometry.isFeasible(markPositions: [10, 30], conduitLength: 50, minStraight: 10))
        XCTAssertFalse(FieldBendGeometry.isFeasible(markPositions: [10, 15], conduitLength: 50, minStraight: 10))
    }
    func testInvalidRadius() {
        XCTAssertThrowsError(try FieldBendGeometry.segmentedNinety(radius: 0, segments: 6))
    }
}
