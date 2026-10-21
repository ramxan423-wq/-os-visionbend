# VisionBend iOS — five-part field verification plan

This app must not be described as field-calibrated until representative **real conduit and real benders** have been tested. The automated test suite validates theoretical formulas, bounds and iOS UI stability, not physical springback, shoe-reference positions or LiDAR measurement accuracy.

## 1. New bend patterns
- [ ] On actual stock, test matching-offset (bend and center alignment) at 15°, 22.5°, 30°, 45°.
- [ ] Verify parallel-offset spacing for adjacent 1/2", 3/4" and 1" EMT runs.
- [ ] Verify matching and parallel kick direction, forward variants and real 90° take-up.
- [ ] Compare rectangular, square and circular-obstacle envelopes against tape-measured clearances.
- [ ] Independently verify shoe reference marks; theoretical centerline stations are **not** manufacturer arrow/hook marks.

## 2. Manufacturer bender catalog
- Greenlee 555 shoe-specific parameters and Klein models: existing linked references; check source revision and the exact shoe.
- Milwaukee iron EMT models 48-22-4080, 48-22-4081, 48-22-4082: the official product pages confirm model and size; **no radius or take-up is manufactured by the app**.
- Gardner Bender BigBen 960, 961, 962: deducts 5/6/8 in (EMT 1/2, 3/4, 1) and centerline radii 3.69/4.74/5.81 in are documented by the manufacturer. Verify the exact head and source/manual version physically.
- [ ] Compare values and reference marks against the current official manual.
- [ ] Use a physical bend and measured springback at every shoe/size combination.

Official source examples:
- https://www.gardnerbender.com/-/media/inriver/GAR_BRO_032_1220_Hand%20Bender%20How%20To%20Guide.pdf
- https://www.milwaukeetool.com/products/details/1-2-emt-iron-conduit-bender/48-22-4080
- https://www.milwaukeetool.com/products/details/3-4-emt-iron-conduit-bender/48-22-4081
- https://www.milwaukeetool.com/products/details/1-emt-iron-conduit-bender/48-22-4082

## 3. QuickCheck
- [x] Programmatic invalid lengths / non-finite values / bend angles / negative dimensions.
- [x] Programmatic adjacent spacing, unknown radius and conservative tangent clearance notices.
- [ ] Verify default estimates against manufacturer minimum stub and outside-diameter allowances.
- [ ] Confirm warnings in both light/dark mode and each supported UI language.

## 4. Ease of use
- [ ] User can pin/unpin a bender, quit and reopen; favorites remain pinned and can be selected on the planner.
- [ ] User can use text or the angle/position sliders without losing typed inputs.
- [ ] Flipping bend direction updates the displayed pattern; reversing measurement end does **not** silently change physical bend direction.
- [ ] Multi-page PDF marks are sorted from the selected measurement end and printed legibly.

## 5. Automated and real-device acceptance
- Run `tools/field_math_test_runner.swift` through the `visionbend-field-math.yml` workflow (compile actual production math under Swift on Ubuntu).
- Run `VisionBendTests/AdvancedFieldPatternsTests.swift` and `FieldQuickCheckTests` through the regular macOS iOS simulator workflow.
- Run `VisionBendUITests/VisionBendAdvancedPatternsUITests.swift` in an iPhone simulator.
- [ ] Real iPhone: camera level, permissions, Vision photo scan, ARKit measurement and LiDAR on supported devices.
- [ ] Real bender: repeat each relevant bend, measure marked layout and final rise, record absolute errors and shoe calibration.
- [ ] StoreKit purchases/restores and signed IPA through Codemagic/TestFlight (separate release validation).

**Release gate:** no automatic claim of 100% field accuracy, and no fabricated deduct or radius for undocumented shoes. Apple Watch support remains removed.
