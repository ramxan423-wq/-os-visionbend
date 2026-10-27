import Foundation

/// VisionBend ships with English as its only supported interface language.
/// Keep this compatibility API for existing views and previously saved settings.
enum VisionBendLocalization {
    static func text(_ english: String, turkish: String? = nil, language: String) -> String {
        english
    }

    static func resolvedLanguage(preferredLanguages: [String] = Locale.preferredLanguages) -> String {
        "en"
    }
}
