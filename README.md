# VisionBend iOS prototype

This is a **partial native SwiftUI port**, not yet a full-featured iOS version.

## How to run
1. On macOS, open Xcode and create a SwiftUI iOS App named VisionBend.
2. Add `VisionBendApp.swift`, `ContentView.swift`, and `BendCalculations.swift` to the target. Replace Xcode-generated app entry and ContentView.
3. Select a unique iOS bundle identifier and your Apple signing team.
4. Build on an iPhone or simulator. Verify the calculations against your actual bender.

## Included
- Two-point offset mark spacing and theoretical shrink.
- Symmetric three-point saddle outer mark distance.
- Dark and orange calculator interface.

## Still required
- Port all other Android calculations, camera, level, AR, project storage, and settings.
- Build/test using Xcode on macOS, sign the iOS archive, then submit via App Store Connect.

The Android code currently lives in the ZIP at the repository root. This initial prototype has not been compiled or tested on an iPhone.
