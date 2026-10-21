import XCTest

final class VisionBendNavigationUITests: XCTestCase {
    func testPrimaryTabsCanBeOpened() {
        let app = XCUIApplication()
        // Start with English and completed language onboarding for deterministic UI smoke tests.
        app.launchArguments = [
            "-visionbend.languageChosen", "YES",
            "-visionbend.language", "en"
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
    }
}
