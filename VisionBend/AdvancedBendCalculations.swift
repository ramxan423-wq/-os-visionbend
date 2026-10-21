import Foundation

/// Geometry-only helpers. Marking conventions and springback vary by bender.
enum AdvancedBendCalculations {
    static func compoundNinetyTravel(firstLeg: Double, secondLeg: Double) throws -> Double {
        guard firstLeg.isFinite, secondLeg.isFinite, firstLeg > 0, secondLeg > 0 else { throw BendCalculationError.invalidInput }
        return hypot(firstLeg, secondLeg)
    }

    static func compoundNinetyRotation(firstLeg: Double, secondLeg: Double) throws -> Double {
        guard firstLeg.isFinite, secondLeg.isFinite, firstLeg > 0, secondLeg > 0 else { throw BendCalculationError.invalidInput }
        return atan2(secondLeg, firstLeg) * 180 / .pi
    }

    static func compoundNinetyDevelopedArc(centerlineRadius: Double) throws -> Double {
        try MoreBendCalculations.arcLength(centerlineRadius: centerlineRadius, angleDegrees: 90)
    }

    static func fractionalInches(_ inches: Double, denominator: Int = 16) -> String {
        guard inches.isFinite, denominator > 0 else { return "—" }
        let negative = inches < 0 ? "-" : ""
        let rounded = Int((abs(inches) * Double(denominator)).rounded())
        let whole = rounded / denominator
        let remainder = rounded % denominator
        if remainder == 0 { return "\(negative)\(whole) in" }
        let gcd = greatestCommonDivisor(remainder, denominator)
        let fraction = "\(remainder / gcd)/\(denominator / gcd)"
        return whole == 0 ? "\(negative)\(fraction) in" : "\(negative)\(whole) \(fraction) in"
    }

    static func parseInches(_ input: String) -> Double? {
        let normalized = input.trimmingCharacters(in: .whitespacesAndNewlines)
            .replacingOccurrences(of: "in", with: "", options: .caseInsensitive)
            .replacingOccurrences(of: "\"", with: "")
            .trimmingCharacters(in: .whitespacesAndNewlines)
        guard !normalized.isEmpty else { return nil }

        if let value = Double(normalized.replacingOccurrences(of: ",", with: ".")),
           value.isFinite { return value }

        // Accept fractions such as 3/8, 1 1/2, 1-1/2 and signed values.
        // A negative sign belongs to the WHOLE measurement, not just one component.
        let negative = normalized.hasPrefix("-")
        let signed = normalized.hasPrefix("+") || negative
        let unsigned = signed ? String(normalized.dropFirst()) : normalized
        let parts = unsigned.replacingOccurrences(of: "-", with: " ")
            .split(whereSeparator: { $0.isWhitespace })
        guard parts.count == 1 || parts.count == 2 else { return nil }

        let pair = parts[parts.count - 1].split(separator: "/", omittingEmptySubsequences: false)
        guard pair.count == 2,
              let numerator = Double(pair[0]), let denominator = Double(pair[1]),
              numerator.isFinite, denominator.isFinite,
              numerator >= 0, denominator > 0 else { return nil }
        let whole = parts.count == 2 ? Double(parts[0]) : 0
        guard let whole, whole.isFinite, whole >= 0 else { return nil }
        let magnitude = whole + numerator / denominator
        guard magnitude.isFinite else { return nil }
        return negative ? -magnitude : magnitude
    }

    private static func greatestCommonDivisor(_ a: Int, _ b: Int) -> Int {
        var x = a, y = b
        while y != 0 { (x, y) = (y, x % y) }
        return x
    }
}
