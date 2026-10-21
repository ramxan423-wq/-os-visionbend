import Foundation

/// Text lengths can use a comma as a list separator or as a decimal separator.
/// A semicolon or newline list uses comma exclusively as a decimal character.
enum ConduitCutInput {
    static func separator(in text: String) -> Character {
        if text.contains(";") { return ";" }
        if text.contains("\n") { return "\n" }
        return ","
    }

    static func entries(_ text: String) -> [String] {
        let separator = separator(in: text)
        return text.split(separator: separator, omittingEmptySubsequences: false)
            .map { String($0).trimmingCharacters(in: .whitespacesAndNewlines) }
    }

    static func lengths(_ text: String, unit: MeasurementUnit) -> [Double]? {
        let parts = entries(text)
        guard !parts.isEmpty && parts.count <= 500 && parts.allSatisfy({ !$0.isEmpty }) else { return nil }
        let numbers = parts.map { FieldInputNumber.parse($0, unit: unit) }
        guard numbers.allSatisfy({ $0 != nil }) else { return nil }
        return numbers.compactMap { $0 }
    }

    static func convertedText(_ text: String, from: MeasurementUnit, to: MeasurementUnit) -> String {
        guard from != to else { return text }
        let delimiter = separator(in: text)
        let parts = entries(text).map { FieldInputNumber.convertedText($0, from: from, to: to) }
        return parts.joined(separator: delimiter == "\n" ? "\n" : String(delimiter) + " ")
    }
}
