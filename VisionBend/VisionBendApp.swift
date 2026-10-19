import SwiftUI

@main
struct VisionBendApp: App {
    @AppStorage("visionbend.languageChosen") private var languageChosen = false
    var body: some Scene {
        WindowGroup {
            Group {
                if languageChosen {
                    ContentView()
                } else {
                    LanguageSelectionView()
                }
            }
        }
    }
}
