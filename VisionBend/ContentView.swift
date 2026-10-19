import SwiftUI

struct ContentView: View {
    @StateObject private var history = BendHistory()
    @AppStorage("visionbend.appearance") private var appearance = 1
    @AppStorage("visionbend.language") private var language = "system"
    @AppStorage("visionbend.units") private var units = 0
    @State private var previousUnit = 0
    @State private var showHistory = false
    @State private var showSettings = false
    @State private var showCamera = false
    @State private var showConduitScan = false
    @State private var showDepthScan = false
    @State private var showAR = false
    @State private var showPremium = false
    @State private var showReference = false
    @State private var showMultiBend = false
    @State private var showCutPlanner = false
    @AppStorage("visionbend.mode") private var mode = 0
    @AppStorage("visionbend.lastHeight") private var height = "10"
    @AppStorage("visionbend.lastAngle") private var angle = "30"
    @State private var output = ""
    @State private var errorMessage = ""
    @State private var selectedTab = 0
    private let accent = Color(red: 1, green: 0.45, blue: 0.08)
    private let names = ["Offset", "3-Point Saddle", "Kick", "Arc", "Rolling Offset", "90° Stub", "4-Point Saddle", "Compound 90°"]
    private var turkish: Bool { language == "tr" || (language == "system" && Locale.current.language.languageCode?.identifier == "tr") }
    private func t(_ tr: String, _ en: String) -> String { turkish ? tr : en }
    private var activeLocale: Locale { language == "system" ? .current : Locale(identifier: language) }
    private var unitName: String { units == 0 ? "mm" : units == 1 ? "cm" : "in" }
    private var firstLabel: String {
        switch mode {
        case 3: return t("Merkez yarıçapı", "Centerline radius")
        case 4: return t("Yatay kaçıklık", "Horizontal offset")
        case 5: return t("İstenen dik çıkış uzunluğu", "Desired stub length")
        case 7: return t("Birinci dik kenar", "First perpendicular leg")
        default: return t("Yükseklik / Mesafe", "Rise / height")
        }
    }
    private var secondLabel: String {
        switch mode {
        case 4: return t("Dikey kaçıklık", "Vertical offset")
        case 5: return t("Bükücü payı (take-up)", "Bender take-up")
        case 7: return t("İkinci dik kenar", "Second perpendicular leg")
        case 1: return t("Merkez açı (derece)", "Center angle (degrees)")
        default: return t("Büküm açısı (derece)", "Bend angle (degrees)")
        }
    }
    var body: some View {
        TabView(selection: $selectedTab) {
            NavigationStack { calculatorPage.navigationTitle("VisionBend") }
                .tabItem { Label(t("Büküm", "Bends"), systemImage: "angle") }.tag(0)
            NavigationStack { cameraPage.navigationTitle(t("Kamera", "Camera")) }
                .tabItem { Label(t("Kamera", "Camera"), systemImage: "camera") }.tag(1)
            NavigationStack { planningPage.navigationTitle(t("Planlama", "Planning")) }
                .tabItem { Label(t("Plan", "Plan"), systemImage: "ruler") }.tag(2)
            NavigationStack { projectsPage.navigationTitle(t("Projelerim", "Projects")) }
                .tabItem { Label(t("Projeler", "Projects"), systemImage: "folder") }.tag(3)
            NavigationStack { settingsPage.navigationTitle(t("Ayarlar", "Settings")) }
                .tabItem { Label(t("Ayarlar", "Settings"), systemImage: "gearshape") }.tag(4)
        }
        .tint(accent)
        .environment(\.locale, activeLocale)
        .preferredColorScheme(appearance == 0 ? nil : appearance == 1 ? .light : .dark)
        .onAppear { previousUnit = units }
        .onChange(of: units) { newValue in
            guard let oldUnit = MeasurementUnit(rawValue: previousUnit),
                  let newUnit = MeasurementUnit(rawValue: newValue) else { previousUnit = newValue; return }
            if let first = (oldUnit == .inches ? AdvancedBendCalculations.parseInches(height) : Double(height.replacingOccurrences(of: ",", with: "."))), first.isFinite {
                height = String(format: "%.4f", oldUnit.convert(first, to: newUnit))
            }
            if [4,5,7].contains(mode), let second = (oldUnit == .inches ? AdvancedBendCalculations.parseInches(angle) : Double(angle.replacingOccurrences(of: ",", with: "."))), second.isFinite {
                angle = String(format: "%.4f", oldUnit.convert(second, to: newUnit))
            }
            output = ""; previousUnit = newValue
        }
        .sheet(isPresented: $showCutPlanner) { NavigationStack { ConduitCutOptimizerView() } }
        .sheet(isPresented: $showMultiBend) { NavigationStack { MultiBendPlannerView() } }
        .sheet(isPresented: $showReference) { NavigationStack { BenderReferenceView() } }
        .sheet(isPresented: $showAR) { NavigationStack { ARMeasureView() } }
        .sheet(isPresented: $showPremium) { NavigationStack { SubscriptionView() } }
        .sheet(isPresented: $showHistory) { ProjectHistoryView(history: history) }
        .sheet(isPresented: $showSettings) { SettingsView() }
        .sheet(isPresented: $showDepthScan) { NavigationStack { DepthConduitScanView() } }
        .sheet(isPresented: $showConduitScan) { NavigationStack { ConduitScanView() } }
        .sheet(isPresented: $showCamera) {
            NavigationStack {
                CameraLevelView()
                    .toolbar { ToolbarItem(placement: .navigationBarTrailing) { Button(t("Bitti", "Done")) { showCamera = false } } }
            }
        }
    }
    private var calculatorPage: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 18) {
                Text(t("Boru Bükme Hesaplayıcı", "Conduit Bending Calculator"))
                    .font(.title2.bold())
                Text(t("1. Büküm türünü seç  2. Ölçüleri gir  3. Sonucu hesapla", "1. Choose bend  2. Enter measurements  3. Calculate"))
                    .font(.subheadline).foregroundStyle(.secondary)
                VStack(alignment: .leading, spacing: 12) {
                    Text(t("Büküm türü", "Bend type")).font(.headline)
                    Picker(t("Büküm türü", "Bend type"), selection: $mode) {
                        ForEach(names.indices, id: \.self) { i in Text(names[i]).tag(i) }
                    }.pickerStyle(.menu).tint(accent)
                        .onChange(of: mode) { _ in
                            output = ""; errorMessage = ""
                            height = ""
                            angle = ""
                        }
                    Text(firstLabel + " (" + unitName + ")").font(.subheadline.bold())
                    TextField(firstLabel, text: $height).keyboardType(.decimalPad).textFieldStyle(.roundedBorder)
                        .onChange(of: height) { _ in output = ""; errorMessage = "" }
                    Text(secondLabel + ([4,5,7].contains(mode) ? " (" + unitName + ")" : ""))
                        .font(.subheadline.bold())
                    TextField(secondLabel, text: $angle).keyboardType(.decimalPad).textFieldStyle(.roundedBorder)
                        .onChange(of: angle) { _ in output = ""; errorMessage = "" }
                    Button(action: calculate) {
                        Label(t("Hesapla", "Calculate"), systemImage: "equal")
                            .frame(maxWidth: .infinity).padding(.vertical, 8)
                    }.buttonStyle(.borderedProminent).tint(accent)
                }.padding().background(.regularMaterial, in: RoundedRectangle(cornerRadius: 16))
                if !errorMessage.isEmpty { Text(errorMessage).foregroundStyle(.red) }
                if !output.isEmpty {
                    VStack(alignment: .leading, spacing: 12) {
                        Text(t("Hesaplama sonucu", "Calculation result")).font(.headline)
                        Text(output).font(.body.monospacedDigit()).textSelection(.enabled)
                        Button(t("Hesaplamayı Kaydet", "Save Calculation")) {
                            guard let a = numericInput(height), let b = numericInput(angle), names.indices.contains(mode) else { return }
                            history.add(mode: names[mode], first: a, second: b, result: output)
                        }.tint(accent)
                    }.padding().frame(maxWidth: .infinity, alignment: .leading)
                        .background(.regularMaterial, in: RoundedRectangle(cornerRadius: 16))
                }
                Text(t("Sahada uygulamadan önce bükücü modelinin paylarını ve ölçüleri doğrulayın.", "Verify your bender's take-up and allowances before field use."))
                    .font(.footnote).foregroundStyle(.secondary)
            }.padding()
        }
    }
    private var cameraPage: some View {
        List {
            Section(t("Ölçüm araçları", "Measurement tools")) {
                Button { showCamera = true } label: { Label(t("Kamera terazisi", "Camera level"), systemImage: "camera.viewfinder") }
                Button { showConduitScan = true } label: { Label(t("Boruyu fotoğrafla tara", "Conduit photo scan"), systemImage: "camera.metering.center.weighted") }
                Button { showDepthScan = true } label: { Label(t("Derinlik destekli tarama (LiDAR)", "Depth-assisted scan (LiDAR)"), systemImage: "viewfinder") }
                Button { showAR = true } label: { Label(t("AR mesafe ölçümü", "AR measure"), systemImage: "ruler") }
            }
            Section {
                Text(t("LiDAR ölçümü yalnızca destekleyen cihazlarda çalışır. Fotoğrafla çap tahmini için aynı düzlemde ölçüsü bilinen bir referans gerekir. AR işaretlerini gerçek ölçüyle doğrulayın.", "LiDAR requires a compatible device. Photo diameter estimates need a known-size reference in the same plane. Verify AR marks with physical measurements."))
                    .font(.footnote).foregroundStyle(.secondary)
            }
        }.tint(accent)
    }
    private var planningPage: some View {
        List {
            Button { showMultiBend = true } label: { Label(t("Çoklu büküm ve 2D plan", "Multi-bend & 2D planner"), systemImage: "point.topleft.down.curvedto.point.bottomright.up") }
            Button { showCutPlanner = true } label: { Label(t("Boru kesim optimizasyonu", "Conduit cut optimizer"), systemImage: "scissors") }
            Button { showReference = true } label: { Label(t("Bükücü referans ve katalog", "Bender reference"), systemImage: "books.vertical") }
        }.tint(accent)
    }
    private var projectsPage: some View {
        List {
            Button { showHistory = true } label: { Label(t("Kaydedilen hesaplamalar", "Saved bends"), systemImage: "clock.arrow.circlepath") }
            Button { showMultiBend = true } label: { Label(t("Plan ve PDF dışa aktarma", "Planner & PDF export"), systemImage: "doc.richtext") }
        }.tint(accent)
    }
    private var settingsPage: some View {
        List {
            Section(t("Uygulama dili", "App language")) {
                Picker(t("Dil", "Language"), selection: $language) {
                    Text(t("Telefon dili", "Device language")).tag("system")
                    Text("Türkçe").tag("tr")
                    Text("English").tag("en")
                }
            }
            Section(t("Görünüm", "Appearance")) {
                Picker(t("Tema", "Theme"), selection: $appearance) {
                    Text(t("Beyaz", "White")).tag(1)
                    Text(t("Siyah", "Black")).tag(2)
                    Text(t("Sistem", "System")).tag(0)
                }.pickerStyle(.segmented)
            }
            Button { showSettings = true } label: { Label(t("Ölçü birimleri", "Units"), systemImage: "slider.horizontal.3") }
            Button { showReference = true } label: { Label(t("Bükücü kataloğu", "Bender catalog"), systemImage: "book") }
            Button { showPremium = true } label: { Label("Premium", systemImage: "star") }
        }.tint(accent)
    }

    private func numericInput(_ value: String) -> Double? {
        units == 2 ? AdvancedBendCalculations.parseInches(value) : Double(value.replacingOccurrences(of: ",", with: "."))
    }

    private func calculate() {
        output = ""
        errorMessage = ""
        guard let rise = numericInput(height),
              let degrees = numericInput(angle),
              rise.isFinite, degrees.isFinite else {
            errorMessage = t("Geçerli sayısal ölçüler girin.", "Enter valid numeric values.")
            return
        }
        do {
            if mode == 0 {
                let spacing = try BendCalculations.offsetSpacing(rise: rise, angleDegrees: degrees)
                let shrink = try BendCalculations.offsetShrink(rise: rise, angleDegrees: degrees)
                output = String(format: t("İşaretler arası mesafe: %.2f %@\nTeorik kısalma: %.2f %@", "Mark spacing: %.2f %@\nTheoretical shrink: %.2f %@"), spacing, unitName, shrink, unitName)
            } else if mode == 1 {
                let distance = try BendCalculations.saddleOuterMarkDistance(height: rise, centerAngleDegrees: degrees)
                output = String(format: t("Merkezden dış işarete: %.2f %@\nDış büküm açısı: %.1f°", "Center to outer mark: %.2f %@\nOuter bend angle: %.1f°"), distance, unitName, degrees / 2)
            } else if mode == 2 {
                let travel = try MoreBendCalculations.kickTravel(rise: rise, angleDegrees: degrees)
                output = String(format: t("Kick yatay ilerleme: %.2f %@", "Kick horizontal travel: %.2f %@"), travel, unitName)
            } else if mode == 3 {
                let arc = try MoreBendCalculations.arcLength(centerlineRadius: rise, angleDegrees: degrees)
                output = String(format: t("Merkez hattı yay uzunluğu: %.2f %@", "Centerline arc length: %.2f %@"), arc, unitName)
            } else if mode == 4 {
                let roll = try MoreBendCalculations.rollingOffset(horizontal: rise, vertical: degrees)
                output = String(format: t("Gerçek çapraz kaçıklık: %.2f %@", "True rolling offset: %.2f %@"), roll, unitName)
            } else if mode == 5 {
                let mark = try ExtraBendCalculations.ninetyDegreeStubMark(desiredStub: rise, takeUp: degrees)
                output = String(format: t("90° büküm işareti: %.2f %@", "90° stub mark: %.2f %@"), mark, unitName)
            } else if mode == 6 {
                let spacing = try ExtraBendCalculations.fourPointSaddleMarkSpacing(clearance: rise, bendAngleDegrees: degrees)
                output = String(format: t("Her offset için işaret aralığı: %.2f %@", "Each offset mark spacing: %.2f %@"), spacing, unitName)
            } else if mode == 7 {
                let travel = try AdvancedBendCalculations.compoundNinetyTravel(firstLeg: rise, secondLeg: degrees)
                let rotation = try AdvancedBendCalculations.compoundNinetyRotation(firstLeg: rise, secondLeg: degrees)
                output = String(format: "Planar diagonal: %.2f\nOrientation: %.1f°\nGeometry only — physical bend marks require verified radius, bender and conduit size.", travel, rotation)
            } else {
                errorMessage = t("Büküm türünü yeniden seçin.", "Unknown calculator mode. Select a mode again.")
            }
        } catch {
            errorMessage = error.localizedDescription
        }
        if units == 2, !output.isEmpty {
            output += "\n" + t("İlk ölçü (kesirli inç): ", "First value (fractional inches): ") + AdvancedBendCalculations.fractionalInches(rise)
        }
    }
}
