import Foundation

/// Shared localized UI strings. Missing translations fall back to English,
/// rather than claiming unsupported languages are fully translated.
enum VisionBendLocalization {
    static let strings: [String: [String: String]] = [
        "Home": ["tr":"Ana Sayfa","es":"Inicio","fr":"Accueil","de":"Startseite","pt":"Início","it":"Home","ar":"الرئيسية","fa":"خانه","ru":"Главная","hi":"होम","zh-Hans":"首页","ja":"ホーム","ko":"홈","id":"Beranda"],
        "Camera": ["tr":"Kamera","es":"Cámara","fr":"Caméra","de":"Kamera","pt":"Câmera","it":"Fotocamera","ar":"الكاميرا","fa":"دوربین","ru":"Камера","hi":"कैमरा","zh-Hans":"相机","ja":"カメラ","ko":"카메라","id":"Kamera"],
        "Planning": ["tr":"Planlama","es":"Planificación","fr":"Planification","de":"Planung","pt":"Planejamento","it":"Pianificazione","ar":"التخطيط","fa":"برنامه‌ریزی","ru":"Планирование","hi":"योजना","zh-Hans":"规划","ja":"計画","ko":"계획","id":"Perencanaan"],
        "Plan": ["tr":"Plan","es":"Plan","fr":"Plan","de":"Plan","pt":"Plano","it":"Piano","ar":"الخطة","fa":"طرح","ru":"План","hi":"योजना","zh-Hans":"计划","ja":"計画","ko":"계획","id":"Rencana"],
        "Projects": ["tr":"Projeler","es":"Proyectos","fr":"Projets","de":"Projekte","pt":"Projetos","it":"Progetti","ar":"المشاريع","fa":"پروژه‌ها","ru":"Проекты","hi":"परियोजनाएँ","zh-Hans":"项目","ja":"プロジェクト","ko":"프로젝트","id":"Proyek"],
        "Settings": ["tr":"Ayarlar","es":"Ajustes","fr":"Paramètres","de":"Einstellungen","pt":"Configurações","it":"Impostazioni","ar":"الإعدادات","fa":"تنظیمات","ru":"Настройки","hi":"सेटिंग्स","zh-Hans":"设置","ja":"設定","ko":"설정","id":"Pengaturan"],
        "Calculate": ["tr":"Hesapla","es":"Calcular","fr":"Calculer","de":"Berechnen","pt":"Calcular","it":"Calcola","ar":"احسب","fa":"محاسبه","ru":"Рассчитать","hi":"गणना करें","zh-Hans":"计算","ja":"計算","ko":"계산","id":"Hitung"],
        "Calculation result": ["tr":"Hesaplama sonucu","es":"Resultado del cálculo","fr":"Résultat du calcul","de":"Berechnungsergebnis","pt":"Resultado do cálculo","it":"Risultato del calcolo","ar":"نتيجة الحساب","fa":"نتیجه محاسبه","ru":"Результат расчёта","hi":"गणना परिणाम","zh-Hans":"计算结果","ja":"計算結果","ko":"계산 결과","id":"Hasil perhitungan"],
        "Save Calculation": ["tr":"Hesaplamayı Kaydet","es":"Guardar cálculo","fr":"Enregistrer le calcul","de":"Berechnung speichern","pt":"Salvar cálculo","it":"Salva calcolo","ar":"حفظ الحساب","fa":"ذخیره محاسبه","ru":"Сохранить расчёт","hi":"गणना सहेजें","zh-Hans":"保存计算","ja":"計算を保存","ko":"계산 저장","id":"Simpan perhitungan"],
        "Bend type": ["tr":"Büküm türü","es":"Tipo de curva","fr":"Type de cintrage","de":"Biegeart","pt":"Tipo de dobra","it":"Tipo di piega","ar":"نوع الثني","fa":"نوع خم","ru":"Тип изгиба","hi":"मोड़ का प्रकार","zh-Hans":"弯曲类型","ja":"曲げの種類","ko":"굽힘 유형","id":"Jenis tekukan"],
        "Bend angle (degrees)": ["tr":"Büküm açısı (derece)","es":"Ángulo de doblado (grados)","fr":"Angle de cintrage (degrés)","de":"Biegewinkel (Grad)","pt":"Ângulo de dobra (graus)","it":"Angolo di piega (gradi)","ar":"زاوية الثني (درجة)","fa":"زاویه خم (درجه)","ru":"Угол изгиба (градусы)","hi":"मोड़ कोण (डिग्री)","zh-Hans":"弯曲角度（度）","ja":"曲げ角度（度）","ko":"굽힘 각도(도)","id":"Sudut tekuk (derajat)"],
        "Appearance": ["tr":"Görünüm","es":"Apariencia","fr":"Apparence","de":"Darstellung","pt":"Aparência","it":"Aspetto","ar":"المظهر","fa":"ظاهر","ru":"Внешний вид","hi":"दिखावट","zh-Hans":"外观","ja":"外観","ko":"모양","id":"Tampilan"],
        "Language": ["tr":"Dil","es":"Idioma","fr":"Langue","de":"Sprache","pt":"Idioma","it":"Lingua","ar":"اللغة","fa":"زبان","ru":"Язык","hi":"भाषा","zh-Hans":"语言","ja":"言語","ko":"언어","id":"Bahasa"],
        "Continue": ["tr":"Devam Et","es":"Continuar","fr":"Continuer","de":"Weiter","pt":"Continuar","it":"Continua","ar":"متابعة","fa":"ادامه","ru":"Продолжить","hi":"जारी रखें","zh-Hans":"继续","ja":"続ける","ko":"계속","id":"Lanjutkan"],
        "Choose your language": ["tr":"Dilini seç","es":"Elige tu idioma","fr":"Choisissez votre langue","de":"Sprache auswählen","pt":"Escolha seu idioma","it":"Scegli la tua lingua","ar":"اختر لغتك","fa":"زبان خود را انتخاب کنید","ru":"Выберите язык","hi":"अपनी भाषा चुनें","zh-Hans":"选择语言","ja":"言語を選択","ko":"언어 선택","id":"Pilih bahasa"],
        "Search language": ["tr":"Dil ara","es":"Buscar idioma","fr":"Rechercher une langue","de":"Sprache suchen","pt":"Buscar idioma","it":"Cerca lingua","ar":"ابحث عن لغة","fa":"جستجوی زبان","ru":"Поиск языка","hi":"भाषा खोजें","zh-Hans":"搜索语言","ja":"言語を検索","ko":"언어 검색","id":"Cari bahasa"]
    ]

    static func text(_ english: String, turkish: String? = nil, language: String) -> String {
        let code = language == "system" ? (Locale.preferredLanguages.first ?? "en") : language
        let normalized = code == "zh-Hans" ? code : String(code.split(separator: "-").first ?? "en")
        if let translated = strings[english]?[code] ?? strings[english]?[normalized] {
            return translated
        }
        return normalized == "tr" ? (turkish ?? english) : english
    }
}
