import Foundation

struct EventContentOverrideScaffold: Codable {
    let code: String
    let title: String?
    let summary: String?
    let overview: String?
    let primaryDocumentTitles: [String]
    let studyNotes: StudyNotesScaffold?
    let flashcardDeckTitle: String?
    let flashcardDeckSummary: String?
}

struct StudyNotesScaffold: Codable {
    let headline: String
    let summary: String?
    let sections: [StudyNotesSectionScaffold]
}

struct StudyNotesSectionScaffold: Codable {
    let title: String?
    let items: [StudyNotesItemScaffold]
}

struct StudyNotesItemScaffold: Codable {
    let text: String
    let children: [StudyNotesItemScaffold]?
}

let arguments = CommandLine.arguments.dropFirst()
guard let rawCode = arguments.first, !rawCode.isEmpty else {
    fputs("Usage: swift Tools/ScaffoldEventContentOverride.swift <EVENTCODE>\n", stderr)
    exit(1)
}

let code = rawCode.replacingOccurrences(of: " ", with: "")
let cwd = URL(fileURLWithPath: FileManager.default.currentDirectoryPath)
let outputURL = cwd
    .appendingPathComponent("Primary Gouge/AppContent/EventContentOverrides", isDirectory: true)
    .appendingPathComponent("\(code).json")

guard !FileManager.default.fileExists(atPath: outputURL.path) else {
    fputs("File already exists: \(outputURL.path)\n", stderr)
    exit(1)
}

try FileManager.default.createDirectory(at: outputURL.deletingLastPathComponent(), withIntermediateDirectories: true)

let scaffold = EventContentOverrideScaffold(
    code: code,
    title: nil,
    summary: nil,
    overview: nil,
    primaryDocumentTitles: [],
    studyNotes: StudyNotesScaffold(
        headline: "Discussion items",
        summary: nil,
        sections: [
            StudyNotesSectionScaffold(
                title: "Main discussion section",
                items: [
                    StudyNotesItemScaffold(
                        text: "Primary discussion item",
                        children: [
                            StudyNotesItemScaffold(text: "Nested discussion point", children: nil)
                        ]
                    )
                ]
            )
        ]
    ),
    flashcardDeckTitle: "\(code) Discussion Item Flashcards",
    flashcardDeckSummary: ""
)

let encoder = JSONEncoder()
encoder.outputFormatting = [.prettyPrinted, .sortedKeys]
let data = try encoder.encode(scaffold)
try data.write(to: outputURL)
print("Created \(outputURL.path)")
