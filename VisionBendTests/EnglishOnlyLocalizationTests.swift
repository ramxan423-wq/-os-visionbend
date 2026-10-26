import XCTest
@testable import VisionBend

final class EnglishOnlyLocalizationTests: XCTestCase {
    func testUnsupportedPhoneLanguageFallsBackToEnglish() {
        XCTAssertEqual(VisionBendLocalization.resolvedLanguage(preferredLanguages: ["tr-TR"]), "en")
        XCTAssertEqual(VisionBendLocalization.resolvedLanguage(preferredLanguages: ["fr-FR", "de-DE"]), "en")
    }

    func testEnglishPhoneVariantsUseEnglish() {
        XCTAssertEqual(VisionBendLocalization.resolvedLanguage(preferredLanguages: ["en-GB"]), "en")
        XCTAssertEqual(VisionBendLocalization.resolvedLanguage(preferredLanguages: ["en-US"]), "en")
    }

    func testOldSavedLanguageCannotDisplayPartialTranslation() {
        XCTAssertEqual(
            VisionBendLocalization.text("Calculate", turkish: "Hesapla", language: "tr"),
            "Calculate"
        )
        XCTAssertEqual(VisionBendLocalization.text("Settings", language: "system"), "Settings")
    }
}
