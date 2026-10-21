import SwiftUI
import UniformTypeIdentifiers

struct BendProjectExport: Codable {
    let title: String
    let mode: String
    let firstValue: Double
    let secondValue: Double
    let result: String
    let notes: String?
}

struct BendExportDocument: FileDocument {
    static var readableContentTypes: [UTType] { [.json, .commaSeparatedText] }
    static var writableContentTypes: [UTType] { [.json, .commaSeparatedText] }
    var project: BendProjectExport
    var language: String
    init(project: BendProjectExport, language: String = "en") { self.project = project; self.language = language }
    init(configuration: ReadConfiguration) throws {
        language = "en"
        project = try JSONDecoder().decode(BendProjectExport.self, from: configuration.file.regularFileContents ?? Data())
    }
    func fileWrapper(configuration: WriteConfiguration) throws -> FileWrapper {
        if configuration.contentType == .commaSeparatedText {
            let values = [project.title, project.mode, String(project.firstValue), String(project.secondValue), project.result, project.notes ?? ""]
            let escaped = values.map { "\"" + $0.replacingOccurrences(of: "\"", with: "\"\"").replacingOccurrences(of: "\n", with: " ") + "\"" }
            let fields = ["Title", "Mode", "First", "Second", "Result", "Notes"]
            let localizedHeaders = fields.map { VisionBendLocalization.text($0, language: language) }
            let csv = localizedHeaders.joined(separator: ",") + "\n" + escaped.joined(separator: ",")
            return FileWrapper(regularFileWithContents: Data(csv.utf8))
        }
        return FileWrapper(regularFileWithContents: try JSONEncoder().encode(project))
    }
}

struct ProjectExportView: View {
    let project: BendProjectExport
    @AppStorage("visionbend.language") private var language = "system"
    private func l(_ key: String) -> String { VisionBendLocalization.text(key, language: language) }
    @State private var exportJSON = false
    @State private var exportCSV = false
    var body: some View {
        VStack(spacing: 16) {
            Button(l("Export JSON")) { exportJSON = true }
            Button(l("Export CSV")) { exportCSV = true }
            ShareLink(item: project.title + "\n" + project.result) {
                Label(l("Share Project Summary"), systemImage: "square.and.arrow.up")
            }
        }
        .padding()
        .fileExporter(isPresented: $exportJSON, document: BendExportDocument(project: project, language: language), contentType: .json, defaultFilename: "VisionBend-Project") { _ in }
        .fileExporter(isPresented: $exportCSV, document: BendExportDocument(project: project, language: language), contentType: .commaSeparatedText, defaultFilename: "VisionBend-Project") { _ in }
    }
}
