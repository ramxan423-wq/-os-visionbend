import XCTest

final class VisionBendNavigationUITests: XCTestCase {
    func testCoreOffsetCanBeCalculatedFromHome() {
        let app = XCUIApplication()
        app.launchArguments = ["-visionbend.units", "0", "-visionbend.language", "en"]
        app.launch()

        let offset = app.buttons["Offset"]
        XCTAssertTrue(offset.waitForExistence(timeout: 20), "Offset calculator is missing from Home")
        offset.tap()

        let rise = app.textFields["Rise / height"]
        let angle = app.textFields["Bend angle (degrees)"]
        XCTAssertTrue(rise.waitForExistence(timeout: 10))
        XCTAssertTrue(angle.exists)
        rise.tap()
        rise.typeText("10")
        angle.tap()
        angle.typeText("30")

        app.buttons["Calculate"].tap()
        let spacing = app.staticTexts.matching(NSPredicate(format: "label CONTAINS %@", "Mark spacing: 20.00 mm")).firstMatch
        XCTAssertTrue(spacing.waitForExistence(timeout: 10), "Correct offset spacing was not displayed")
    }

    func testPrimaryTabsCanBeOpened() {
        let app = XCUIApplication()
        // Force a non-English phone locale to verify the English-only fallback.
        app.launchArguments = [
            "-AppleLanguages", "(tr)",
            "-AppleLocale", "tr_TR",
            "-visionbend.language", "tr"
        ]
        app.launch()

        let tabs = app.tabBars
        let tabNames = ["Home", "Camera", "Plan", "Projects", "Settings"]
        for name in tabNames {
            let tab = tabs.buttons[name]
            XCTAssertTrue(tab.waitForExistence(timeout: 20), "Missing main tab: \(name)")
            tab.tap()
            XCTAssertTrue(app.state == .runningForeground, "App unexpectedly closed after opening \(name)")
        }
        XCTAssertFalse(app.buttons["Premium"].exists, "A paid-download app must not show a subscription paywall")
        tabs.buttons["Settings"].tap()
        XCTAssertTrue(app.staticTexts["English"].waitForExistence(timeout: 10))
    }
}
