import XCTest

/// Genuine VisionBend UI capture on the latest feature branch; no mockups.
final class VisionBendLatestScreenshotsUITests: XCTestCase {
    func testCaptureLatestScreens() {
        let app = XCUIApplication()
        app.launchArguments = [
            "-visionbend.languageChosen", "YES",
            "-visionbend.language", "en",
            "-visionbend.appearance", "1",
            "-visionbend.units", "0"
        ]
        app.launch()
        let tabs = app.tabBars
        XCTAssertTrue(tabs.buttons["Home"].waitForExistence(timeout: 25))
        func capture(_ name: String) {
            let screenshot = XCTAttachment(screenshot: app.screenshot())
            screenshot.name = name
            screenshot.lifetime = .keepAlways
            add(screenshot)
        }
        capture("01-latest-home")

        if app.staticTexts["Offset"].firstMatch.exists {
            app.staticTexts["Offset"].firstMatch.tap()
            capture("02-latest-calculator")
            app.terminate()
            app.launch()
        }
        let sections = [
            ("Camera", "03-latest-camera"),
            ("Plan", "04-latest-planning"),
            ("Projects", "07-latest-projects"),
            ("Settings", "08-latest-settings")
        ]
        for (name, file) in sections {
            let tab = app.tabBars.buttons[name]
            XCTAssertTrue(tab.waitForExistence(timeout: 20), "Missing English tab: \(name)")
            tab.tap()
            capture(file)
            if name == "Plan" {
                let tool = app.buttons["Advanced bend patterns"]
                if tool.waitForExistence(timeout: 6) {
                    tool.tap()
                    capture("05-latest-advanced-bend-patterns")
                    let calculate = app.buttons["Calculate pattern"]
                    if calculate.waitForExistence(timeout: 5) {
                        calculate.tap()
                        capture("06-latest-pattern-result")
                    }
                    app.terminate()
                    app.launch()
                }
            }
        }
    }
}