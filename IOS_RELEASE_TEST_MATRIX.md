# VisionBend iOS release test matrix

This matrix distinguishes **verified automated checks** from **physical-device checks not yet run**. Do not call the app fully tested until the pending rows have been executed on a supported iPhone.

| Area | Scenarios | Execution |
| --- | --- | --- |
| iOS source build | XcodeGen generation; iOS Simulator compile | GitHub Actions CI |
| Calculation logic | All XCTest suites, including geometry, unit conversion, fraction input | GitHub Actions CI |
| Tab navigation | Home, Camera, Plan, Projects and Settings open without quitting | New XCUITest simulator smoke |
| Eight bend types | Offset, 3-point saddle, kick, arc, rolling offset, 90° stub, 4-point saddle, compound 90°; verify positive values and rejection of invalid inputs | CorePurposeSmokeTests added; 10 independent numeric checks passed; Swift XCTest and manual UI pending |
| Unit conversion | mm/cm/in switching preserves physical dimensions; fractions and decimal commas; marks and stock list conversion | XCTest and simulator build; user-entered workflow pending |
| Multi-bend planner | Generates valid bend marks, rejects overlaps/out-of-stock marks, stores edit changes | Geometry tests; hands-on workflow pending |
| Advanced catalog | Exact model, conduit and size; no unsupported manufacturer guess; source references | Manual inspection pending |
| PDF | Short and 20+ marking lists, pagination, sharing, saved filenames | Source correction; PDF viewer inspection pending |
| Saved projects | Add, update notes, export, delete, restore after app relaunch | Manual persistence tests pending |
| Camera level | Allow and deny permission; preview; motion; set zero/reset; real device orientation | Real-device test required |
| Photo conduit estimation | Take a live photo or select from library; sample reference, no reference, no detected contour | Both photo sources wired; real images/device test required |
| AR measurement | Supported and unsupported device; set two points and reset; stale marks removed after reset | AR reset cleanup fixed in source; ARKit device test required |
| LiDAR depth | Unsupported-device fallback; depth quality and measurement reliability | LiDAR-capable device required |
| Localization | English-only UI on English and non-English iPhones; number entry | English fallback implemented; device review pending |
| Paid distribution | App Store Connect up-front app price; no subscription or paywall screen | Source removes StoreKit paywall; storefront price must be verified |
| Signing | Compatible P12, matching provisioning profile, export signed IPA | Requires Apple credentials and archive dispatch |
| TestFlight | Upload IPA, install on real device, crash and transaction testing | Pending |

## Ship gate
1. Automated iOS build and all required tests are green **for the exact final commit**.
2. Camera and AR/LiDAR behavior is tested on supported/unsupported iPhone models.
3. Real-device navigation and English-only localization checks are complete.
4. Paid download price and App Store listing are configured correctly; no in-app subscription products advertised.
5. Signed App Store archive / IPA and TestFlight installation succeed.
6. Manufacturer-specific dimensions and bending marks are validated against real bender manuals and a physical test bend.

**Safety:** Calculations and visual measurements are theoretical or experimental; never replace a field measurement without a real-tool check.

## Source-audit fixes after the English-only release changes

- Invalid-calculation messages now use English; invalid or overflowing geometry values are rejected instead of displaying infinity.
- All eight main calculator types have a single numerical regression smoke test and invalid-input checks.
- Photo inspection now supports both camera capture (where available) and the photo library; failed scans clear the previous pixel estimate.
- AR bend markers are removed when the user resets endpoints, even without another camera tap.
- Camera diameter estimates reject non-finite values.
- The camera level keeps one motion sensor manager across SwiftUI view refreshes instead of creating a fresh manager on redraw.

These are code-level fixes; they are **not proof of iPhone runtime success**. The macOS CI job and a supported physical iPhone remain mandatory release checks.
