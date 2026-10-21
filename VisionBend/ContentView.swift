import SwiftUI

struct ContentView: View {
    @StateObject private var history = BendHistory()
    @AppStorage("visionbend.appearance") private var appearance = 1
    @AppStorage("visionbend.language") private var language = "system"
    @AppStorage("visionbend.languageChosen") private var languageChosen = false
    @AppStorage("visionbend.units") private var units = 0
    @AppStorage("visionbend.inputStyle.slider") private var useSliders = false
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
    @State private var showAdvancedPatterns = false
    @AppStorage("visionbend.mode") private var mode = 0
    @AppStorage("visionbend.lastHeight") private var height = "10"
    @AppStorage("visionbend.lastAngle") private var angle = "30"
    @AppStorage("visionbend.rollingAngle") private var rollingAngle = "30"
    @State private var output = ""
    @State private var errorMessage = ""
    @State private var selectedTab = 0
    private let accent = Color(red: 1, green: 0.45, blue: 0.08)
    private let bendNamesTR = ["Offset (Kaydırma)", "3 Nokta Eyer", "Tek Açılı Büküm", "Yay Büküm", "Çapraz Offset", "90° Dik Çıkış", "4 Nokta Eyer", "Birleşik 90°"]
    private let names = ["Offset", "3-Point Saddle", "Kick", "Arc", "Rolling Offset", "90° Stub", "4-Point Saddle", "Compound 90°"]
    private var turkish: Bool { language == "tr" || (language == "system" && Locale.current.language.languageCode?.identifier == "tr") }
    private func t(_ tr: String, _ en: String) -> String { VisionBendLocalization.text(en, turkish: tr, language: language) }
    private var activeLocale: Locale { language == "system" ? .current : Locale(identifier: language) }
    private func localizedFormat(_ template: String, _ arguments: CVarArg...) -> String {
        String(format: template, locale: activeLocale, arguments: arguments)
    }
    private var selectedMode: Int { names.indices.contains(mode) ? mode : 0 }
    private var calculatorNumericValid: Bool {
        guard let first = numericInput(height), let second = numericInput(angle),
              first.isFinite, second.isFinite else { return false }
        switch selectedMode {
        case 0, 2, 6: return first > 0 && second > 0 && second < 90
        case 1: return first > 0 && second > 0 && second < 180
        case 3: return first > 0 && second > 0 && second <= 180
        case 4:
            guard let theta = Double(rollingAngle.replacingOccurrences(of: ",", with: ".")) else { return false }
            return first >= 0 && second >= 0 && (first > 0 || second > 0)
                && theta.isFinite && theta > 0 && theta < 90
        case 5: return first > second && second >= 0
        case 7: return first > 0 && second > 0
        default: return false
        }
    }
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
            NavigationStack { homePage.navigationTitle("VisionBend").navigationDestination(for: Int.self) { index in calculatorPage.onAppear { if mode != index { mode = index; height = ""; angle = ""; output = ""; errorMessage = "" } }.navigationTitle(t(bendNamesTR[index], names[index])).navigationBarTitleDisplayMode(.inline) } }
                .tabItem { Label(t("Ana Sayfa", "Home"), systemImage: "house.fill") }.tag(0)
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
        .onAppear {
            if !names.indices.contains(mode) { mode = 0 }
            previousUnit = units
        }
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
        .sheet(isPresented: $showAdvancedPatterns) {
            NavigationStack {
                AdvancedPatternToolboxView()
                    .toolbar {
                        ToolbarItem(placement: .navigationBarTrailing) {
                            Button(t("Bitti", "Done")) { showAdvancedPatterns = false }
                        }
                    }
            }
        }
        .sheet(isPresented: $showCutPlanner) {
            NavigationStack {
                ConduitCutOptimizerView()
                    .toolbar {
                        ToolbarItem(placement: .navigationBarTrailing) {
                            Button(t("Bitti", "Done")) { showCutPlanner = false }
                        }
                    }
            }
        }
        .sheet(isPresented: $showMultiBend) {
            NavigationStack {
                MultiBendPlannerView()
                    .toolbar {
                        ToolbarItem(placement: .navigationBarTrailing) {
                            Button(t("Bitti", "Done")) { showMultiBend = false }
                        }
                    }
            }
        }
        .sheet(isPresented: $showReference) {
            NavigationStack {
                BenderReferenceView()
                    .toolbar {
                        ToolbarItem(placement: .navigationBarTrailing) {
                            Button(t("Bitti", "Done")) { showReference = false }
                        }
                    }
            }
        }
        .sheet(isPresented: $showAR) {
            NavigationStack {
                ARMeasureView()
                    .toolbar {
                        ToolbarItem(placement: .navigationBarTrailing) {
                            Button(t("Bitti", "Done")) { showAR = false }
                        }
                    }
            }
        }
        .sheet(isPresented: $showPremium) {
            NavigationStack {
                SubscriptionView()
                    .toolbar {
                        ToolbarItem(placement: .navigationBarTrailing) {
                            Button(t("Bitti", "Done")) { showPremium = false }
                        }
                    }
            }
        }
        .sheet(isPresented: $showHistory) { ProjectHistoryView(history: history) }
        .sheet(isPresented: $showSettings) {
            NavigationStack {
                SettingsView()
                    .toolbar {
                        ToolbarItem(placement: .navigationBarTrailing) {
                            Button(t("Bitti", "Done")) { showSettings = false }
                        }
                    }
            }
        }
        .sheet(isPresented: $showDepthScan) {
            NavigationStack {
                DepthConduitScanView()
                    .toolbar {
                        ToolbarItem(placement: .navigationBarTrailing) {
                            Button(t("Bitti", "Done")) { showDepthScan = false }
                        }
                    }
            }
        }
        .sheet(isPresented: $showConduitScan) {
            NavigationStack {
                ConduitScanView()
                    .toolbar {
                        ToolbarItem(placement: .navigationBarTrailing) {
                            Button(t("Bitti", "Done")) { showConduitScan = false }
                        }
                    }
            }
        }
        .sheet(isPresented: $showCamera) {
            NavigationStack {
                CameraLevelView()
                    .toolbar { ToolbarItem(placement: .navigationBarTrailing) { Button(t("Bitti", "Done")) { showCamera = false } } }
            }
        }
    }
    private var homePage: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 20) {
                VStack(alignment: .leading, spacing: 6) {
                    Text("VisionBend Pro").font(.largeTitle.bold())
                    Text(t("Boru bükümünü üç adımda hesapla: işlem seç, ölçü gir, sonucu gör.", "Calculate bends in three steps: select, enter measurements, view result."))
                        .font(.subheadline).foregroundStyle(.secondary)
                }
                Text(t("Büküm Hesaplamaları", "Bend Calculators")).font(.title3.bold())
                LazyVGrid(columns: [GridItem(.flexible()), GridItem(.flexible())], spacing: 12) {
                    ForEach(names.indices, id: \.self) { i in
                        NavigationLink(value: i) {
                            VStack(alignment: .leading, spacing: 12) {
                                Image(systemName: ["arrow.up.right", "point.3.connected.trianglepath.dotted", "arrow.turn.up.right", "circle.dotted", "arrow.up.forward", "arrow.turn.up.right", "square.dashed", "angle"][i])
                                    .font(.title2).foregroundStyle(accent)
                                Text(t(bendNamesTR[i], names[i]))
                                    .font(.subheadline.bold()).foregroundStyle(.primary)
                                    .multilineTextAlignment(.leading)
                                Spacer(minLength: 0)
                                Image(systemName: "arrow.right").foregroundStyle(accent)
                            }
                            .frame(maxWidth: .infinity, minHeight: 115, alignment: .leading)
                            .padding(14)
                            .background(Color.secondary.opacity(0.09), in: RoundedRectangle(cornerRadius: 16))
                        }
                        .buttonStyle(.plain)
                    }
                }
                Text(t("Diğer Araçlar", "Other Tools")).font(.title3.bold())
                Button { selectedTab = 1 } label: {
                    Label(t("Kamera, AR ve LiDAR Ölçüm", "Camera, AR and LiDAR"), systemImage: "camera.viewfinder")
                        .frame(maxWidth: .infinity, alignment: .leading).padding()
                }
                .background(Color.secondary.opacity(0.09), in: RoundedRectangle(cornerRadius: 14))
                Button { selectedTab = 2 } label: {
                    Label(t("Çoklu Büküm ve Kesim Planlama", "Multi-bend and Cut Planning"), systemImage: "ruler")
                        .frame(maxWidth: .infinity, alignment: .leading).padding()
                }
                .background(Color.secondary.opacity(0.09), in: RoundedRectangle(cornerRadius: 14))
                Text(t("Ölçüleri sahada uygulamadan önce gerçek bükücü ile doğrulayın.", "Verify measurements with the physical bender before field use."))
                    .font(.footnote).foregroundStyle(.secondary)
            }
            .padding()
        }
        .tint(accent)
    }
    private var calculatorPage: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 18) {
                Text(t("Bükümünü seç ve hesapla", "Choose a bend and calculate"))
                    .font(.title2.bold())
                Text(t("1. Büküm türünü seç  2. Ölçüleri gir  3. Sonucu hesapla", "1. Choose bend  2. Enter measurements  3. Calculate"))
                    .font(.subheadline).foregroundStyle(.secondary)
                VStack(alignment: .leading, spacing: 12) {
                    Text(t("Büküm türü", "Bend type")).font(.headline)
                    Picker(t("Büküm türü", "Bend type"), selection: $mode) {
                        ForEach(names.indices, id: \.self) { i in
                            Text(t(bendNamesTR[i], names[i])).tag(i)
                        }
                    }
                    .pickerStyle(.menu)
                    .onChange(of: mode) { _ in
                        height = ""
                        angle = ""
                        output = ""
                        errorMessage = ""
                    }
                    Text(t("Önce bükümü seçin; yalnızca o büküme ait ölçüleri girin.",
                           "Select the bend first; enter only the measurements required for it."))
                        .font(.caption).foregroundStyle(.secondary)
                    Text(t("Seçilen işlem: ", "Selected: ") + t(bendNamesTR[selectedMode], names[selectedMode]))
                        .font(.subheadline.bold())
                        .foregroundStyle(accent)
                    Text(firstLabel + " (" + unitName + ")").font(.subheadline.bold())
                    TextField(firstLabel, text: $height).keyboardType(.decimalPad).textFieldStyle(.roundedBorder)
                        .onChange(of: height) { _ in output = ""; errorMessage = "" }
                    Text(secondLabel + ([4,5,7].contains(mode) ? " (" + unitName + ")" : ""))
                        .font(.subheadline.bold())
                    TextField(secondLabel, text: $angle).keyboardType(.decimalPad).textFieldStyle(.roundedBorder)
                        .onChange(of: angle) { _ in output = ""; errorMessage = "" }
                    Toggle(t("Kaydırıcı ile giriş", "Slider input"), isOn: $useSliders)
                        .font(.subheadline)
                    if useSliders && [0, 2, 3, 6].contains(mode) {
                        Slider(value: Binding(
                            get: { min(85, max(5, Double(angle.replacingOccurrences(of: ",", with: ".")) ?? 30)) },
                            set: { angle = String(format: "%.1f", $0) }),
                               in: 5...85, step: 1)
                        .accessibilityLabel(t("Büküm açısı kaydırıcısı", "Bend angle slider"))
                    }
                    if mode == 4 {
                        Text(t("Büküm açısı (derece)", "Bend angle (degrees)")).font(.subheadline.bold())
                        TextField(t("Örnek: 30", "Example: 30"), text: $rollingAngle)
                            .keyboardType(.decimalPad).textFieldStyle(.roundedBorder)
                            .onChange(of: rollingAngle) { _ in output = ""; errorMessage = "" }
                    }
                    if height.isEmpty || angle.isEmpty {
                        Label(t("Ölçüleri girin; QuickCheck girişleri kontrol edecek.",
                                "Enter measurements for QuickCheck."),
                              systemImage: "info.circle")
                            .foregroundStyle(.secondary).font(.caption)
                    } else if !calculatorNumericValid {
                        Label(t("QuickCheck: Geçersiz ölçü.", "QuickCheck: Invalid number."),
                              systemImage: "xmark.octagon.fill")
                            .foregroundStyle(.red).font(.caption)
                    } else {
                        Label(t("QuickCheck: Ölçüler sayısal olarak uygun. Bükücü kılavuzuyla doğrulayın.",
                                "QuickCheck: Numeric input valid. Confirm against bender manual."),
                              systemImage: "exclamationmark.triangle")
                            .foregroundStyle(.orange).font(.caption)
                    }
                    Button(action: calculate) {
                        Label(t("Hesapla", "Calculate"), systemImage: "equal")
                            .frame(maxWidth: .infinity).padding(.vertical, 8)
                    }.buttonStyle(.borderedProminent).tint(accent)
                }.padding().background(.regularMaterial, in: RoundedRectangle(cornerRadius: 16))
                if !errorMessage.isEmpty { Text(errorMessage).foregroundStyle(.red) }
                if !output.isEmpty {
                    VStack(alignment: .leading, spacing: 12) {
                        Text(t("Hesaplama sonucu", "Calculation result")).font(.headline)
                        bendDiagram
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
            Button { showAdvancedPatterns = true } label: { Label(t("Gelişmiş büküm çeşitleri", "Advanced bend patterns"), systemImage: "point.3.connected.trianglepath.dotted") }
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
                Button {
                    languageChosen = false
                } label: {
                    Label(VisionBendLanguages.name(for: language), systemImage: "globe")
                }
                Text(t("Dili değiştirmek için dokunun.", "Tap to change language."))
                    .font(.caption).foregroundStyle(.secondary)
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

    private var bendDiagram: some View {
        VStack(alignment: .leading, spacing: 6) {
            Text(t("Şematik büküm görünümü (ölçekli değildir)", "Schematic bend preview (not to scale)"))
                .font(.caption).foregroundStyle(.secondary)
            GeometryReader { geometry in
                Path { path in
                    let w = geometry.size.width
                    let h = geometry.size.height
                    path.move(to: CGPoint(x: 12, y: h * 0.72))
                    if mode == 3 {
                        path.addQuadCurve(to: CGPoint(x: w - 12, y: h * 0.3), control: CGPoint(x: w * 0.5, y: -h * 0.1))
                    } else if mode == 5 || mode == 7 {
                        path.addLine(to: CGPoint(x: w * 0.55, y: h * 0.72))
                        path.addLine(to: CGPoint(x: w * 0.55, y: h * 0.15))
                    } else {
                        path.addLine(to: CGPoint(x: w * 0.3, y: h * 0.72))
                        path.addLine(to: CGPoint(x: w * 0.53, y: h * 0.28))
                        path.addLine(to: CGPoint(x: w - 12, y: h * 0.28))
                    }
                }
                .stroke(accent, style: StrokeStyle(lineWidth: 7, lineCap: .round, lineJoin: .round))
            }
            .frame(height: 110)
            .padding(10)
            .background(Color.secondary.opacity(0.08), in: RoundedRectangle(cornerRadius: 12))
        }
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
                output = localizedFormat(t("İşaretler arası mesafe: %.2f %@\nTeorik kısalma: %.2f %@", "Mark spacing: %.2f %@\nTheoretical shrink: %.2f %@"), spacing, unitName, shrink, unitName)
            } else if mode == 1 {
                let distance = try BendCalculations.saddleOuterMarkDistance(height: rise, centerAngleDegrees: degrees)
                output = localizedFormat(t("Merkezden dış işarete: %.2f %@\nDış büküm açısı: %.1f°", "Center to outer mark: %.2f %@\nOuter bend angle: %.1f°"), distance, unitName, degrees / 2)
            } else if mode == 2 {
                let travel = try MoreBendCalculations.kickTravel(rise: rise, angleDegrees: degrees)
                output = localizedFormat(t("Kick yatay ilerleme: %.2f %@", "Kick horizontal travel: %.2f %@"), travel, unitName)
            } else if mode == 3 {
                let arc = try MoreBendCalculations.arcLength(centerlineRadius: rise, angleDegrees: degrees)
                output = localizedFormat(t("Merkez hattı yay uzunluğu: %.2f %@", "Centerline arc length: %.2f %@"), arc, unitName)
            } else if mode == 4 {
                let roll = try MoreBendCalculations.rollingOffset(horizontal: rise, vertical: degrees)
                guard let rollDegrees = Double(rollingAngle.replacingOccurrences(of: ",", with: ".")), rollDegrees.isFinite else {
                    errorMessage = t("Geçerli büküm açısı girin.", "Enter a valid bend angle.")
                    return
                }
                let spacing = try MoreBendCalculations.rollingOffsetMarkSpacing(horizontal: rise, vertical: degrees, angleDegrees: rollDegrees)
                let rotation = atan2(degrees, rise) * 180 / Double.pi
                output = localizedFormat(t("Çapraz kaçıklık: %.2f %@\nTeorik işaret aralığı: %.2f %@\nDönüş açısı: %.1f°", "True offset: %.2f %@\nTheoretical mark spacing: %.2f %@\nRoll angle: %.1f°"), roll, unitName, spacing, unitName, rotation)
            } else if mode == 5 {
                let mark = try ExtraBendCalculations.ninetyDegreeStubMark(desiredStub: rise, takeUp: degrees)
                output = localizedFormat(t("90° büküm işareti: %.2f %@", "90° stub mark: %.2f %@"), mark, unitName)
            } else if mode == 6 {
                let spacing = try ExtraBendCalculations.fourPointSaddleMarkSpacing(clearance: rise, bendAngleDegrees: degrees)
                output = localizedFormat(t("Her offset için işaret aralığı: %.2f %@", "Each offset mark spacing: %.2f %@"), spacing, unitName)
            } else if mode == 7 {
                let travel = try AdvancedBendCalculations.compoundNinetyTravel(firstLeg: rise, secondLeg: degrees)
                let rotation = try AdvancedBendCalculations.compoundNinetyRotation(firstLeg: rise, secondLeg: degrees)
                output = localizedFormat(t("Düzlemsel köşegen: %.2f %@\nYön açısı: %.1f°\nYalnızca geometri — gerçek büküm işaretleri için yarıçap, bükücü ve boru çapını doğrulayın.", "Planar diagonal: %.2f %@\nOrientation: %.1f°\nGeometry only — physical bend marks require verified radius, bender and conduit size."), travel, unitName, rotation)
            } else {
                errorMessage = t("Büküm türünü yeniden seçin.", "Unknown calculator mode. Select a mode again.")
            }
        } catch {
            errorMessage = t("Geçersiz ölçü veya büküm açısı. Ölçüleri kontrol edin.",
                             "Invalid dimensions or bend angle. Check your measurements.")
        }
        if units == 2, !output.isEmpty {
            output += "\n" + t("İlk ölçü (kesirli inç): ", "First value (fractional inches): ") + AdvancedBendCalculations.fractionalInches(rise)
        }
    }
}
