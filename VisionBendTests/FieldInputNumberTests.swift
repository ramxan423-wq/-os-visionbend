import XCTest
@testable import VisionBend

final class FieldInputNumberTests: XCTestCase {
    func testCommaAndFractionLengths() {
        XCTAssertEqual(FieldInputNumber.parse("12,5", unit: .millimeters), 12.5)
        XCTAssertEqual(FieldInputNumber.parse(" 2.54 ", unit: .centimeters), 2.54)
        XCTAssertEqual(FieldInputNumber.parse("1 1/2", unit: .inches), 1.5)
        XCTAssertEqual(FieldInputNumber.parse("1-1/2", unit: .inches), 1.5)
        XCTAssertNil(FieldInputNumber.parse("1/2", unit: .millimeters))
        XCTAssertNil(FieldInputNumber.parse("nan", unit: .millimeters))
        XCTAssertNil(FieldInputNumber.parse("", unit: .inches))
    }

    func testConversionFromMillimetersToInches() {
        XCTAssertEqual(FieldInputNumber.convertedText("25,4", from: .millimeters, to: .inches), "1.0000")
        XCTAssertEqual(FieldInputNumber.convertedText("100", from: .millimeters, to: .centimeters), "10.0000")
        XCTAssertEqual(FieldInputNumber.convertedText("1 1/2", from: .inches, to: .millimeters), "38.1000")
    }

    func testInvalidInputIsNotReplacedByZero() {
        XCTAssertEqual(FieldInputNumber.convertedText("missing", from: .millimeters, to: .inches), "missing")
        XCTAssertEqual(FieldInputNumber.convertedText("12,5", from: .millimeters, to: .millimeters), "12,5")
    }
}
