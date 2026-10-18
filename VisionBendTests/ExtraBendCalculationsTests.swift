import XCTest
@testable import VisionBend

final class ExtraBendCalculationsTests: XCTestCase {
    func testStubDeduct() throws {
        XCTAssertEqual(try ExtraBendCalculations.ninetyDegreeStubMark(desiredStub: 300, takeUp: 120), 180)
    }
    func testStubInvalid() {
        XCTAssertThrowsError(try ExtraBendCalculations.ninetyDegreeStubMark(desiredStub: 100, takeUp: 120))
    }
    func testFourPointSpacing() throws {
        XCTAssertEqual(try ExtraBendCalculations.fourPointSaddleMarkSpacing(clearance: 100, bendAngleDegrees: 30), 200, accuracy: 0.0001)
    }
}
