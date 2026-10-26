import XCTest
@testable import VisionBend

final class BendPlanGeometryTests: XCTestCase {
    func testSegmentedArcUsesRadiusAndNumberOfBends() throws {
        let plan = try BendPlanGeometry.segmentedArc(radius: 200, totalAngle: 90, segments: 5, arcStart: 100)
        XCTAssertEqual(plan.anglePerBend, 18, accuracy: 0.0001)
        XCTAssertEqual(plan.stationSpacing, 20 * Double.pi, accuracy: 0.0001)
        XCTAssertEqual(plan.stations.count, 5)
        XCTAssertEqual(plan.stations.first ?? -1, 100 + 10 * Double.pi, accuracy: 0.0001)
        XCTAssertEqual(plan.stations.last ?? -1, 100 + 90 * Double.pi, accuracy: 0.0001)
    }

    func testCompoundNinetyHasTwoComputedStations() throws {
        let positions = try BendPlanGeometry.compoundNinetyStations(firstStation: 100, tangentBetweenArcs: 300, radius: 50)
        XCTAssertEqual(positions.0, 100, accuracy: 0.0001)
        XCTAssertEqual(positions.1, 400 + 25 * Double.pi, accuracy: 0.0001)
    }

    func testBackToBackSecondMarkIsRelativeToFinishedFirstBend() throws {
        let marks = try BendPlanGeometry.backToBackGuide(firstStub: 300, takeUp: 120, backToBackDistance: 900)
        XCTAssertEqual(marks.firstArrow, 180, accuracy: 0.0001)
        XCTAssertEqual(marks.starFromFirstBack, 900, accuracy: 0.0001)
    }

    func testInvalidPlansAreRejected() {
        XCTAssertThrowsError(try BendPlanGeometry.segmentedArc(radius: 0, totalAngle: 90, segments: 5, arcStart: 0))
        XCTAssertThrowsError(try BendPlanGeometry.segmentedArc(radius: 100, totalAngle: 90, segments: 1, arcStart: 0))
        XCTAssertThrowsError(try BendPlanGeometry.compoundNinetyStations(firstStation: 100, tangentBetweenArcs: -1, radius: 50))
        XCTAssertThrowsError(try BendPlanGeometry.backToBackGuide(firstStub: 100, takeUp: 110, backToBackDistance: 500))
    }
}
