import XCTest

/// Automated captures of the genuine SwiftUI screens in an iPhone simulator.
/// Snapshots are attached to the XCTest result bundle, not recreated artwork.
final class VisionBendScreenshotsUITests: XCTestCase {
    func testCaptureScreens() {
        let app = XCUIApplication()
        app.launchArguments = [
            "-visionbend.languageChosen", "YES",
            "-visionbend.language", "en",
            "-visionbend.appearance", "1",
            "-visionbend.units", "0"
        ]
        app.launch()
        XCTAssertTrue(app.tabBars.buttons["Home"].waitForExistence(timeout: 20))
        func save(_ name: String) {
            let attachment = XCTAttachment(screenshot: app.screenshot())
            attachment.name = name
            attachment.lifetime = .keepAlways
            add(attachment)
        }

        save("01-home")
        let offset = app.staticTexts["Offset"].firstMatch
        if offset.waitForExistence(timeout: 10) {
            offset.tap()
            save("02-calculator")
        }

        app.terminate()
        app.launch()
        let tabs = app.tabBars
        for (name, label) in [
            ("Camera", "03-camera"),
            ("Plan", "04-planning"),
            ("Projects", "07-projects"),
            ("Settings", "08-settings")
        ] {
            let tab = tabs.buttons[name]
            XCTAssertTrue(tab.waitForExistence(timeout: 15), "Missing tab: \\(name)")
            tab.tap()
            save(label)
            if name == "Plan" {
                let planner = app.staticTexts["Multi-bend & 2D planner"].firstMatch
                if planner.waitForExistence(timeout: 8) {
                    planner.tap()
                    save("05-multi-bend-planner")
                    let advanced = app.switches["Advanced bender options"].firstMatch
                    if advanced.waitForExistence(timeout: 8) {
                        advanced.tap()
                        save("06-advanced-settings")
                    }
                    // Dismiss the sheet before continuing to other tabs.
                    let done = app.buttons["Done"].firstMatch
                    if done.exists { done.tap() }
                    else {
                        app.terminate()
                        app.launch()
                    }
                }
            }
        }
    }
}
