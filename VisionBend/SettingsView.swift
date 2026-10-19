import SwiftUI

struct SettingsView: View {
    @AppStorage("visionbend.appearance") private var appearance = 1
    @AppStorage("visionbend.units") private var units = 0
    @AppStorage("visionbend.language") private var language = "system"

    private var tr: Bool {
        language == "tr" || (language == "system" && Locale.current.language.languageCode?.identifier == "tr")
    }
    private func t(_ turkish: String, _ english: String) -> String { tr ? turkish : english }

    var body: some View {
        Form {
            Section(t("Görünüm", "Appearance")) {
                Picker(t("Tema", "Theme"), selection: $appearance) {
                    Text(t("Beyaz", "White")).tag(1)
                    Text(t("Siyah", "Dark")).tag(2)
                    Text(t("Sistem", "System")).tag(0)
                }
                .pickerStyle(.segmented)
            }
            Section(t("Ölçü birimleri", "Measurements")) {
                Picker(t("Birim", "Units"), selection: $units) {
                    Text(t("Milimetre", "Millimeters")).tag(0)
                    Text(t("Santimetre", "Centimeters")).tag(1)
                    Text(t("İnç", "Inches")).tag(2)
                }
                Text(t("Birim değişince mevcut hesaplama girişleri dönüştürülür. Kaydedilmiş kayıtlar eski değerlerini korur.", "Changing units converts current calculator inputs. Saved records retain their original values."))
                    .font(.caption).foregroundStyle(.secondary)
            }
            Section(t("Güvenlik", "Safety")) {
                Text(t("Hesaplamalar teoriktir. Kullanacağınız bükücünün yarıçapını, take-up payını ve düzeltmelerini sahada doğrulayın.", "Calculations are theoretical. Verify bend radius, take-up and deductions for your exact bender before use."))
            }
        }
        .navigationTitle(t("Gelişmiş ayarlar", "Advanced Settings"))
    }
}
