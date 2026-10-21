# VisionBend iOS release test matrix

This matrix distinguishes **verified automated checks** from **physical-device checks not yet run**. Do not call the app fully tested until the pending rows have been executed on a supported iPhone.

| Area | Scenarios | Execution |
| --- | --- | --- |
| iOS source build | XcodeGen generation; iOS Simulator compile | GitHub Actions CI |
| Watch app build | watchOS Simulator target compiles | GitHub Actions CI |
| Calculation logic | All XCTest suites, including geometry, unit conversion, fraction input | GitHub Actions CI |
| Tab navigation | Home, Camera, Plan, Projects and Settings open without quitting | New XCUITest simulator smoke |
| Eight bend types | Offset, 3-point saddle, kick, arc, rolling offset, 90° stub, 4-point saddle, compound 90°; verify positive values and rejection of invalid inputs | Existing unit coverage, manual UI pending |
| Unit conversion | mm/cm/in switching preserves physical dimensions; fractions and decimal commas; marks and stock list conversion | XCTest and simulator build; user-entered workflow pending |
| Multi-bend planner | Generates valid bend marks, rejects overlaps/out-of-stock marks, stores edit changes | Geometry tests; hands-on workflow pending |
| Advanced catalog | Exact model, conduit and size; no unsupported manufacturer guess; source references | Manual inspection pending |
| PDF | Short and 20+ marking lists, pagination, sharing, saved filenames | Source correction; PDF viewer inspection pending |
| Saved projects | Add, update notes, export, delete, restore after app relaunch | Manual persistence tests pending |
| Camera level | Allow and deny permission; preview; motion; set zero/reset; real device orientation | Real-device test required |
| Photo conduit estimation | Library access, sample reference, no reference, no detected contour | Real images/device test required |
| AR measurement | Supported and unsupported device; set two points and reset | ARKit device test required |
| LiDAR depth | Unsupported-device fallback; depth quality and measurement reliability | LiDAR-capable device required |
| Watch messaging | Paired watch app, marking transfer, reconnection | Paired physical devices required |
| Localization | Full app strings, layout, long/RTL languages, number entry | Incomplete; full review needed |
| Premium | App Store Connect subscription IDs, products loading, monthly/yearly, purchase, restore, entitlement | Not configured; blocks paid-release signoff |
| Signing | Compatible P12, matching provisioning profile, export signed IPA | Requires Apple credentials and archive dispatch |
| TestFlight | Upload IPA, install on real device, crash and transaction testing | Pending |

## Ship gate
1. Automated iOS build and all required tests are green **for the exact final commit**.
2. Camera and AR/LiDAR behavior is tested on supported/unsupported iPhone models.
3. Real-device navigation and localization checks are complete.
4. Any advertised Premium plans are configured and verified in StoreKit.
5. Signed App Store archive / IPA and TestFlight installation succeed.
6. Manufacturer-specific dimensions and bending marks are validated against real bender manuals and a physical test bend.

**Safety:** Calculations and visual measurements are theoretical or experimental; never replace a field measurement without a real-tool check.
