# VisionBend iOS

Native SwiftUI iOS application under development. **Not yet a complete Android port or verified TestFlight build.**

## Implemented in source
- Two-point offset mark spacing and theoretical shrink
- Three-point saddle mark spacing
- Kick horizontal travel
- Bend centerline arc length
- Rolling offset resultant
- Camera preview with camera permission handling
- Motion-sensor pitch/roll level (reference only)
- Persistent last-used calculation mode and input values

## Build and test
Requires macOS/Xcode 16 or compatible, plus XcodeGen:

```sh
brew install xcodegen
xcodegen generate
xcodebuild -project VisionBend.xcodeproj -scheme VisionBend -sdk iphonesimulator -destination 'generic/platform=iOS Simulator' CODE_SIGNING_ALLOWED=NO build
```

A GitHub Actions workflow attempts a simulator build and unit tests on macOS. **Its success has not been confirmed.** A signed IPA requires Apple Developer signing credentials and Xcode archive/export configuration.

## Remaining work
- Audit the original Android source ZIP and port remaining calculator modes and screens
- Camera measurement / object detection and true AR implementation (the current camera level is *not* AR)
- Calibration, localization, project storage, settings, subscription integration
- Simulator and real-device tests, signing, TestFlight submission

Safety: mathematical outputs are theoretical and may require adjustments for conduit type and the exact bender. Always verify against the tool and physical measurements.
