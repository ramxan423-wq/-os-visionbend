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
    init(project: BendProjectExport) { self.project = project }
    init(configuration: ReadConfiguration) throws {
        project = try JSONDecoder().decode(BendProjectExport.self, from: configuration.file.regularFileContents ?? Data())
    }
    func fileWrapper(configuration: WriteConfiguration) throws -> FileWrapper {
        if configuration.contentType == .commaSeparatedText {
            let values = [project.title, project.mode, String(project.firstValue), String(project.secondValue), project.result, project.notes ?? ""]
            let escaped = values.map { "\"" + $0.replacingOccurrences(of: "\"", with: "\"\"").replacingOccurrences(of: "\n", with: " ") + "\"" }
            let csv = "Title,Mode,First,Second,Result,Notes\n" + escaped.joined(separator: ",")
            return FileWrapper(regularFileWithContents: Data(csv.utf8))
        }
        return FileWrapper(regularFileWithContents: try JSONEncoder().encode(project))
    }
}

struct ProjectExportView: View {
    let project: BendProjectExport
    @State private var exportJSON = false
    @State private var exportCSV = false
    var body: some View {
        VStack(spacing: 16) {
            Button("Export JSON") { exportJSON = true }
            Button("Export CSV") { exportCSV = true }
            ShareLink(item: project.title + "\n" + project.result) {
                Label("Share Project Summary", systemImage: "square.and.arrow.up")
            }
        }
        .padding()
        .fileExporter(isPresented: $exportJSON, document: BendExportDocument(project: project), contentType: .json, defaultFilename: "VisionBend-Project") { _ in }
        .fileExporter(isPresented: $exportCSV, document: BendExportDocument(project: project), contentType: .commaSeparatedText, defaultFilename: "VisionBend-Project") { _ in }
    }
}
