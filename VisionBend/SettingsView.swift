import SwiftUI

struct SettingsView: View {
    @AppStorage("visionbend.appearance") private var appearance = 1
    @AppStorage("visionbend.units") private var units = 0
    @AppStorage("visionbend.language") private var language = "system"

    private func t(_ turkish: String, _ english: String) -> String {
        VisionBendLocalization.text(english, turkish: turkish, language: language)
    }

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
            Section("Legal & Support") {
                NavigationLink {
                    VisionBendLegalPage(kind: .privacy)
                } label: {
                    Label("Privacy Policy", systemImage: "hand.raised")
                }
                NavigationLink {
                    VisionBendLegalPage(kind: .support)
                } label: {
                    Label("Support", systemImage: "questionmark.circle")
                }
                NavigationLink {
                    VisionBendLegalPage(kind: .terms)
                } label: {
                    Label("Terms of Use", systemImage: "doc.text")
                }
            }
            Section(t("Güvenlik", "Safety")) {
                Text(t("Hesaplamalar teoriktir. Kullanacağınız bükücünün yarıçapını, take-up payını ve düzeltmelerini sahada doğrulayın.", "Calculations are theoretical. Verify bend radius, take-up and deductions for your exact bender before use."))
            }
        }
        .navigationTitle(t("Gelişmiş ayarlar", "Advanced Settings"))
    }
}

private struct VisionBendLegalPage: View {
    enum Kind {
        case privacy, support, terms

        var title: String {
            switch self {
            case .privacy: return "Privacy Policy"
            case .support: return "Support"
            case .terms: return "Terms of Use"
            }
        }
    }

    let kind: Kind

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 16) {
                Text(kind.title).font(.largeTitle.bold())
                switch kind {
                case .privacy:
                    Text("Last updated: October 27, 2026").font(.caption).foregroundStyle(.secondary)
                    paragraph("Information & storage", "VisionBend’s standard conduit bending calculators do not require an account. Measurements, saved projects and preferences may be stored on your device.")
                    paragraph("Device permissions", "Some optional features may request access to device capabilities. Permissions are managed in iOS Settings. Manual bend calculations do not require camera access.")
                    paragraph("Payments", "VisionBend is a one-time paid App Store download. Apple processes your payment; VisionBend does not request payment card details.")
                    paragraph("Third-party services", "VisionBend does not intentionally include third-party advertising trackers. Apple may handle App Store purchases and diagnostics under Apple’s own policies.")
                    paragraph("Data retention", "Locally stored records remain on your device until deleted using the app or iOS. Device backups may be controlled through your Apple account settings.")
                    paragraph("Changes and questions", "This policy may change as features change. Please see the Support page for assistance.")
                case .support:
                    paragraph("Getting started", "Choose a bend type, set your measurement units, enter dimensions, and tap Calculate. Verify every result against your exact bender’s manufacturer instructions before field use.")
                    paragraph("Troubleshooting", "Check units, conduit dimensions, bend angle, machine model, and take-up allowances. If a screen becomes unresponsive, restart VisionBend and install the latest update.")
                    paragraph("Contact", "Use the developer contact information on VisionBend’s App Store listing. Include your iPhone model, iOS version, app version, and the steps needed to reproduce the issue. Please do not send sensitive personal data.")
                    paragraph("Safety", "Calculations are planning aids. Follow electrical codes, manufacturer instructions, and safe work procedures.")
                case .terms:
                    Text("Last updated: October 27, 2026").font(.caption).foregroundStyle(.secondary)
                    paragraph("License", "VisionBend is a one-time paid App Store download with no recurring subscription. The Apple Standard Licensed Application End User License Agreement (EULA) governs your license.")
                    paragraph("Intended use", "VisionBend provides conduit bending calculations, planning tools, and references for informational use. Results are not certified measurements or engineering approval.")
                    paragraph("Field verification", "Confirm units, conduit dimensions, model-specific machine settings, take-up, deductions, and allowances. Perform a test bend when appropriate and follow applicable safety rules and electrical codes.")
                    paragraph("Availability", "Features may vary by app version, device, operating system and permissions.")
                    paragraph("Trademarks", "Third-party product and manufacturer names belong to their respective owners; mention does not imply endorsement.")
                }
            }
            .frame(maxWidth: .infinity, alignment: .leading)
            .padding()
        }
        .navigationTitle(kind.title)
        .navigationBarTitleDisplayMode(.inline)
    }

    private func paragraph(_ heading: String, _ body: String) -> some View {
        VStack(alignment: .leading, spacing: 6) {
            Text(heading).font(.headline)
            Text(body).foregroundStyle(.secondary)
        }
    }
}
