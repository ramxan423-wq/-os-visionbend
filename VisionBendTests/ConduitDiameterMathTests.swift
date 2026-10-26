import XCTest
@testable import VisionBend

final class ConduitDiameterMathTests: XCTestCase {
    func testReferenceScale() {
        let estimate = ConduitDiameterMath.calibratedDiameter(conduitPixels: 100, referencePixels: 200, referenceMillimeters: 50)
        XCTAssertEqual(estimate?.millimeters ?? -1, 25, accuracy: 0.001)
    }

    func testInvalidReference() {
        XCTAssertNil(ConduitDiameterMath.calibratedDiameter(conduitPixels: 100, referencePixels: 0, referenceMillimeters: 50))
    }

    func testPerspectiveGeometry() {
        let estimate = ConduitDiameterMath.physicalDiameter(widthPixels: 100, depthMeters: 1, focalLengthPixels: 1000)
        XCTAssertEqual(estimate?.millimeters ?? -1, 100, accuracy: 0.001)
    }

    func testOverflowDoesNotProduceAnInfiniteDiameter() {
        XCTAssertNil(ConduitDiameterMath.calibratedDiameter(conduitPixels: 1e308, referencePixels: 0.01, referenceMillimeters: 1e308))
        XCTAssertNil(ConduitDiameterMath.physicalDiameter(widthPixels: 1e308, depthMeters: 1e308, focalLengthPixels: 1))
    }
}
