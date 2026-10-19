import SwiftUI

/// First-launch language choice. Language names are autonyms, so they remain
/// readable even before a locale has been selected.
enum VisionBendLanguages {
    static let supported: [(code: String, name: String)] = [
        ("en","English"),("zh-Hans","简体中文"),("hi","हिन्दी"),("es","Español"),
        ("ar","العربية"),("fr","Français"),("bn","বাংলা"),("pt","Português"),
        ("ru","Русский"),("ur","اردو"),("id","Bahasa Indonesia"),("de","Deutsch"),
        ("ja","日本語"),("sw","Kiswahili"),("mr","मराठी"),("te","తెలుగు"),
        ("tr","Türkçe"),("ta","தமிழ்"),("vi","Tiếng Việt"),("ko","한국어"),
        ("it","Italiano"),("th","ไทย"),("gu","ગુજરાતી"),("fa","فارسی"),
        ("pl","Polski"),("uk","Українська"),("pa","ਪੰਜਾਬੀ"),("ml","മലയാളം"),
        ("kn","ಕನ್ನಡ"),("or","ଓଡ଼ିଆ"),("my","မြန်မာ"),("ro","Română"),
        ("nl","Nederlands"),("hu","Magyar"),("el","Ελληνικά"),("cs","Čeština"),
        ("sv","Svenska"),("fi","Suomi"),("da","Dansk"),("no","Norsk"),
        ("he","עברית"),("ku","Kurdî"),("az","Azərbaycanca"),("uz","Oʻzbekcha"),
        ("kk","Қазақша"),("ne","नेपाली"),("si","සිංහල"),("km","ខ្មែរ"),
        ("lo","ລາວ"),("am","አማርኛ"),("ha","Hausa"),("yo","Yorùbá"),
        ("ig","Igbo"),("zu","isiZulu"),("af","Afrikaans"),("ms","Bahasa Melayu"),
        ("fil","Filipino"),("sr","Српски"),("bg","Български"),("hr","Hrvatski")
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
                Text("Choose your language").font(.title2.bold())
                Text("Dilini seç • اختر لغتك • Selecciona tu idioma")
                    .font(.subheadline).foregroundStyle(.secondary)
                TextField("Search language / Dil ara", text: $search)
                    .textFieldStyle(.roundedBorder).padding(.horizontal)
                List(filtered, id: \.code) { item in
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
                    Text("Continue / Devam Et")
                        .frame(maxWidth: .infinity).padding(.vertical, 10)
                }
                .buttonStyle(.borderedProminent).tint(.orange)
                .padding(.horizontal).padding(.bottom, 8)
            }
            .navigationTitle("VisionBend")
            .onAppear {
                let preferred = Locale.preferredLanguages.first ?? "en"
                selected = VisionBendLanguages.supported.first(where: { preferred == $0.code || preferred.hasPrefix($0.code + "-") })?.code ?? "en"
            }
        }
    }
}
