# VisionBend iOS

Native SwiftUI electrical-conduit bending and measurement app. The source includes eight basic bend calculators, advanced multi-bend planning, cut optimization, manufacturer references, project history, PDF export, camera-level, calibrated photo scan, optional AR/LiDAR tools and optional Apple Watch integration.

## Current verification
- GitHub Actions builds the unsigned iOS and watchOS Simulator targets and runs XCTest on macOS. See [iOS build verification](https://github.com/ramxan423-wq/-os-visionbend/actions).
- A successful simulator build **does not** prove that camera, ARKit, LiDAR, Watch connectivity, purchasing, or notifications work on real devices.
- The signed App Store archive workflow requires an Apple distribution certificate and matching provisioning profile. Codemagic has a separate App Store signed IPA workflow.
- The build workflows generate the App Store icon asset catalog before XcodeGen.
- The app's StoreKit product identifiers have not yet been populated. **Premium subscriptions are not operational until the actual App Store Connect identifiers and entitlement behavior are configured and tested.**

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

To create a signed IPA, configure the exact iOS bundle identifier, signing integration and App Store Connect product IDs before running the `visionbend-ios-ipa` workflow in Codemagic.

## Known limitations and remaining validation
- Real iPhone camera access, motion-sensor level, Vision conduit identification, AR tracking and LiDAR depth require compatible real-device tests; camera features are experimental measurements, not calibrated metrology.
- StoreKit subscriptions need real product IDs and purchase/restore/entitlement validation.
- Navigation clarity and unit safety have been improved, but complete localization coverage for every selectable language and device-specific accessibility review are not yet verified.
- The Android app's feature parity and the signed, App Store-ready IPA have not been independently confirmed.
