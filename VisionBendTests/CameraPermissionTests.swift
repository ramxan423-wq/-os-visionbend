import XCTest
import AVFoundation
@testable import VisionBend

final class CameraPermissionTests: XCTestCase {
    func testCameraUsageDescriptionIsPresent() {
        let description = Bundle.main.object(forInfoDictionaryKey: "NSCameraUsageDescription") as? String
        XCTAssertNotNil(description)
        XCTAssertFalse(description?.isEmpty ?? true)
    }

    func testCameraAuthorizationStatusCanBeQueried() {
        let status = AVCaptureDevice.authorizationStatus(for: .video)
        XCTAssertTrue([.notDetermined, .restricted, .denied, .authorized].contains(status))
    }
}
