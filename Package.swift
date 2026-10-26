// swift-tools-version: 5.9
import PackageDescription

// Linux and macOS validation for the shared, Foundation-only calculation core.
// The iOS-only SwiftUI, ARKit, Vision, SceneKit, and UIKit features still require
// the separate Xcode workflow and physical-device checks.
let package = Package(
    name: "VisionBendCoreValidation",
    defaultLocalization: "en",
    products: [
        .library(name: "VisionBend", targets: ["VisionBend"])
    ],
    targets: [
        .target(
            name: "VisionBend",
            path: "VisionBend",
            sources: [
                "AdvancedBendCalculations.swift",
                "BendCalculations.swift",
                "BenderCalibration.swift",
                "ConduitCutInput.swift",
                "ConduitDiameterMath.swift",
                "ExtraBendCalculations.swift",
                "FieldBendGeometry.swift",
                "FieldInputNumber.swift",
                "Greenlee555ScaleReadingTable.swift",
                "GreenleeSaddleTable.swift",
                "LevelMath.swift",
                "MeasurementUnits.swift",
                "MoreBendCalculations.swift",
                "VerifiedBenderCatalog.swift",
                "VisionBendLocalization.swift"
            ]
        ),
        .testTarget(
            name: "VisionBendTests",
            dependencies: ["VisionBend"],
            path: "VisionBendTests",
            exclude: ["CameraPermissionTests.swift"]
        )
    ]
)
