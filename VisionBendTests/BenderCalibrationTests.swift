import XCTest
@testable import VisionBend

final class BenderCalibrationTests: XCTestCase {
    func testStubMarkWithVerifiedManualValues() {
        let model = BenderCalibration(manufacturer: "Example", model: "Sample", conduit: "EMT", tradeSize: "1/2", referenceMark: "Arrow", takeUp: 5, fieldCorrection: 0, source: "Test fixture only")
        XCTAssertEqual(model.stubPosition(for: 30), 25)
    }

    func testInvalidInputsAreRejected() {
        let model = BenderCalibration(manufacturer: "Example", model: "Sample", conduit: "EMT", tradeSize: "1/2", referenceMark: "Arrow", takeUp: 5, fieldCorrection: 0, source: "Test fixture only")
        XCTAssertNil(model.stubPosition(for: 3))
        XCTAssertNil(model.stubPosition(for: .infinity))
        XCTAssertNil(model.stubPosition(for: .nan))
    }
}
