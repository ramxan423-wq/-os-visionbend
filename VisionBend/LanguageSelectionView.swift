import SwiftUI

/// First-launch language choice. Language names are autonyms, so they remain
/// readable even before a locale has been selected.
enum VisionBendLanguages {
    // Exactly 20 selectable app-interface languages, including English.
    // Additional choices must not be presented before full UI localization QA.
    static let supported: [(code: String, name: String)] = [
        ("en", "English"),
        ("tr", "Türkçe"),
        ("es", "Español"),
        ("fr", "Français"),
        ("de", "Deutsch"),
        ("ar", "العربية"),
        ("pt", "Português"),
        ("it", "Italiano"),
        ("ru", "Русский"),
        ("fa", "فارسی"),
        ("hi", "हिन्दी"),
        ("zh-Hans", "简体中文"),
        ("zh-Hant", "繁體中文"),
        ("ja", "日本語"),
        ("ko", "한국어"),
        ("id", "Bahasa Indonesia"),
        ("da", "Dansk"),
        ("sv", "Svenska"),
        ("nl", "Nederlands"),
        ("fi", "Suomi")
    ]
    static func name(for code: String) -> String {
        supported.first(where: { $0.code == code })?.name ?? "English"
    }
}

struct LanguageSelectionView: View {
    @AppStorage("visionbend.language") private var language = "system"
    @AppStorage("visionbend.languageChosen") private var languageChosen = false
    @State private var selected = "en"
    @State private var search = ""

    private var filtered: [(code: String, name: String)] {
        VisionBendLanguages.supported.filter {
            search.isEmpty || $0.name.localizedCaseInsensitiveContains(search) ||
                $0.code.localizedCaseInsensitiveContains(search)
        }
    }
    var body: some View {
        NavigationStack {
            VStack(spacing: 12) {
                Text(VisionBendLocalization.text("Choose your language", language: selected)).font(.title2.bold())
                Text("VisionBend")
                    .font(.subheadline).foregroundStyle(.secondary)
                TextField(VisionBendLocalization.text("Search language", language: selected), text: $search)
                    .textFieldStyle(.roundedBorder).padding(.horizontal)
                List(Array(filtered.enumerated()), id: \.offset) { _, item in
                    Button {
                        selected = item.code
                    } label: {
                        HStack {
                            Text(item.name).foregroundStyle(.primary)
                            Spacer()
                            if selected == item.code { Image(systemName: "checkmark.circle.fill").foregroundStyle(.orange) }
                        }
                        .contentShape(Rectangle())
                    }
                }
                Button {
                    language = selected
                    languageChosen = true
                } label: {
                    Text(VisionBendLocalization.text("Continue", language: selected))
                        .frame(maxWidth: .infinity).padding(.vertical, 10)
                }
                .buttonStyle(.borderedProminent).tint(.orange)
                .padding(.horizontal).padding(.bottom, 8)
            }
            .navigationTitle("VisionBend")
            .onAppear {
                let preferred = Locale.preferredLanguages.first ?? "en"
                if language != "system" && VisionBendLanguages.supported.contains(where: { $0.code == language }) {
                    selected = language
                } else {
                    selected = VisionBendLanguages.supported.first(where: { preferred == $0.code })?.code ??
                        VisionBendLanguages.supported.first(where: { preferred.hasPrefix($0.code + "-") })?.code ?? "en"
                }
            }
        }
    }
}
