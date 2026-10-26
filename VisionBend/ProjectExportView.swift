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
    // CSV is export-only. Importing CSV as JSON would fail, so do not advertise it as readable.
    static var readableContentTypes: [UTType] { [.json] }
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
    @State private var showExportError = false
    @State private var exportErrorMessage = ""
    var body: some View {
        VStack(spacing: 16) {
            Button("Export JSON") { exportJSON = true }
            Button("Export CSV") { exportCSV = true }
            ShareLink(item: project.title + "\n" + project.result) {
                Label("Share Project Summary", systemImage: "square.and.arrow.up")
            }
        }
        .padding()
        .fileExporter(isPresented: $exportJSON, document: BendExportDocument(project: project), contentType: .json, defaultFilename: "VisionBend-Project") { result in
            reportExportError(result)
        }
        .fileExporter(isPresented: $exportCSV, document: BendExportDocument(project: project), contentType: .commaSeparatedText, defaultFilename: "VisionBend-Project") { result in
            reportExportError(result)
        }
        .alert("Export could not be completed", isPresented: $showExportError) {
            Button("OK", role: .cancel) {}
        } message: {
            Text(exportErrorMessage)
        }
    }

    private func reportExportError(_ result: Result<URL, Error>) {
        if case .failure(let error) = result {
            exportErrorMessage = error.localizedDescription
            showExportError = true
        }
    }
}
