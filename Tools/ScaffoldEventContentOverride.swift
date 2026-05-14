import Foundation

struct EventContentOverrideScaffold: Codable {
    let code: String
    let title: String?
    let summary: String?
    let overview: String?
    let canonicalCoverage: [String: [String]]?
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

struct SyllabusEventReferenceFile: Codable {
    let events: [SyllabusEventReferenceEventRecord]
}

struct SyllabusEventReferenceEventRecord: Codable {
    let code: String
    let shortTitle: String
    let discussionItems: [String]
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
let syllabusReferenceURL = cwd.appendingPathComponent("Primary Gouge/AppContent/SyllabusEventReference.json")

guard !FileManager.default.fileExists(atPath: outputURL.path) else {
    fputs("File already exists: \(outputURL.path)\n", stderr)
    exit(1)
}

try FileManager.default.createDirectory(at: outputURL.deletingLastPathComponent(), withIntermediateDirectories: true)

let referenceEvent: SyllabusEventReferenceEventRecord?
if let data = try? Data(contentsOf: syllabusReferenceURL) {
    let decoder = JSONDecoder()
    decoder.dateDecodingStrategy = .iso8601
    if let file = try? decoder.decode(SyllabusEventReferenceFile.self, from: data) {
        referenceEvent = file.events.first { $0.code.replacingOccurrences(of: " ", with: "") == code }
    } else {
        referenceEvent = nil
    }
} else {
    referenceEvent = nil
}

let requiredProcedureItems = referenceEvent?.discussionItems ?? ["Primary discussion item"]
let requiredProcedureSection = StudyNotesSectionScaffold(
    title: "Required Procedures",
    items: requiredProcedureItems.map { StudyNotesItemScaffold(text: $0, children: nil) }
)
let canonicalCoverage = Dictionary(uniqueKeysWithValues: requiredProcedureItems.map { ($0, [$0]) })
let generatedTitle = referenceEvent?.shortTitle

let scaffold = EventContentOverrideScaffold(
    code: code,
    title: generatedTitle,
    summary: nil,
    overview: nil,
    canonicalCoverage: canonicalCoverage,
    primaryDocumentTitles: [],
    studyNotes: StudyNotesScaffold(
        headline: "Discussion items",
        summary: nil,
        sections: [
            StudyNotesSectionScaffold(
                title: generatedTitle ?? "Primary Study Section",
                items: [
                    StudyNotesItemScaffold(
                        text: "Use an event-meaningful section title and a short lead bullet that orients the student to what this part of the brief is trying to accomplish.",
                        children: [
                            StudyNotesItemScaffold(text: "Prefer a few high-value bullets over a rigid template.", children: nil),
                            StudyNotesItemScaffold(text: "Group related syllabus items when that improves readability, then track the coverage in canonicalCoverage.", children: nil),
                            StudyNotesItemScaffold(text: "Keep only the numbers, cautions, and procedural details that help the student brief and execute the event cleanly.", children: nil)
                        ]
                    )
                ]
            ),
            requiredProcedureSection
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
