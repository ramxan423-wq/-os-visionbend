# VisionBend iOS – feature verification report

Date: 2026-10-26. Repository: `ramxan423-wq/-os-visionbend`.

## Scope and evidence levels

- **Executed**: a test actually ran on a GitHub Actions Linux Swift runner.
- **Source inspected**: the implementation and navigation path were read, but no iPhone execution has been observed.
- **Unverified**: only a compatible iOS simulator, camera/AR device, signed archive, or real bender can establish the result.
- **Not implemented**: the current iOS source does not provide the advertised operation.

## Executed calculation checks

The Foundation-only Swift package compiled and all **49 XCTest cases** executed successfully in [GitHub Actions run 40360643455](https://github.com/ramxan423-wq/-os-visionbend/actions/runs/40360643455) at commit `92c5f099eca33b7385aa16076ba6a1dccd1b9e88`. The same run successfully parsed **all iOS Swift source files** for syntax errors. These are genuine compiler checks, **not an iOS app build**. They include:

1. The eight Home calculations: offset (mark spacing and theoretical shrink), three-point saddle, kick, arc length, rolling offset, 90° stub, four-point saddle spacing, and compound-90 **planar geometry**.
2. Unit conversions and fractional-inch input, decimal-comma cut lists, and invalid or overflowing numeric inputs.
3. Bender take-up calibration, manufacturer catalog identity/table integrity, theoretical field geometry, camera diameter formula (not camera recognition), level-math helpers, and the English-only localization fallback.

Example calculated values: 10 mm rise / 30° offset → 20 mm theoretical mark spacing and 2.6795 mm theoretical shrink; 100 mm stub with verified 15 mm take-up → 85 mm mark. These values do not certify field-marking accuracy.

## Feature-by-feature status

| Area | Evidence | Status / remaining risk |
| --- | --- | --- |
| Home: eight calculators | Executed Swift XCTest | Core geometry checks passed; visual user-entry flow requires iPhone or iOS Simulator |
| Invalid inputs | Executed Swift XCTest | Rejects invalid angles, nonpositive values, overflow and infinite geometry |
| Units: mm/cm/in | Executed Swift XCTest | Conversion and fractional inches checked; live Settings workflow unverified |
| Five main tabs | Source inspected | Navigation wired; XCUITest authored but not executed on final commit |
| English-only interface | Executed Swift XCTest for text resolver | Legacy language settings fall back to English; all iOS screen labels need visual review |
| Greenlee/Klein bender references | Source inspected | Entries and manufacturer source links exist; not every value independently checked against current official manuals or a physical test bend |
| Manual bender profiles | Source inspected | Save/delete in local AppStorage with explicit unit/reference metadata; saved-profile selector wired to planner; iPhone persistence and unit-switch tests pending |
| Model-calibrated stub | Executed Swift calculation + inspected planner | Mathematics tested; user must supply exact model/size/reference/take-up |
| Multibend planner | Source inspected | Ten preset selections and custom mark creation wired; 90° stub now uses documented calibration, back-to-back requires a second post-bend STAR procedure, Kick uses a user-entered starting station, segmented arc uses radius/segment count, compound 90 uses radius/tangent inputs; manufacturer-specific physical marks still require field tests |
| 2D marking drawing | Source inspected | Schematic only, no dimensioned production CAD drawing |
| 3D preview | Source inspected | SceneKit theoretical radius path now uses finer midpoint arc stepping; accuracy and visuals not confirmed on iPhone |
| Cut optimizer | Executed unit tests for input + inspected algorithm | First-fit decreasing straight stock; no bent developed-length optimization or UI execution |
| Saved bend projects | Source inspected | UserDefaults add/edit/delete wired; reopen-and-restore test pending |
| JSON/CSV export | Source inspected | FileDocument exporters wired, errors visible; actual exported files not opened and inspected on iPhone |
| PDF mark sheets | Source inspected | UIGraphicsPDFRenderer + 20-item pagination wired; rendered PDF inspection pending |
| Camera level | Source inspected | Permission request, live camera preview, motion readings, zero/reset wired; physical phone tilt and camera test pending |
| Photo conduit scan | Source inspected | Camera capture, photo-library input, and manual two-point conduit + two-point same-plane reference calibration wired; automatic contour estimate still **not verified diameter detection** |
| LiDAR depth scan | Source inspected | Horizontal/vertical image-to-focal-axis mismatch fixed, five-frame provisional reading and unsupported-device guard wired; LiDAR device + calipers test pending |
| AR point-to-point distance | Source inspected | Manual two-tap surface tracking; no tape-measure accuracy comparison |
| AR conduit marks | Source inspected | Manual start/end selection, proportional virtual markers, reset fix; not automatic pipe recognition or real bender mark validation |
| Direct paid download | Source inspected | Subscription/paywall code removed; **US $9.99 storefront price must be set/verified in App Store Connect** |
| Signed App Store archive | Unverified | Current signed IPA/archive and upload not demonstrated |

## Advertised operations absent from the current iOS source

- The older promotional material mentions **33 calculation modules**; current Home shows **eight** and planning offers ten presets, some overlapping and theoretical. Do not claim 33 verified iOS tools.
- **CAD Drawing Workshop**, production CAD editing, and **DXF/SVG export** are not present. PDF/CSV/JSON export is not the same as CAD/DXF/SVG.
- **Project backup/restore across devices** is not implemented; local saved calculations are not cloud sync.
- Several math helpers (parallel kick, kicked 90, setback/gain) exist but are not each exposed as an independently verified, full physical-marking screen. Back-to-back and segmented arc now have explicit guided planning, but do not claim manufacturer-specific automatic shoe marks without a manual.

## Device and release blockers

1. `project.yml` specifies **iOS 16.0** minimum, so **iPhone 6s/iPhone 7 cannot install this build**. Apple lists iOS 16 compatibility beginning at iPhone 8 / iPhone X era.
2. The most recent macOS Xcode build/test workflow was queued; a prior attempt was cancelled without running its build steps. Passing Linux calculation tests does **not** verify SwiftUI, SceneKit, Vision, AVFoundation, ARKit, signing or iOS launch.
3. App Store price, payment and distribution have not been read from the actual storefront/Connect configuration.
4. Manufacturer bend reference marks, true conduit diameter, springback, radius, camera depth and AR coordinates need at least one calibrated physical sample per claimed device/profile.

## Required physical acceptance test

On an iPhone with iOS 16+:

1. Install and launch the exact commit’s signed TestFlight build; open each Home, Camera, Plan, Projects, Settings tab; inspect all visible copy in English.
2. Enter known dimensions in all eight main calculators, compare with an independently computed sheet and a manufacturer table where applicable. Repeat with cm and fractional inches.
3. Generate a custom and a manufacturer-specific plan, intentionally create an out-of-bounds mark, test 2D/3D visuals, verify PDF pagination/share and CSV/JSON contents.
4. Save a calculation and manual bender profile; force-quit and relaunch; edit, export and delete them.
5. Deny/allow camera, take a new photo, choose a library image, calibrate against a known ruler, and compare estimated diameter to calipers. Test the no-contour image case.
6. With an ARKit-capable phone, measure a known tape-marked distance, reset markers and observe cleanup; compare all virtual marks to the tape. On a LiDAR model, test depth scan; on a non-LiDAR model, check the fallback.
7. Bend a scrap sample with an **exact** bender, conduit type, size and manual revision; record reference alignment, take-up, springback and resulting dimensions before certifying a physical mark as correct.
8. Verify paid App Store pricing is a one-time download at the intended US storefront amount and no in-app subscription/paywall appears.

**Release decision:** Core calculator math has automated evidence; full iPhone behavior, manufacturer-calibrated physical marks, CAD feature parity, and App Store distribution are **not verified**. Do not label VisionBend fully tested or ready for public release yet.
