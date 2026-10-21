import SwiftUI
import WatchConnectivity

private enum WatchUIStrings {
    private static let keys = ["No synced project","Project","Send a plan from VisionBend on iPhone.","The latest received plan remains available offline.","Up","Down","Left","Right"]
    private static let rows: [String: [String]] = [
        "tr": ["Eşitlenmiş proje yok","Proje","iPhone'daki VisionBend uygulamasından bir plan gönderin.","Son alınan plan çevrimdışı kullanılabilir.","Yukarı","Aşağı","Sol","Sağ"],
        "es": ["Sin proyecto sincronizado","Proyecto","Envía un plan desde VisionBend en el iPhone.","El último plan recibido está disponible sin conexión.","Arriba","Abajo","Izquierda","Derecha"],
        "fr": ["Aucun projet synchronisé","Projet","Envoyez un plan depuis VisionBend sur iPhone.","Le dernier plan reçu reste disponible hors ligne.","Haut","Bas","Gauche","Droite"],
        "de": ["Kein synchronisiertes Projekt","Projekt","Sende einen Plan von VisionBend auf dem iPhone.","Der zuletzt empfangene Plan bleibt offline verfügbar.","Oben","Unten","Links","Rechts"],
        "ar": ["لا يوجد مشروع متزامن","مشروع","أرسل خطة من VisionBend على iPhone.","تبقى أحدث خطة مستلمة متاحة دون اتصال.","أعلى","أسفل","يسار","يمين"],
        "pt": ["Nenhum projeto sincronizado","Projeto","Envie um plano do VisionBend no iPhone.","O último plano recebido fica disponível offline.","Cima","Baixo","Esquerda","Direita"],
        "it": ["Nessun progetto sincronizzato","Progetto","Invia un piano da VisionBend su iPhone.","L'ultimo piano ricevuto resta disponibile offline.","Su","Giù","Sinistra","Destra"],
        "ru": ["Нет синхронизированного проекта","Проект","Отправьте план из VisionBend на iPhone.","Последний полученный план доступен без сети.","Вверх","Вниз","Влево","Вправо"],
        "fa": ["پروژه همگام‌سازی‌شده‌ای نیست","پروژه","از VisionBend در آیفون برنامه بفرستید.","آخرین برنامه دریافت‌شده آفلاین در دسترس است.","بالا","پایین","چپ","راست"],
        "hi": ["कोई सिंक प्रोजेक्ट नहीं","प्रोजेक्ट","iPhone पर VisionBend से योजना भेजें।","अंतिम प्राप्त योजना ऑफ़लाइन उपलब्ध रहती है।","ऊपर","नीचे","बाएँ","दाएँ"],
        "zh-Hans": ["没有已同步项目","项目","从 iPhone 的 VisionBend 发送计划。","最近收到的计划可离线查看。","向上","向下","左","右"],
        "zh-Hant": ["沒有已同步專案","專案","從 iPhone 的 VisionBend 傳送計畫。","最近收到的計畫可離線查看。","向上","向下","左","右"],
        "ja": ["同期されたプロジェクトなし","プロジェクト","iPhoneのVisionBendから計画を送信してください。","最後に受信した計画はオフラインでも利用できます。","上","下","左","右"],
        "ko": ["동기화된 프로젝트 없음","프로젝트","iPhone의 VisionBend에서 계획을 보내세요.","최근 받은 계획은 오프라인에서도 볼 수 있습니다.","위","아래","왼쪽","오른쪽"],
        "id": ["Belum ada proyek tersinkron","Proyek","Kirim rencana dari VisionBend di iPhone.","Rencana terakhir tetap tersedia secara offline.","Atas","Bawah","Kiri","Kanan"],
        "da": ["Intet synkroniseret projekt","Projekt","Send en plan fra VisionBend på iPhone.","Den senest modtagne plan er tilgængelig offline.","Op","Ned","Venstre","Højre"],
        "sv": ["Inget synkroniserat projekt","Projekt","Skicka en plan från VisionBend på iPhone.","Den senast mottagna planen finns tillgänglig offline.","Upp","Ned","Vänster","Höger"],
        "nl": ["Geen gesynchroniseerd project","Project","Verstuur een plan vanuit VisionBend op de iPhone.","Het laatst ontvangen plan blijft offline beschikbaar.","Omhoog","Omlaag","Links","Rechts"],
        "fi": ["Ei synkronoitua projektia","Projekti","Lähetä suunnitelma iPhonen VisionBendistä.","Viimeisin vastaanotettu suunnitelma on käytettävissä offline-tilassa.","Ylös","Alas","Vasen","Oikea"]
    ]
    static func text(_ key: String, language: String) -> String {
        let preference = language == "system" ? (Locale.preferredLanguages.first ?? "en") : language
        let code = preference.hasPrefix("zh-Hant") || preference.hasPrefix("zh-HK")
            ? "zh-Hant" : preference.hasPrefix("zh-Hans") ? "zh-Hans"
            : String(preference.split(separator: "-").first ?? "en")
        guard let index = keys.firstIndex(of: key),
              let translations = rows[code], translations.indices.contains(index)
        else { return key }
        return translations[index]
    }
}


final class WatchPlanStore: NSObject, ObservableObject, WCSessionDelegate {
    @Published var name = "No synced project"
    @Published var language = "system"
    @Published var units = ""
    @Published var marks: [String] = []

    override init() {
        super.init()
        restore()
        if WCSession.isSupported() {
            WCSession.default.delegate = self
            WCSession.default.activate()
        }
    }

    private func restore() {
        guard let payload = UserDefaults.standard.dictionary(forKey: "lastWatchPlan") else { return }
        apply(payload)
    }

    private func apply(_ payload: [String: Any]) {
        language = payload["language"] as? String ?? "system"
        name = payload["name"] as? String ?? "Project"
        units = payload["units"] as? String ?? ""
        let values = payload["marks"] as? [[String: Any]] ?? []
        marks = values.map { item in
            let position = item["position"] as? Double ?? 0
            let angle = item["angle"] as? Double ?? 0
            let direction = WatchUIStrings.text(item["direction"] as? String ?? "", language: language)
            return String(format: "%.2f %@ · %.1f° %@", position, units, angle, direction)
        }
    }

    func session(_ session: WCSession, didReceiveApplicationContext applicationContext: [String: Any]) {
        DispatchQueue.main.async {
            UserDefaults.standard.set(applicationContext, forKey: "lastWatchPlan")
            self.apply(applicationContext)
        }
    }

    func session(_ session: WCSession, activationDidCompleteWith state: WCSessionActivationState, error: Error?) {
        let context = session.receivedApplicationContext
        if !context.isEmpty {
            DispatchQueue.main.async {
                UserDefaults.standard.set(context, forKey: "lastWatchPlan")
                self.apply(context)
            }
        }
    }
}

@main
struct VisionBendWatchApp: App {
    var body: some Scene { WindowGroup { WatchMarksView() } }
}

struct WatchMarksView: View {
    @StateObject private var store = WatchPlanStore()
    private func l(_ key: String) -> String { WatchUIStrings.text(key, language: store.language) }
    var body: some View {
        NavigationStack {
            List {
                Section(l(store.name)) {
                    if store.marks.isEmpty { Text(l("Send a plan from VisionBend on iPhone.")) }
                    ForEach(store.marks, id: \.self) { Text($0).font(.caption) }
                }
                Text(l("The latest received plan remains available offline."))
                    .font(.caption2).foregroundStyle(.secondary)
            }
            .navigationTitle("VisionBend")
        }
    }
}
