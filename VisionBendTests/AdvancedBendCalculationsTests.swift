import XCTest
@testable import VisionBend

final class AdvancedBendCalculationsTests: XCTestCase {
    func testCompoundGeometry() throws {
        XCTAssertEqual(try AdvancedBendCalculations.compoundNinetyTravel(firstLeg: 3, secondLeg: 4), 5, accuracy: 0.00001)
        XCTAssertEqual(try AdvancedBendCalculations.compoundNinetyRotation(firstLeg: 1, secondLeg: 1), 45, accuracy: 0.00001)
        XCTAssertEqual(try AdvancedBendCalculations.compoundNinetyDevelopedArc(centerlineRadius: 10), 5 * Double.pi, accuracy: 0.00001)
    }
    func testFractionalInches() {
        XCTAssertEqual(AdvancedBendCalculations.fractionalInches(1.5), "1 1/2 in")
        XCTAssertEqual(AdvancedBendCalculations.fractionalInches(0.125), "1/8 in")
        XCTAssertEqual(AdvancedBendCalculations.parseInches("1 1/2"), 1.5)
        XCTAssertEqual(AdvancedBendCalculations.parseInches("3/8"), 0.375)
        XCTAssertNil(AdvancedBendCalculations.parseInches("1/0"))
        XCTAssertEqual(AdvancedBendCalculations.parseInches("-1 1/2"), -1.5)
        XCTAssertEqual(AdvancedBendCalculations.parseInches("-1-1/2"), -1.5)
        XCTAssertEqual(AdvancedBendCalculations.parseInches("+3/8"), 0.375)
        XCTAssertEqual(AdvancedBendCalculations.parseInches("1,25"), 1.25)
        XCTAssertNil(AdvancedBendCalculations.parseInches("1/-2"))
        XCTAssertNil(AdvancedBendCalculations.parseInches("1/0"))
        XCTAssertNil(AdvancedBendCalculations.parseInches("not a length"))
    }
    func testInvalidCompound() {
        XCTAssertThrowsError(try AdvancedBendCalculations.compoundNinetyTravel(firstLeg: -1, secondLeg: 2))
    }
}
