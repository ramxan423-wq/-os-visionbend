import XCTest
@testable import VisionBend

final class EnglishLocalizationTests: XCTestCase {
    func testEnglishAppLabelsNeverTurnTurkish() {
        let labels = [
            "Home", "Camera", "Plan", "Projects", "Settings",
            "Choose your language", "Search language", "Continue",
            "Bend Calculators", "Multi-bend & 2D planner",
            "Bender reference", "Advanced bend patterns",
            "QuickCheck", "Calculation result", "Done",
            "Premium", "Units", "Add Mark",
            "Conduit length", "Centerline radius", "Manufacturer"
        ]
        for key in labels {
            XCTAssertEqual(VisionBendLocalization.text(key, turkish: "TÜRKÇE", language: "en"),
                           key, "English app should show English key: \(key)")
        }
    }
    func testRegionalEnglishAndExplicitEnglishSelection() {
        for english in ["en", "en-GB", "en-AU", "en-CA"] {
            XCTAssertEqual(VisionBendLocalization.text("Save", turkish: "Kaydet", language: english),
                           "Save", "Selected language \(english) leaked a Turkish translation")
            XCTAssertEqual(VisionBendLocalization.text("Camera", turkish: "Kamera", language: english),
                           "Camera")
        }
    }
    func testTurkishFallbackDoesNotLeakIntoEnglish() {
        let key = "Invalid dimensions or bend angle. Check your measurements."
        XCTAssertEqual(VisionBendLocalization.text(key, turkish: "Geçersiz ölçü.", language: "en"), key)
        XCTAssertEqual(VisionBendLocalization.text(key, turkish: "Geçersiz ölçü.", language: "tr"),
                       "Geçersiz ölçü.")
    }
    func testEnglishFormatStringPreservesPlaceholders() {
        let key = "Mark spacing: %.2f %@\nTheoretical shrink: %.2f %@"
        let localized = VisionBendLocalization.text(key, language: "en")
        XCTAssertEqual(localized, key)
        let result = String(format: localized, 100.0, "mm", 10.0, "mm")
        XCTAssertEqual(result, "Mark spacing: 100.00 mm\nTheoretical shrink: 10.00 mm")
    }
}
