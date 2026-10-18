import XCTest
@testable import VisionBend

final class MeasurementUnitsTests: XCTestCase {
    func testConversions() {
        XCTAssertEqual(MeasurementUnit.inches.convert(1, to: .millimeters), 25.4, accuracy: 0.00001)
        XCTAssertEqual(MeasurementUnit.centimeters.convert(10, to: .millimeters), 100, accuracy: 0.00001)
        XCTAssertEqual(MeasurementUnit.millimeters.convert(25.4, to: .inches), 1, accuracy: 0.00001)
    }

    func testRoundTrip() {
        for from in MeasurementUnit.allCases {
            for to in MeasurementUnit.allCases {
                let original = 123.45
                XCTAssertEqual(to.convert(from.convert(original, to: to), to: from), original, accuracy: 0.00001)
            }
        }
    }
}
