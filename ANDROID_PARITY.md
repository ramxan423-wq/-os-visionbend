# Android–iOS feature parity acceptance checklist

**Goal:** no user-visible Android functionality missing from the iOS release. This is an acceptance specification, NOT a claim of implementation or test success.

## Audit required
- [ ] Extract and inventory the actual Android source from BendVision-Pro, including all screens, navigation, calculators, permissions, assets, persistence, monetization and translations
- [ ] Create a screen-by-screen, input-by-input parity matrix with file references to both codebases
- [ ] Confirm the Android baseline version and distinguish working features from planned features

## Calculators
- [ ] Port every Android bend mode, formula, marking guide and adjustment
- [ ] Match units, conversions, rounding, edge cases and validation
- [ ] Golden-case tests comparing the same inputs and expected results on Android and iOS

## Camera and measurement
- [ ] Camera permission, lifecycle, denial/recovery, no-camera fallback
- [ ] Implement actual pipe detection and calibrated diameter measurement where Android has working equivalents
- [ ] Verify accuracy on supported iPhones; show limitations, never imply camera measurements are exact

## AR and level
- [ ] ARKit equivalent for every implemented Android AR workflow, with device compatibility fallback
- [ ] Calibrated level, reset/zero and orientation handling
- [ ] Real device testing across permissions and sensor availability

## UI and storage
- [ ] Reproduce all Android menus, screens, onboarding, orange/black and light/dark themes
- [ ] Full project create/edit/save/delete/history and migration tests
- [ ] Localize every visible string for every supported Android locale
- [ ] Preserve all existing iOS functionality during port

## Release
- [ ] Successful Xcode simulator build and unit tests
- [ ] Real iPhone smoke test: calculations, camera, sensors, AR, persistence, appearance and accessibility
- [ ] Active Apple Developer account, bundle ID, provisioning and distribution signing
- [ ] Signed IPA export, App Store Connect upload and TestFlight processing
- [ ] Internal tester acceptance, crash-free launch and no critical parity gaps

**Current status:** incomplete. iOS source contains a subset of calculators, a camera preview, a basic level, local history and settings. Neither full Android parity nor successful TestFlight upload has been verified.
