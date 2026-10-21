import XCTest

/// End-to-end iPhone simulator checks for English on every top-level screen.
final class VisionBendEnglishUITests: XCTestCase {
    func testEnglishTabsToolsAndErrors() {
        let app = XCUIApplication()
        app.launchArguments = [
            "-visionbend.languageChosen", "YES",
            "-visionbend.language", "en",
            "-visionbend.appearance", "1",
            "-visionbend.units", "0"
        ]
        app.launch()
        let tabs = app.tabBars
        for name in ["Home", "Camera", "Plan", "Projects", "Settings"] {
            let button = tabs.buttons[name]
            XCTAssertTrue(button.waitForExistence(timeout: 20), "Missing English tab: \(name)")
            button.tap()
            XCTAssertEqual(app.state, .runningForeground)
        }
        XCTAssertTrue(app.staticTexts["App language"].waitForExistence(timeout: 8))
        XCTAssertFalse(app.staticTexts["Ayarlar"].exists)
        XCTAssertFalse(app.staticTexts["Projeler"].exists)
        let planTab = tabs.buttons["Plan"]
        planTab.tap()
        let advancedTool = app.buttons["Advanced bend patterns"]
        XCTAssertTrue(advancedTool.waitForExistence(timeout: 15))
        advancedTool.tap()
        XCTAssertTrue(app.buttons["Calculate pattern"].waitForExistence(timeout: 15))
        XCTAssertTrue(app.staticTexts["Bend family"].exists)
        XCTAssertTrue(app.buttons["Done"].exists)
    }

    func testCalculatorInvalidInputShowsEnglishError() {
        let app = XCUIApplication()
        app.launchArguments = [
            "-visionbend.languageChosen", "YES",
            "-visionbend.language", "en",
            "-visionbend.mode", "0",
            "-visionbend.lastHeight", "20",
            "-visionbend.lastAngle", "0"
        ]
        app.launch()
        XCTAssertTrue(app.tabBars.buttons["Home"].waitForExistence(timeout: 20))
        let link = app.staticTexts["Offset"].firstMatch
        XCTAssertTrue(link.waitForExistence(timeout: 12))
        link.tap()
        let calculate = app.buttons["Calculate"]
        XCTAssertTrue(calculate.waitForExistence(timeout: 15))
        calculate.tap()
        XCTAssertTrue(app.staticTexts["Invalid dimensions or bend angle. Check your measurements."]
            .waitForExistence(timeout: 10))
        XCTAssertFalse(app.staticTexts["Pozitif ölçüler ve 0–90° arasında bir açı girin."].exists)
    }
}
