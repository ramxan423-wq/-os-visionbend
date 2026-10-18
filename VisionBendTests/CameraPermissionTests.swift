import XCTest
import AVFoundation
@testable import VisionBend

final class CameraPermissionTests: XCTestCase {
    func testCameraUsageDescriptionIsPresentInAppTarget() {
        let appBundle = Bundle(for: BendHistory.self)
        let description = appBundle.object(forInfoDictionaryKey: "NSCameraUsageDescription") as? String
        XCTAssertNotNil(description, "The iOS app target must declare NSCameraUsageDescription")
        XCTAssertFalse(description?.isEmpty ?? true)
    }

    func testCameraAuthorizationStatusCanBeQueried() {
        let status = AVCaptureDevice.authorizationStatus(for: .video)
        XCTAssertTrue([.notDetermined, .restricted, .denied, .authorized].contains(status))
    }
}
