import XCTest

final class VisionBendAdvancedPatternsUITests: XCTestCase {
    func testAdvancedPatternsOpenAndCalculate() {
        let app = XCUIApplication()
        app.launchArguments = [
            "-visionbend.languageChosen", "YES",
            "-visionbend.language", "en",
            "-visionbend.units", "0"
        ]
        app.launch()
        let planTab = app.tabBars.buttons["Plan"]
        XCTAssertTrue(planTab.waitForExistence(timeout: 20))
        planTab.tap()
        let tool = app.buttons["Advanced bend patterns"]
        XCTAssertTrue(tool.waitForExistence(timeout: 12))
        tool.tap()
        let compute = app.buttons["Calculate pattern"]
        XCTAssertTrue(compute.waitForExistence(timeout: 15))
        compute.tap()
        XCTAssertTrue(app.staticTexts["Calculation result"].waitForExistence(timeout: 15))
        XCTAssertTrue(app.buttons["Done"].exists)
    }
}
