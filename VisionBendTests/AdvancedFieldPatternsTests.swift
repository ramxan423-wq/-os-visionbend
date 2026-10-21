import XCTest
@testable import VisionBend

final class AdvancedFieldPatternsTests: XCTestCase {
    func testMatchingBendsAndCenters() throws {
        let result = try AdvancedFieldPatterns.matchingBendsOffset(
            start: 100, rise: 50, angle: 30, betweenPairs: 80)
        XCTAssertEqual(result.count, 4)
        XCTAssertEqual(result[0].position, 100, accuracy: 1e-9)
        XCTAssertEqual(result[1].position, 200, accuracy: 1e-9)
        XCTAssertEqual(result[2].position, 280, accuracy: 1e-9)
        XCTAssertEqual(result[3].position, 380, accuracy: 1e-9)
        let centers = try AdvancedFieldPatterns.matchingCentersOffset(
            center: 300, rise: 50, angle: 30, centerGap: 40)
        XCTAssertEqual(centers.map(\.position), [180, 280, 320, 420])
        XCTAssertThrowsError(try AdvancedFieldPatterns.matchingCentersOffset(
            center: 20, rise: 50, angle: 30, centerGap: 40))
    }
    func testParallelOffsetAndKickFamilies() throws {
        let rows = try AdvancedFieldPatterns.parallelOffsets(
            firstStart: 80, rise: 50, angle: 45,
            conduitSeparation: 20, count: 3)
        XCTAssertEqual(rows.count, 3)
        XCTAssertEqual(rows[2][0].position, 120, accuracy: 1e-9)
        XCTAssertEqual(rows[0][1].position, 80 + 50 * sqrt(2), accuracy: 1e-9)
        let kicks = try AdvancedFieldPatterns.parallelKicks(
            firstStart: 60, rise: 25, angle: 45,
            conduitSeparation: 25, count: 3, forward: true)
        XCTAssertEqual(kicks.count, 3)
        XCTAssertEqual(kicks[2].position, 110, accuracy: 1e-9)
        XCTAssertEqual(kicks[1].direction, "Down")
        let paired = try AdvancedFieldPatterns.matchingKick(
            start: 100, rise: 50, angle: 45, separation: 30, alignCenters: true)
        XCTAssertEqual(paired[1].position, 130, accuracy: 1e-9)
    }
    func testCompoundCircleSquareRectangleAndArc() throws {
        let circle = try AdvancedFieldPatterns.compound90(
            shape: .circle, width: 100, height: 10, clearance: 10, centerlineRadius: 60)
        XCTAssertEqual(circle.clearWidth, 120)
        XCTAssertEqual(circle.clearHeight, 120)
        XCTAssertEqual(circle.rotationDegrees, 45, accuracy: 1e-10)
        XCTAssertEqual(circle.arcLength90!, 60 * .pi / 2, accuracy: 1e-10)
        let square = try AdvancedFieldPatterns.compound90(
            shape: .square, width: 100, height: 400, clearance: 10, centerlineRadius: nil)
        XCTAssertEqual(square.clearHeight, 120)
        XCTAssertNil(square.arcLength90)
        let rectangle = try AdvancedFieldPatterns.compound90(
            shape: .rectangle, width: 100, height: 200, clearance: 10, centerlineRadius: nil)
        XCTAssertEqual(rectangle.clearHeight, 220)
        XCTAssertEqual(rectangle.diagonalTravel, hypot(120, 220), accuracy: 1e-9)
        XCTAssertThrowsError(try AdvancedFieldPatterns.compound90(
            shape: .circle, width: 0, height: 10, clearance: 0, centerlineRadius: nil))
        XCTAssertThrowsError(try AdvancedFieldPatterns.compound90(
            shape: .square, width: 10, height: 10, clearance: -1, centerlineRadius: nil))
    }
    func testReversingMeasurementsAndFlippingDirection() throws {
        let marks = [AdvancedFieldPatterns.Station(position: 20, angle: 30, direction: "Up"),
                     AdvancedFieldPatterns.Station(position: 40, angle: 30, direction: "Down")]
        let mirror = try AdvancedFieldPatterns.reversedMeasurements(marks, conduitLength: 100)
        XCTAssertEqual(mirror.map(\.position), [60, 80])
        XCTAssertEqual(mirror[0].direction, "Down")
        XCTAssertEqual(AdvancedFieldPatterns.oppositeDirection("Left"), "Right")
        XCTAssertEqual(AdvancedFieldPatterns.oppositeDirection("Up"), "Down")
        XCTAssertThrowsError(try AdvancedFieldPatterns.reversedMeasurements(marks, conduitLength: 30))
    }
    func testImpossibleInputs() {
        XCTAssertThrowsError(try AdvancedFieldPatterns.parallelOffsets(
            firstStart: 10, rise: 10, angle: 0, conduitSeparation: 10, count: 2))
        XCTAssertThrowsError(try AdvancedFieldPatterns.parallelKicks(
            firstStart: 10, rise: 10, angle: 30, conduitSeparation: 10, count: 21, forward: false))
        XCTAssertThrowsError(try AdvancedFieldPatterns.matchingBendsOffset(
            start: 10, rise: 10, angle: 30, betweenPairs: -1))
        XCTAssertThrowsError(try AdvancedFieldPatterns.offsetPair(
            start: .nan, rise: 10, angle: 30))
    }
}

final class FieldQuickCheckTests: XCTestCase {
    private func item(_ p: Double, angle: Double = 30) -> AdvancedFieldPatterns.Station {
        AdvancedFieldPatterns.Station(position: p, angle: angle, direction: "Up")
    }
    func testSafeGeometryWithVerifiedBender() {
        let r = FieldQuickCheck.evaluate(length: 500, marks: [item(100), item(200)],
                                          minimumStraight: 30, centerlineRadius: 20,
                                          hasVerifiedReference: true)
        XCTAssertEqual(r.severity, .safe)
        XCTAssertTrue(r.canProceed)
    }
    func testCautionForMissingShoeDetails() {
        let r = FieldQuickCheck.evaluate(length: 500, marks: [item(100), item(200)],
                                          minimumStraight: 30)
        XCTAssertEqual(r.severity, .caution)
        XCTAssertTrue(r.canProceed)
    }
    func testRejectOverlapAndOutsideMark() {
        let a = FieldQuickCheck.evaluate(length: 300, marks: [item(100), item(110)],
                                          minimumStraight: 30)
        XCTAssertEqual(a.severity, .impossible)
        XCTAssertFalse(a.canProceed)
        let b = FieldQuickCheck.evaluate(length: 300, marks: [item(-1)],
                                          minimumStraight: 0)
        XCTAssertEqual(b.severity, .impossible)
    }
    func testTangentLengthCautionAndStubValidation() {
        let r = FieldQuickCheck.evaluate(length: 100, marks: [item(4, angle: 90)],
                                          minimumStraight: 1, centerlineRadius: 20,
                                          hasVerifiedReference: true)
        XCTAssertEqual(r.severity, .caution)
        let stub = FieldQuickCheck.evaluate(length: 100, marks: [item(10)],
                                             minimumStraight: 0, takeUp: 20, targetStub: 15)
        XCTAssertEqual(stub.severity, .impossible)
    }
    func testRejectsNaN() {
        XCTAssertEqual(FieldQuickCheck.evaluate(length: .nan, marks: [], minimumStraight: 0).severity,
                       .impossible)
    }
}
