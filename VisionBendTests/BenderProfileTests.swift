import XCTest
@testable import VisionBend

final class BenderProfileTests: XCTestCase {
    func testProfileRoundTripIncludesUnitsAndReference() throws {
        let profile = BenderProfile(manufacturer: "Klein Tools", model: "51606", conduitType: "EMT", conduitSize: "1/2 in", takeUp: "5", radius: "4.625", notes: "Field checked", source: "Manual page 2", unitCode: 2, referenceMark: "Arrow")
        let data = try JSONEncoder().encode(profile)
        let restored = try JSONDecoder().decode(BenderProfile.self, from: data)
        XCTAssertEqual(restored.unitCode, 2)
        XCTAssertEqual(restored.referenceMark, "Arrow")
        XCTAssertEqual(restored.model, "51606")
    }

    func testLegacyProfileLoadsWithoutAssumingItsUnits() throws {
        let oldJSON = """
        {"id":"A0B874E0-6A12-41A2-83DB-0EB66D41A81D","manufacturer":"Greenlee","model":"840A","conduitType":"EMT","conduitSize":"1/2 in","takeUp":"5","radius":"4","notes":"","source":""}
        """
        let restored = try JSONDecoder().decode(BenderProfile.self, from: Data(oldJSON.utf8))
        XCTAssertNil(restored.unitCode)
        XCTAssertNil(restored.referenceMark)
    }
}
