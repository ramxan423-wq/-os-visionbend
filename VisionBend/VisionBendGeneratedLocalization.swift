import Foundation

/// Bundled localization supplement generated during development.
/// Ships in the app; does NOT make network calls at runtime.
/// Manually-reviewed keys in VisionBendLocalization and VisionBendMoreTranslations
/// take precedence over these draft translations.
enum VisionBendGeneratedLocalization {
    private static let translations: [String: [String: String]] = {
        guard let url = Bundle.main.url(forResource: "GeneratedTranslations", withExtension: "json"),
              let data = try? Data(contentsOf: url),
              let dictionary = try? JSONDecoder().decode([String: [String: String]].self, from: data)
        else { return [:] }
        return dictionary
    }()

    static func text(_ english: String, code: String) -> String? {
        translations[code]?[english]
    }

    static func hasTranslation(_ english: String, code: String) -> Bool {
        guard let value = text(english, code: code) else { return false }
        return !value.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty
    }
}
