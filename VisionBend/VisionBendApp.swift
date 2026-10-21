import SwiftUI

@main
struct VisionBendApp: App {
    @AppStorage("visionbend.languageChosen") private var languageChosen = false
    @AppStorage("visionbend.language") private var language = "system"
    private var currentLanguageSupported: Bool {
        language == "system" || VisionBendLanguages.supported.contains(where: { $0.code == language })
    }
    var body: some Scene {
        WindowGroup {
            Group {
                if languageChosen && currentLanguageSupported {
                    ContentView()
                } else {
                    LanguageSelectionView()
                }
            }
        }
    }
}
