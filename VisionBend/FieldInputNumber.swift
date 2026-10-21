import Foundation

/// Consistent length parsing and unit conversion across iOS field tools.
/// Validates finite values; supports fractional inches for imperial input.
enum FieldInputNumber {
    static func parse(_ input: String, unit: MeasurementUnit) -> Double? {
        if unit == .inches {
            return AdvancedBendCalculations.parseInches(input)
        }
        let trimmed = input.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !trimmed.isEmpty else { return nil }
        guard let value = Double(trimmed.replacingOccurrences(of: ",", with: ".")),
              value.isFinite else { return nil }
        return value
    }

    static func convertedText(_ value: String, from: MeasurementUnit, to: MeasurementUnit) -> String {
        guard from != to, let parsed = parse(value, unit: from) else { return value }
        let converted = from.convert(parsed, to: to)
        guard converted.isFinite else { return value }
        return String(format: "%.4f", converted)
    }
}
