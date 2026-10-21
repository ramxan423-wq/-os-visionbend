import XCTest

/// Opens every top-level VisionBend tab in every selectable interface language.
/// This is a stability smoke test; translation completeness is enforced separately
/// by tools/audit_localizations.py and must be reviewed by native speakers.
final class VisionBendAllLanguagesUITests: XCTestCase {
    func testAll20LanguagesCanOpenEveryMainSection() {
        let locales = [
            "en", "tr", "es", "fr", "de", "ar", "pt", "it",
            "ru", "fa", "hi", "zh-Hans", "zh-Hant", "ja",
            "ko", "id", "da", "sv", "nl", "fi"
        ]
        let app = XCUIApplication()
        for code in locales {
            app.launchArguments = [
                "-visionbend.languageChosen", "YES",
                "-visionbend.language", code,
                "-visionbend.appearance", "1"
            ]
            app.launch()
            XCTAssertTrue(app.tabBars.firstMatch.waitForExistence(timeout: 25),
                          "App did not show tabs for \(code)")
            for index in 0..<5 {
                let tab = app.tabBars.buttons.element(boundBy: index)
                XCTAssertTrue(tab.exists, "Missing tab \(index) in \(code)")
                tab.tap()
                XCTAssertEqual(app.state, .runningForeground,
                               "App closed opening tab \(index) in \(code)")
            }
            let attachment = XCTAttachment(screenshot: app.screenshot())
            attachment.name = "VisionBend-\(code)-settings"
            attachment.lifetime = .keepAlways
            add(attachment)
            app.terminate()
        }
    }
}
