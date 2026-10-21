import XCTest
@testable import VisionBend

final class ConduitCutInputTests: XCTestCase {
    func testCommaSeparatedLengths() {
        XCTAssertEqual(ConduitCutInput.lengths("850, 850, 420, 300", unit: .millimeters) ?? [], [850, 850, 420, 300])
    }

    func testDecimalCommasWithSemicolons() {
        XCTAssertEqual(ConduitCutInput.lengths("12,5; 3,25", unit: .centimeters) ?? [], [12.5, 3.25])
    }

    func testNewlinesWithDecimalCommas() {
        XCTAssertEqual(ConduitCutInput.lengths("12,5\n3,25", unit: .centimeters) ?? [], [12.5, 3.25])
    }

    func testFractionalInches() {
        XCTAssertEqual(ConduitCutInput.lengths("1 1/2, 3/8", unit: .inches) ?? [], [1.5, 0.375])
    }

    func testInvalidListsDoNotSilentlyDropParts() {
        XCTAssertNil(ConduitCutInput.lengths("100,, 200", unit: .millimeters))
        XCTAssertNil(ConduitCutInput.lengths("100,abc", unit: .millimeters))
        XCTAssertNil(ConduitCutInput.lengths("", unit: .millimeters))
    }

    func testUnitConversionsKeepSeparator() {
        XCTAssertEqual(ConduitCutInput.convertedText("25,4; 50,8", from: .millimeters, to: .inches), "1.0000; 2.0000")
        XCTAssertEqual(ConduitCutInput.convertedText("100, 200", from: .millimeters, to: .centimeters), "10.0000, 20.0000")
    }
}
