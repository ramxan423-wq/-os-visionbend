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
}
