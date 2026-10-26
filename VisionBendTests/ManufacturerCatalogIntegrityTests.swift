import XCTest
@testable import VisionBend

/// Internal consistency checks, not a substitute for checking printed manuals.
final class ManufacturerCatalogIntegrityTests: XCTestCase {
    func testEveryBenderHasUniqueIdentityAndDocumentedValues() {
        let entries = VerifiedBenderCatalog.entries
        XCTAssertFalse(entries.isEmpty)
        XCTAssertEqual(Set(entries.map(\.id)).count, entries.count)
        for model in entries {
            XCTAssertFalse(model.brand.isEmpty, model.id)
            XCTAssertFalse(model.model.isEmpty, model.id)
            XCTAssertFalse(model.conduit.isEmpty, model.id)
            XCTAssertFalse(model.tradeSize.isEmpty, model.id)
            XCTAssertTrue(model.sourceURL.hasPrefix("https://"), model.id)
            if let deduct = model.deductInches {
                XCTAssertTrue(deduct.isFinite && deduct >= 0, model.id)
            }
            if let radius = model.radiusInches {
                XCTAssertTrue(radius.isFinite && radius > 0, model.id)
            }
        }
    }

    func testManufacturerSaddleCellsAreUniqueAndReferenceKnownModels() {
        let modelIDs = Set(VerifiedBenderCatalog.entries.map(\.id))
        let rows = GreenleeSaddleTable.rows
        XCTAssertFalse(rows.isEmpty)
        let identities = rows.map { "\($0.modelID)|\($0.angle)|\($0.heightInches)" }
        XCTAssertEqual(Set(identities).count, identities.count)
        for row in rows {
            XCTAssertTrue(modelIDs.contains(row.modelID), row.modelID)
            XCTAssertTrue(row.angle > 0 && row.angle <= 90)
            XCTAssertTrue(row.heightInches > 0)
            XCTAssertTrue(row.z.isFinite && row.z >= 0)
            XCTAssertTrue(row.l1.isFinite && row.l1 > 0)
            XCTAssertTrue(row.l2.isFinite && row.l2 > 0)
            XCTAssertNotNil(GreenleeSaddleTable.exact(modelID: row.modelID, angle: row.angle, heightInches: row.heightInches))
        }
    }

    func testUnknownManufacturerTablesDoNotGuess() {
        XCTAssertNil(GreenleeSaddleTable.exact(modelID: "unknown", angle: 30, heightInches: 4))
        XCTAssertNil(VerifiedBenderCatalog.stubMarkInches(modelID: "unknown", desiredStubInches: 30))
    }
}
