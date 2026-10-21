// swift-tools-version: 5.9
import PackageDescription

// Standalone production-math QA target. The actual iOS app still builds from
// project.yml; this manifest deliberately excludes all SwiftUI/ARKit sources.
let package = Package(
    name: "VisionBendFieldGeometryQA",
    platforms: [.macOS(.v13)],
    products: [.library(name: "VisionBend", targets: ["VisionBend"])],
    targets: [
        .target(
            name: "VisionBend",
            path: "VisionBend",
            sources: [
                "BendCalculations.swift",
                "AdvancedBendCalculations.swift",
                "MoreBendCalculations.swift",
                "ExtraBendCalculations.swift",
                "FieldBendGeometry.swift",
                "FieldQuickCheck.swift",
                "AdvancedFieldPatterns.swift",
                "BenderCalibration.swift",
                "VerifiedBenderCatalog.swift"
            ]
        ),
        .testTarget(
            name: "VisionBendMathTests",
            dependencies: ["VisionBend"],
            path: "VisionBendTests",
            sources: [
                "BendCalculationsTests.swift",
                "AdvancedBendCalculationsTests.swift",
                "MoreBendCalculationsTests.swift",
                "ExtraBendCalculationsTests.swift",
                "FieldBendGeometryTests.swift",
                "BenderCalibrationTests.swift",
                "AdvancedFieldPatternsTests.swift"
            ]
        )
    ]
)
