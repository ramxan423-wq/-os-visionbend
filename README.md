# VisionBend iOS

Native SwiftUI electrical-conduit bending and measurement app. The source includes eight basic bend calculators, advanced multi-bend planning, cut optimization, manufacturer references, project history, PDF export, camera-level, calibrated photo scan, optional AR/LiDAR tools.

## Current verification
- GitHub Actions builds the unsigned iOS Simulator target and runs XCTest on macOS. See [iOS build verification](https://github.com/ramxan423-wq/-os-visionbend/actions).
- A successful simulator build **does not** prove that camera, ARKit, LiDAR, purchasing, or notifications work on real devices.
- The signed App Store archive workflow requires an Apple distribution certificate and matching provisioning profile. Codemagic has a separate App Store signed IPA workflow.
- The build workflows generate the App Store icon asset catalog before XcodeGen.
- **Monetization:** one-time paid App Store download with unlimited access to all features. There is no in-app subscription, restore-purchase flow or Premium gate. The actual download price must be configured in App Store Connect.
- **Language:** English is currently the only fully supported interface language. The app detects the device's preferred language and uses the English fallback on non-English devices; the unfinished language picker is removed.

## Core calculations and planner
- Two-point offset spacing and shrink, three-point saddle, kick, arc length, rolling offset, 90-degree stub and four-point saddle.
- Multi-bend geometry, measured placement, optional model-specific calibration, printable multi-page marking sheet, schematic 2D and provisional 3D preview.
- Unit-aware field input and display for mm/cm/in, including comma-decimal and fractional-inch entry in selected tools.
- These calculations remain theoretical. Always use the exact bender model, real conduit dimensions, manufacturer's references and a field test bend.

## Project build
On macOS with a compatible Xcode installation:

```sh
brew install xcodegen
python3 tools/generate_app_icon.py
xcodegen generate
xcodebuild -project VisionBend.xcodeproj -scheme VisionBend \
  -sdk iphonesimulator -destination 'generic/platform=iOS Simulator' \
  CODE_SIGNING_ALLOWED=NO build
```

To create a signed IPA, configure the exact iOS bundle identifier and signing integration before running the `visionbend-ios-ipa` workflow in Codemagic. Configure the one-time app purchase price in App Store Connect, not in the app.

## Known limitations and remaining validation
- Real iPhone camera access, motion-sensor level, Vision conduit identification, AR tracking and LiDAR depth require compatible real-device tests; camera features are experimental measurements, not calibrated metrology.
- No monthly/yearly in-app subscriptions are offered. Confirm the paid-app price and App Store metadata before release.
- Navigation clarity and unit safety have been improved, but complete English UI, accessibility and real-device review are not yet verified.
- The Android app's feature parity and the signed, App Store-ready IPA have not been independently confirmed.
