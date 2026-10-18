import XCTest
@testable import VisionBend

final class LevelMathTests: XCTestCase {
    func testRadianConversion() {
        XCTAssertEqual(LevelMath.degrees(radians: .pi / 2), 90, accuracy: 0.00001)
        XCTAssertEqual(LevelMath.degrees(radians: -.pi / 4), -45, accuracy: 0.00001)
    }

    func testLevelTolerance() {
        XCTAssertTrue(LevelMath.isLevel(pitchRadians: 0, rollRadians: 0))
        XCTAssertTrue(LevelMath.isLevel(pitchRadians: .pi / 360, rollRadians: 0))
        XCTAssertFalse(LevelMath.isLevel(pitchRadians: .pi / 36, rollRadians: 0))
        XCTAssertFalse(LevelMath.isLevel(pitchRadians: 0, rollRadians: -.pi / 36))
        XCTAssertFalse(LevelMath.isLevel(pitchRadians: .nan, rollRadians: 0))
        XCTAssertFalse(LevelMath.isLevel(pitchRadians: 0, rollRadians: 0, toleranceDegrees: -1))
    }
}
