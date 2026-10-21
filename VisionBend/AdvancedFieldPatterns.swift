import Foundation

/// Theoretical centerline patterns: positions are NOT shoe/hook/arrow marks.
/// A manufacturer-specific bend table and field test are required before fabrication.
enum AdvancedFieldPatterns {
    struct Station: Equatable {
        let position: Double
        let angle: Double
        let direction: String
    }
    struct ObstacleSolution: Equatable {
        let clearWidth: Double
        let clearHeight: Double
        let diagonalTravel: Double
        let rotationDegrees: Double
        let arcLength90: Double?
    }
    enum ObstacleShape: String, CaseIterable, Identifiable {
        case circle = "Circle"
        case square = "Square"
        case rectangle = "Rectangle"
        var id: String { rawValue }
    }

    private static func require(_ values: Double...) throws {
        guard values.allSatisfy({ $0.isFinite }) else { throw BendCalculationError.invalidInput }
    }
    static func offsetPair(start: Double, rise: Double, angle: Double,
                           up: String = "Up", down: String = "Down") throws -> [Station] {
        try require(start, rise, angle)
        guard start >= 0, rise > 0, angle > 0, angle < 90 else { throw BendCalculationError.invalidInput }
        let spacing = try BendCalculations.offsetSpacing(rise: rise, angleDegrees: angle)
        return [Station(position: start, angle: angle, direction: up),
                Station(position: start + spacing, angle: angle, direction: down)]
    }
    static func matchingBendsOffset(start: Double, rise: Double, angle: Double,
                                    betweenPairs: Double) throws -> [Station] {
        try require(betweenPairs)
        guard betweenPairs >= 0 else { throw BendCalculationError.invalidInput }
        let pair = try offsetPair(start: start, rise: rise, angle: angle)
        let nextStart = pair[1].position + betweenPairs
        return pair + (try offsetPair(start: nextStart, rise: rise, angle: angle))
    }
    static func matchingCentersOffset(center: Double, rise: Double, angle: Double,
                                      centerGap: Double) throws -> [Station] {
        try require(center, centerGap)
        guard center >= 0, centerGap >= 0 else { throw BendCalculationError.invalidInput }
        let span = try BendCalculations.offsetSpacing(rise: rise, angleDegrees: angle)
        let left = center - centerGap / 2 - span
        guard left >= 0 else { throw BendCalculationError.invalidInput }
        return try matchingBendsOffset(start: left, rise: rise, angle: angle,
                                       betweenPairs: centerGap)
    }
    /// The longitudinal stagger is geometrical; shoe adjustment is separate.
    static func parallelOffsets(firstStart: Double, rise: Double, angle: Double,
                                conduitSeparation: Double, count: Int) throws -> [[Station]] {
        try require(firstStart, rise, angle, conduitSeparation)
        guard (1...20).contains(count), conduitSeparation >= 0,
              firstStart >= 0, angle > 0, angle < 90 else { throw BendCalculationError.invalidInput }
        let stagger = conduitSeparation / tan(angle * .pi / 180)
        return try (0..<count).map { i in
            try offsetPair(start: firstStart + Double(i) * stagger, rise: rise, angle: angle)
        }
    }
    static func matchingKick(start: Double, rise: Double, angle: Double,
                             separation: Double, alignCenters: Bool) throws -> [Station] {
        try require(start, rise, angle, separation)
        guard start >= 0, rise > 0, angle > 0, angle < 90,
              separation > 0 else { throw BendCalculationError.invalidInput }
        let stagger = alignCenters ? separation / tan(angle * .pi / 180) : separation
        return [Station(position: start, angle: angle, direction: "Up"),
                Station(position: start + stagger, angle: angle, direction: "Up")]
    }
    static func parallelKicks(firstStart: Double, rise: Double, angle: Double,
                              conduitSeparation: Double, count: Int,
                              forward: Bool) throws -> [Station] {
        try require(firstStart, rise, angle, conduitSeparation)
        guard firstStart >= 0, rise > 0, angle > 0, angle < 90,
              conduitSeparation >= 0, (1...20).contains(count) else {
            throw BendCalculationError.invalidInput
        }
        let stagger = conduitSeparation / tan(angle * .pi / 180)
        return (0..<count).map { i in
            Station(position: firstStart + Double(i) * stagger,
                    angle: angle, direction: forward ? "Down" : "Up")
        }
    }
    static func compound90(shape: ObstacleShape, width: Double, height: Double,
                           clearance: Double, centerlineRadius: Double?) throws -> ObstacleSolution {
        try require(width, height, clearance)
        guard width > 0, height > 0, clearance >= 0 else { throw BendCalculationError.invalidInput }
        let obstacleHeight = shape == .circle || shape == .square ? width : height
        let w = width + 2 * clearance
        let h = obstacleHeight + 2 * clearance
        let radiusArc: Double?
        if let centerlineRadius {
            try require(centerlineRadius)
            guard centerlineRadius > 0 else { throw BendCalculationError.invalidInput }
            radiusArc = centerlineRadius * .pi / 2
        } else { radiusArc = nil }
        let diagonal = hypot(w, h)
        guard diagonal.isFinite else { throw BendCalculationError.invalidInput }
        return ObstacleSolution(clearWidth: w, clearHeight: h,
                                diagonalTravel: diagonal,
                                rotationDegrees: atan2(h, w) * 180 / .pi,
                                arcLength90: radiusArc)
    }
    /// Measure the same marks from the OTHER end. This does NOT flip bend direction.
    static func reversedMeasurements(_ marks: [Station], conduitLength: Double) throws -> [Station] {
        try require(conduitLength)
        guard conduitLength > 0, marks.allSatisfy({ $0.position.isFinite && $0.position >= 0 && $0.position <= conduitLength }) else {
            throw BendCalculationError.invalidInput
        }
        return marks.map { Station(position: conduitLength - $0.position,
                                   angle: $0.angle, direction: $0.direction) }
            .sorted { $0.position < $1.position }
    }
    static func oppositeDirection(_ direction: String) -> String {
        switch direction {
        case "Up": return "Down"
        case "Down": return "Up"
        case "Left": return "Right"
        case "Right": return "Left"
        default: return direction
        }
    }
}
