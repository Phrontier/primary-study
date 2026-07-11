import Foundation
import PDFKit

enum SyllabusBuildError: LocalizedError {
    case message(String)

    var errorDescription: String? {
        switch self {
        case .message(let text):
            return text
        }
    }
}

enum SyllabusCategory: String, Codable, CaseIterable {
    case familiarization
    case instruments
    case navigation
    case formation
    case capstone

    var displayName: String {
        switch self {
        case .familiarization: return "Familiarization"
        case .instruments: return "Instruments"
        case .navigation: return "Navigation"
        case .formation: return "Formation"
        case .capstone: return "Capstone"
        }
    }
}

struct SyllabusEventReferenceFile: Codable {
    let track: String
    let sourceDocumentTitle: String
    let sourceDocumentDate: String
    let generatedAt: Date
    let aliases: [String: [String]]
    let events: [SyllabusEventReferenceRecord]
}

struct SyllabusEventReferenceRecord: Codable {
    let code: String
    let shortTitle: String
    let category: String
    let categoryDisplayName: String
    let media: String
    let eventKind: String
    let isCheckride: Bool
    let isSolo: Bool
    let blockCode: String
    let blockTitle: String
    let discussionItems: [String]
    let sourcePages: [Int]
    let mediaNotes: String?
    let legacyReviewAliases: [String]
    let sequence: Int
}

struct Block {
    let blockCode: String
    let category: SyllabusCategory
    let rawMedia: String
    let blockTitle: String
    let startPage: Int
    var endPage: Int
}

struct EventMediaOverride {
    let media: String
    let note: String?
}

struct EventOverrideTitle: Codable {
    let code: String
    let title: String?
}

enum ShortTitleSource {
    case override
    case generatedOverride
    case block
    case heading
    case discussion
}

struct ShortTitleDecision {
    var title: String
    let source: ShortTitleSource
    let fallbackDiscussionTitle: String?
    let eventKind: String
}

let generatedShortTitleOverrides: [String: String] = [
    "CS3102": "Advanced IMC Emergencies",
    "CS4101": "Capstone Maneuver and EP Flight 1",
    "CS4102": "Capstone Maneuver and EP Flight 2",
    "F2101": "Formation Arrival and Departure Procedures",
    "F3101": "Visual Signals and Formation Maneuvers",
    "FAM4203": "Oil and Propeller Systems",
    "FAM4301": "OBOGS and Pressurization System",
    "I2102": "IMC Emergencies",
    "I2202": "Arcing and Radial Intercepts",
    "I3101": "Clearance and Departure Procedures",
    "I4101": "CRM and Holding",
    "I4102": "ILS and LOC Approaches",
    "I4103": "PAR, ASR, and No-Gyro",
    "I4201": "Departure Procedures and Airway Navigation",
    "I4202": "FMS Arrivals",
    "I4203": "No-Gyro and Fuel Management",
    "I4204": "Takeoff and Alternate Minimums",
    "I4301": "Flight Planning and Jet Logs",
    "I4302": "En Route Weather and Circling",
    "I4303": "Airspace and Field Selection",
    "I4304": "Lost Communications and SID/STAR",
    "I6101": "Procedure Turns and Missed Approach",
    "I6102": "Arcing and Holding",
    "I6202": "En Route Weather Sources",
    "I6301": "EPs and NWCs"
]

let arguments = Array(CommandLine.arguments.dropFirst())
guard let rawPDFPath = arguments.first else {
    throw SyllabusBuildError.message("Usage: swift Tools/BuildSyllabusEventReference.swift <path-to-pdf> [output-json] [delta|echo]")
}

let requestedTrack = arguments.count > 2 ? arguments[2].lowercased() : "delta"
guard ["delta", "echo"].contains(requestedTrack) else {
    throw SyllabusBuildError.message("Track must be either delta or echo.")
}

let currentDirectory = URL(fileURLWithPath: FileManager.default.currentDirectoryPath)
let outputURL = arguments.count > 1
    ? URL(fileURLWithPath: arguments[1], relativeTo: currentDirectory).standardizedFileURL
    : currentDirectory.appendingPathComponent("Primary Gouge/AppContent/SyllabusEventReference.json")
let pdfURL = URL(fileURLWithPath: rawPDFPath)

guard let document = PDFDocument(url: pdfURL) else {
    throw SyllabusBuildError.message("Unable to open PDF at \(pdfURL.path)")
}

let blockHeaderRegex = try NSRegularExpression(
    pattern: #"^((?:FAM|I|N|F|CS)\d{2})\s+(CAI/MIL|Lect|UTD(?:/MR|/OFT|/ER)?|VTD|OFT|T-6B)\b(.*)$"#,
    options: []
)
let eventCodeRegex = try NSRegularExpression(
    pattern: #"^((?:FAM|I|N|F|CS)\d{4})$"#,
    options: []
)
let maneuverRegex = try NSRegularExpression(
    pattern: #"\bMANEUVER\s+((?:FAM|I|N|F|CS)\d{4})\b"#,
    options: []
)
let mediaOverrideRegex = try NSRegularExpression(
    pattern: #"((?:FAM|I|N|F|CS)\d{4}(?:-\d+)?)\s+(?:should|shall|may)\s+be\s+(?:conducted|flown)\s+.*?(UTD or UTD/ER|UTD/MR|UTD/ER|mixed reality UTD|UTD|VTD|OFT|T-6B)"#,
    options: [.caseInsensitive]
)

var pageLines: [[String]] = []
for index in 0..<document.pageCount {
    let pageText = document.page(at: index)?.string ?? ""
    let splitLines = pageText.components(separatedBy: .newlines)
    let trimmedLines = splitLines.map {
        $0.replacingOccurrences(of: "\t", with: " ").trimmingCharacters(in: .whitespacesAndNewlines)
    }
    let nonEmptyLines = trimmedLines.filter { !$0.isEmpty }
    let lines = nonEmptyLines.filter { line in
        line.range(of: #"^CNATRAINST 1542\.166[A-Z]$"#, options: .regularExpression) == nil
            && line.range(of: #"^\d{1,2} [A-Z][a-z]{2} \d{4}$"#, options: .regularExpression) == nil
            && line.range(of: #"^[IVXLC]+-\d+$"#, options: .regularExpression) == nil
            && line.range(of: #"^\d+$"#, options: .regularExpression) == nil
    }
    pageLines.append(lines)
}

var blocks: [Block] = []
for pageIndex in 0..<pageLines.count {
    let lines = pageLines[pageIndex]
    guard let headerIndex = lines.firstIndex(where: { $0.hasPrefix("Blk # Media Title Events Hrs") }) else {
        continue
    }

    guard headerIndex + 1 < lines.count else { continue }

    for lineIndex in (headerIndex + 1)..<min(lines.count, headerIndex + 8) {
        let line = lines[lineIndex]
        guard let match = firstMatch(in: line, regex: blockHeaderRegex) else { continue }

        let blockCode = match[1]
        guard let category = category(for: blockCode) else { continue }

        let rawMedia = match[2]
        let titleFragment = match[3].trimmingCharacters(in: .whitespacesAndNewlines)
        var titleParts = titleFragment.isEmpty ? [] : [titleFragment]
        var cursor = lineIndex + 1
        while cursor < lines.count {
            let candidate = lines[cursor]
            if candidate.hasPrefix("1. Prerequisites") || candidate.hasPrefix("2. Syllabus Notes") {
                break
            }
            if candidate.range(of: #"^\d+\s+\d+\.\d+(?:\s+\d+\.\d+)?$"#, options: .regularExpression) != nil {
                break
            }
            titleParts.append(candidate)
            cursor += 1
        }

        let title = titleParts
            .joined(separator: " ")
            .replacingOccurrences(of: #" +"#, with: " ", options: .regularExpression)
            .replacingOccurrences(of: #"\s+\d+\s+\d+\.\d+(?:\s+\d+\.\d+)?$"#, with: "", options: .regularExpression)
            .trimmingCharacters(in: .whitespacesAndNewlines)

        blocks.append(
            Block(
                blockCode: blockCode,
                category: category,
                rawMedia: rawMedia,
                blockTitle: title,
                startPage: pageIndex + 1,
                endPage: pageIndex + 1
            )
        )
        break
    }
}

blocks.sort { $0.startPage < $1.startPage }
for index in blocks.indices {
    if index < blocks.count - 1 {
        blocks[index].endPage = blocks[index + 1].startPage - 1
    } else {
        blocks[index].endPage = document.pageCount
    }
}

var records: [SyllabusEventReferenceRecord] = []
for block in blocks {
    let blockLines = (block.startPage...block.endPage).flatMap { pageLines[$0 - 1] }
    let blockText = blockLines.joined(separator: " ")
    let discussionExtraction = extractDiscussionLines(from: block, pageLines: pageLines)
    guard !discussionExtraction.lines.isEmpty else { continue }

    let explicitMedia = parseMediaOverrides(from: blockText, within: block)
    let groupedDiscussion = parseDiscussionGroups(
        block: block,
        discussionLines: discussionExtraction.lines,
        blockText: blockText,
        eventCodeRegex: eventCodeRegex,
        maneuverRegex: maneuverRegex
    )

    for (code, rawDiscussion) in groupedDiscussion {
        let mediaOverride = explicitMedia[code] ?? EventMediaOverride(
            media: canonicalMedia(from: block.rawMedia),
            note: mediaNote(for: block.rawMedia, canonicalMedia: canonicalMedia(from: block.rawMedia))
        )
        var discussionItems = normalizeDiscussionItems(from: rawDiscussion)
        if requestedTrack == "echo", code == "FAM4801", discussionItems.count == 1 {
            discussionItems = discussionItems[0]
                .components(separatedBy: ".")
                .map { $0.trimmingCharacters(in: .whitespacesAndNewlines) }
                .filter { !$0.isEmpty }
        }
        guard !discussionItems.isEmpty,
              !discussionItems.allSatisfy({ $0.caseInsensitiveCompare("none") == .orderedSame })
        else { continue }

        let isCheckride = code.hasSuffix("90")
        let isSolo = code == "FAM4501" || (requestedTrack == "echo" && code == "FAM4801")
            records.append(
                SyllabusEventReferenceRecord(
                    code: code,
                    shortTitle: code,
                    category: block.category.rawValue,
                    categoryDisplayName: block.category.displayName,
                    media: mediaOverride.media,
                eventKind: eventKind(for: mediaOverride.media),
                isCheckride: isCheckride,
                isSolo: isSolo,
                blockCode: block.blockCode,
                blockTitle: block.blockTitle,
                discussionItems: discussionItems,
                sourcePages: discussionExtraction.sourcePages,
                mediaNotes: mediaOverride.note,
                    legacyReviewAliases: legacyAliases(for: code, block: block, isCheckride: isCheckride),
                    sequence: records.count
            )
        )
    }
}

let uniqueCodes = Set(records.map(\.code))
guard uniqueCodes.count == records.count else {
    throw SyllabusBuildError.message("Duplicate event codes detected while building syllabus reference.")
}

let requiredCodes = requestedTrack == "echo"
    ? ["FAM1301", "FAM2101", "FAM2105", "F1201", "N4102", "I4490", "F4290", "FAM4501"]
    : ["FAM2101", "FAM2202", "F2101", "N4101", "I4490", "F4290", "CS4290", "FAM4501"]
for code in requiredCodes {
    guard records.contains(where: { $0.code == code }) else {
        throw SyllabusBuildError.message("Missing required syllabus event \(code).")
    }
}

let overrideTitles = loadOverrideTitles(
    from: currentDirectory.appendingPathComponent("Primary Gouge/AppContent/EventContentOverrides", isDirectory: true)
)
let sourceFilesByCode = loadSourceFilesByCode(
    under: currentDirectory.appendingPathComponent("Contents", isDirectory: true)
)
records = applyShortTitles(
    to: records,
    overrideTitles: overrideTitles,
    sourceFilesByCode: sourceFilesByCode
)

let file = SyllabusEventReferenceFile(
    track: requestedTrack,
    sourceDocumentTitle: requestedTrack == "echo"
        ? "CNATRAINST 1542.166E T-6B Joint Primary Pilot Training (JPT) Curriculum"
        : "CNATRAINST 1542.166D T-6B Joint Primary Pilot Training (JPPT) Curriculum",
    sourceDocumentDate: requestedTrack == "echo" ? "2026-04-24" : "2024-07-15",
    generatedAt: Date(),
    aliases: [
        "familiarization": ["fam", "fams", "familiarization", "contacts"],
        "instruments": ["i", "ins", "instrument", "instruments"],
        "navigation": ["n", "nav", "navigation", "navaigation"],
        "formation": ["f", "form", "forms", "formation"],
        "capstone": ["cs", "capstone"]
    ],
    events: records
)

let encoder = JSONEncoder()
encoder.dateEncodingStrategy = .iso8601
encoder.outputFormatting = [.prettyPrinted, .sortedKeys]
let data = try encoder.encode(file)
try data.write(to: outputURL)
print("Wrote \(records.count) events to \(outputURL.path)")

func category(for blockCode: String) -> SyllabusCategory? {
    if blockCode.hasPrefix("FAM") { return .familiarization }
    if blockCode.hasPrefix("CS") { return .capstone }
    if blockCode.hasPrefix("I") { return .instruments }
    if blockCode.hasPrefix("N") { return .navigation }
    if blockCode.hasPrefix("F") { return .formation }
    return nil
}

func firstMatch(in text: String, regex: NSRegularExpression) -> [String]? {
    let range = NSRange(text.startIndex..., in: text)
    guard let match = regex.firstMatch(in: text, options: [], range: range) else {
        return nil
    }

    return (0..<match.numberOfRanges).compactMap { index in
        guard let range = Range(match.range(at: index), in: text) else { return nil }
        return String(text[range])
    }
}

func extractDiscussionLines(from block: Block, pageLines: [[String]]) -> (lines: [String], sourcePages: [Int]) {
    var capturedLines: [String] = []
    var sourcePages: [Int] = []
    var isCapturing = false

    for pageNumber in block.startPage...block.endPage {
        let lines = pageLines[pageNumber - 1]
        var appendedLineOnPage = false

        for line in lines {
            if !isCapturing {
                guard let range = line.range(of: "4. Discuss Items") else { continue }
                isCapturing = true
                let remainder = String(line[range.upperBound...])
                    .trimmingCharacters(in: CharacterSet(charactersIn: ".: "))
                if !remainder.isEmpty {
                    capturedLines.append(remainder)
                    appendedLineOnPage = true
                }
                continue
            }

            if line.hasPrefix("5. Block MIF") {
                if appendedLineOnPage && !sourcePages.contains(pageNumber) {
                    sourcePages.append(pageNumber)
                }
                return (capturedLines, sourcePages)
            }

            capturedLines.append(line)
            appendedLineOnPage = true
        }

        if isCapturing && appendedLineOnPage && !sourcePages.contains(pageNumber) {
            sourcePages.append(pageNumber)
        }
    }

    return (capturedLines, sourcePages)
}

func parseDiscussionGroups(
    block: Block,
    discussionLines: [String],
    blockText: String,
    eventCodeRegex: NSRegularExpression,
    maneuverRegex: NSRegularExpression
) -> [(String, String)] {
    var grouped: [(String, String)] = []
    var currentCode: String?
    var currentLines: [String] = []

    for line in discussionLines {
        let normalizedLine = line.trimmingCharacters(in: .whitespacesAndNewlines)
        if let match = firstMatch(in: normalizedLine, regex: eventCodeRegex) {
            if let currentCode, !currentLines.isEmpty {
                grouped.append((currentCode, currentLines.joined(separator: " ")))
            }
            currentCode = match[1]
            currentLines = []
            continue
        }

        guard !normalizedLine.isEmpty else { continue }
        currentLines.append(normalizedLine)
    }

    if let currentCode, !currentLines.isEmpty {
        grouped.append((currentCode, currentLines.joined(separator: " ")))
    }

    if !grouped.isEmpty {
        return grouped
    }

    let singleCode = singleEventCode(for: block, blockText: blockText, maneuverRegex: maneuverRegex)
    return [(singleCode, discussionLines.joined(separator: " "))]
}

func singleEventCode(for block: Block, blockText: String, maneuverRegex: NSRegularExpression) -> String {
    if let match = firstMatch(in: blockText, regex: maneuverRegex) {
        return match[1]
    }

    if block.blockCode.hasSuffix("44") || block.blockCode.hasSuffix("42") || block.blockCode.hasSuffix("11") {
        return block.blockCode + "90"
    }

    return block.blockCode + "01"
}

func parseMediaOverrides(from blockText: String, within block: Block) -> [String: EventMediaOverride] {
    let textRange = NSRange(blockText.startIndex..., in: blockText)
    let matches = mediaOverrideRegex.matches(in: blockText, options: [], range: textRange)
    var overrides: [String: EventMediaOverride] = [:]

    for match in matches {
        guard
            let codeRange = Range(match.range(at: 1), in: blockText),
            let mediaRange = Range(match.range(at: 2), in: blockText)
        else {
            continue
        }

        let codeToken = String(blockText[codeRange])
        let rawMedia = String(blockText[mediaRange])
        let media = canonicalMedia(from: rawMedia)
        let note = mediaNote(for: rawMedia, canonicalMedia: media)

        for code in expandedCodes(from: codeToken, within: block.blockCode) {
            overrides[code] = EventMediaOverride(media: media, note: note)
        }
    }

    return overrides
}

func expandedCodes(from token: String, within blockCode: String) -> [String] {
    let normalized = token.uppercased()
    if let range = normalized.range(of: "-") {
        let left = String(normalized[..<range.lowerBound])
        let right = String(normalized[range.upperBound...])
        guard
            let leftNumber = Int(left.suffix(1)),
            let rightNumber = Int(right)
        else {
            return [normalized]
        }

        let prefix = String(left.dropLast())
        return (leftNumber...rightNumber).map { "\(prefix)\($0)" }
    }

    return [normalized]
}

func canonicalMedia(from rawMedia: String) -> String {
    let normalized = rawMedia.lowercased()
    if normalized.contains("lect") || normalized.contains("cai/mil") {
        return "Ground School"
    }
    if normalized.contains("mixed reality utd") || normalized.contains("utd/mr") {
        return "UTD/MR"
    }
    if normalized.contains("utd") {
        return "UTD"
    }
    if normalized.contains("vtd") {
        return "VTD"
    }
    if normalized.contains("oft") {
        return "OFT"
    }
    return "T-6B"
}

func mediaNote(for rawMedia: String, canonicalMedia: String) -> String? {
    let normalizedRaw = rawMedia
        .replacingOccurrences(of: #" +"#, with: " ", options: .regularExpression)
        .trimmingCharacters(in: .whitespacesAndNewlines)
    return normalizedRaw.caseInsensitiveCompare(canonicalMedia) == .orderedSame ? nil : normalizedRaw
}

func eventKind(for media: String) -> String {
    if media == "Ground School" { return "groundSchool" }
    return media == "T-6B" ? "flight" : "sim"
}

func normalizeDiscussionItems(from rawDiscussion: String) -> [String] {
    let normalized = rawDiscussion
        .replacingOccurrences(of: #"\s+"#, with: " ", options: .regularExpression)
        .replacingOccurrences(of: ", and ", with: ", ")
        .replacingOccurrences(of: ", or ", with: ", ")
        .trimmingCharacters(in: CharacterSet(charactersIn: ". "))

    guard !normalized.isEmpty else { return [] }

    var commaSplitItems: [String] = []
    var current = ""
    var depth = 0

    for character in normalized {
        if character == "(" {
            depth += 1
        } else if character == ")" && depth > 0 {
            depth -= 1
        }

        if (character == "," || character == ";") && depth == 0 {
            let item = current.trimmingCharacters(in: .whitespacesAndNewlines)
            if !item.isEmpty {
                commaSplitItems.append(item)
            }
            current = ""
            continue
        }

        current.append(character)
    }

    let finalItem = current.trimmingCharacters(in: .whitespacesAndNewlines)
    if !finalItem.isEmpty {
        commaSplitItems.append(finalItem)
    }

    return commaSplitItems.enumerated().map { index, item in
        var cleaned = item
            .replacingOccurrences(of: #"^\."#, with: "", options: .regularExpression)
            .trimmingCharacters(in: CharacterSet(charactersIn: ". "))
        cleaned = cleaned.replacingOccurrences(of: #"^(?:and|or)\s+"#, with: "", options: [.regularExpression, .caseInsensitive])
        if index == 0 {
            cleaned = cleaned.replacingOccurrences(of: #"^Discuss\s+"#, with: "", options: [.regularExpression, .caseInsensitive])
        }
        return cleaned
    }
}

func legacyAliases(for code: String, block: Block, isCheckride: Bool) -> [String] {
    if code == "FAM4490" {
        return ["FAM4401"]
    }

    if isCheckride && block.blockCode == "CS42" {
        return ["CS4201"]
    }

    return []
}

func loadOverrideTitles(from url: URL) -> [String: String] {
    guard let files = try? FileManager.default.contentsOfDirectory(at: url, includingPropertiesForKeys: nil) else {
        return [:]
    }

    let decoder = JSONDecoder()
    var results: [String: String] = [:]

    for fileURL in files where fileURL.pathExtension.lowercased() == "json" {
        guard
            let data = try? Data(contentsOf: fileURL),
            let override = try? decoder.decode(EventOverrideTitle.self, from: data),
            let title = override.title?.trimmingCharacters(in: .whitespacesAndNewlines),
            !title.isEmpty
        else {
            continue
        }

        results[normalizeCode(override.code)] = title
    }

    return results
}

func loadSourceFilesByCode(under rootURL: URL) -> [String: [URL]] {
    guard let enumerator = FileManager.default.enumerator(at: rootURL, includingPropertiesForKeys: nil) else {
        return [:]
    }

    var grouped: [String: [URL]] = [:]
    while let item = enumerator.nextObject() as? URL {
        var isDirectory: ObjCBool = false
        guard FileManager.default.fileExists(atPath: item.path, isDirectory: &isDirectory), !isDirectory.boolValue else {
            continue
        }
        guard let code = eventCode(fromFilename: item.lastPathComponent) else {
            continue
        }
        grouped[code, default: []].append(item)
    }

    return grouped
}

func eventCode(fromFilename filename: String) -> String? {
    guard let range = filename.range(of: #"(?:FAM|I|N|F|CS)\s?\d{4}"#, options: .regularExpression) else {
        return nil
    }
    return normalizeCode(String(filename[range]))
}

func applyShortTitles(
    to records: [SyllabusEventReferenceRecord],
    overrideTitles: [String: String],
    sourceFilesByCode: [String: [URL]]
) -> [SyllabusEventReferenceRecord] {
    var decisions: [String: ShortTitleDecision] = [:]

    for record in records {
        decisions[record.code] = decideShortTitle(
            for: record,
            overrideTitles: overrideTitles,
            sourceFilesByCode: sourceFilesByCode
        )
    }

    resolveDuplicateShortTitles(in: &decisions, records: records)

    return records.map { record in
        SyllabusEventReferenceRecord(
            code: record.code,
            shortTitle: decisions[record.code]?.title ?? record.code,
            category: record.category,
            categoryDisplayName: record.categoryDisplayName,
            media: record.media,
            eventKind: record.eventKind,
            isCheckride: record.isCheckride,
            isSolo: record.isSolo,
            blockCode: record.blockCode,
            blockTitle: record.blockTitle,
            discussionItems: record.discussionItems,
            sourcePages: record.sourcePages,
            mediaNotes: record.mediaNotes,
            legacyReviewAliases: record.legacyReviewAliases,
            sequence: record.sequence
        )
    }
}

func decideShortTitle(
    for record: SyllabusEventReferenceRecord,
    overrideTitles: [String: String],
    sourceFilesByCode: [String: [URL]]
) -> ShortTitleDecision {
    if let overrideTitle = overrideTitles[record.code] {
        return ShortTitleDecision(
            title: overrideTitle,
            source: .override,
            fallbackDiscussionTitle: normalizedDiscussionTitle(from: record.discussionItems),
            eventKind: record.eventKind
        )
    }

    if let generatedTitle = generatedShortTitleOverrides[record.code] {
        return ShortTitleDecision(
            title: generatedTitle,
            source: .generatedOverride,
            fallbackDiscussionTitle: normalizedDiscussionTitle(from: record.discussionItems),
            eventKind: record.eventKind
        )
    }

    if record.isCheckride || record.isSolo {
        return ShortTitleDecision(
            title: cleanedShortTitle(record.blockTitle),
            source: .block,
            fallbackDiscussionTitle: normalizedDiscussionTitle(from: record.discussionItems),
            eventKind: record.eventKind
        )
    }

    if let headingTitle = sourceHeadingTitle(for: record, sourceFilesByCode: sourceFilesByCode) {
        return ShortTitleDecision(
            title: headingTitle,
            source: .heading,
            fallbackDiscussionTitle: normalizedDiscussionTitle(from: record.discussionItems),
            eventKind: record.eventKind
        )
    }

    if let discussionTitle = normalizedDiscussionTitle(from: record.discussionItems) {
        return ShortTitleDecision(
            title: discussionTitle,
            source: .discussion,
            fallbackDiscussionTitle: discussionTitle,
            eventKind: record.eventKind
        )
    }

    return ShortTitleDecision(
        title: cleanedShortTitle(record.blockTitle),
        source: .block,
        fallbackDiscussionTitle: nil,
        eventKind: record.eventKind
    )
}

func sourceHeadingTitle(
    for record: SyllabusEventReferenceRecord,
    sourceFilesByCode: [String: [URL]]
) -> String? {
    let files = prioritizedSourceFiles(for: sourceFilesByCode[record.code] ?? [])
    for file in files {
        guard let text = extractText(from: file) else { continue }
        guard let title = extractHeadingTitle(from: text, code: record.code) else { continue }
        let cleaned = cleanedShortTitle(title)
        guard cleaned.caseInsensitiveCompare(record.code) != .orderedSame else { continue }
        return cleaned
    }
    return nil
}

func prioritizedSourceFiles(for files: [URL]) -> [URL] {
    files.sorted { lhs, rhs in
        let lhsRank = sourcePriority(for: lhs)
        let rhsRank = sourcePriority(for: rhs)
        if lhsRank == rhsRank {
            return lhs.lastPathComponent < rhs.lastPathComponent
        }
        return lhsRank < rhsRank
    }
}

func sourcePriority(for file: URL) -> Int {
    let name = file.lastPathComponent.lowercased()
    let ext = file.pathExtension.lowercased()
    if name.contains("briefing guide") { return 0 }
    if ext == "docx" || ext == "doc" { return 1 }
    if ext == "pdf" { return 2 }
    return 3
}

func extractText(from file: URL) -> String? {
    let ext = file.pathExtension.lowercased()
    if ext == "docx" || ext == "doc" {
        let process = Process()
        process.executableURL = URL(fileURLWithPath: "/usr/bin/textutil")
        process.arguments = ["-convert", "txt", "-stdout", file.path]
        let pipe = Pipe()
        process.standardOutput = pipe
        process.standardError = Pipe()

        do {
            try process.run()
            process.waitUntilExit()
            guard process.terminationStatus == 0 else { return nil }
            let data = pipe.fileHandleForReading.readDataToEndOfFile()
            return String(decoding: data, as: UTF8.self)
        } catch {
            return nil
        }
    }

    if ext == "pdf", let document = PDFDocument(url: file) {
        return document.string
    }

    return nil
}

func extractHeadingTitle(from text: String, code: String) -> String? {
    let lines = text
        .components(separatedBy: .newlines)
        .map { $0.trimmingCharacters(in: .whitespacesAndNewlines) }
        .filter { !$0.isEmpty }

    guard !lines.isEmpty else { return nil }

    for line in lines.prefix(12) {
        let normalizedLine = line.replacingOccurrences(of: "\t", with: " ")
        if normalizedLine.hasPrefix(code + ":") || normalizedLine.hasPrefix(code + " -") {
            let title = normalizedLine
                .replacingOccurrences(of: code + ":", with: "")
                .replacingOccurrences(of: code + " -", with: "")
                .trimmingCharacters(in: .whitespacesAndNewlines)
            if let candidate = preferredShortTitleCandidate(from: title) {
                return candidate
            }
        }
    }

    if lines.first == code {
        for line in lines.dropFirst().prefix(16) {
            if let candidate = preferredShortTitleCandidate(from: line) {
                return candidate
            }
        }
    }

    return nil
}

func normalizedDiscussionTitle(from discussionItems: [String]) -> String? {
    for item in discussionItems {
        if let candidate = preferredShortTitleCandidate(from: item) {
            return candidate
        }
    }

    return nil
}

func preferredShortTitleCandidate(from rawValue: String) -> String? {
    let stripped = rawValue
        .replacingOccurrences(of: "\t", with: " ")
        .replacingOccurrences(of: #"^[•\-]\s*"#, with: "", options: .regularExpression)
        .replacingOccurrences(of: #"^\d+[\.\)]\s*"#, with: "", options: .regularExpression)
        .components(separatedBy: CharacterSet(charactersIn: ":,;("))
        .first?
        .trimmingCharacters(in: .whitespacesAndNewlines) ?? rawValue

    guard !stripped.isEmpty else { return nil }
    guard !isWeakShortTitleCandidate(stripped) else { return nil }

    let cleaned = cleanedShortTitle(stripped)
    guard !cleaned.isEmpty else { return nil }
    guard cleaned.caseInsensitiveCompare("N/A") != .orderedSame else { return nil }
    return cleaned
}

func isWeakShortTitleCandidate(_ value: String) -> Bool {
    let normalized = value
        .lowercased()
        .replacingOccurrences(of: #"\s+"#, with: " ", options: .regularExpression)
        .trimmingCharacters(in: .whitespacesAndNewlines)

    let weakExactMatches: Set<String> = [
        "discuss items",
        "discuss items:",
        "syllabus notes",
        "syllabus notes:",
        "special syllabus requirements",
        "special syllabus requirements:",
        "ssrs",
        "n/a",
        "type",
        "description",
        "purpose",
        "general"
    ]

    if weakExactMatches.contains(normalized) {
        return true
    }

    return normalized.hasPrefix("any ")
        || normalized.hasPrefix("per the ")
        || normalized.hasPrefix("definition")
        || normalized.hasPrefix("objective")
        || normalized.hasPrefix("requirement")
}

func cleanedShortTitle(_ value: String) -> String {
    var title = value
        .replacingOccurrences(of: #"\s+"#, with: " ", options: .regularExpression)
        .trimmingCharacters(in: .whitespacesAndNewlines)
        .lowercased()
        .localizedCapitalized

    let replacements: [(String, String)] = [
        (#"\bAnd\b"#, "and"),
        (#"\bOr\b"#, "or"),
        (#"\bOf\b"#, "of"),
        (#"\bIn\b"#, "in"),
        (#"\bOn\b"#, "on"),
        (#"\bFor\b"#, "for"),
        (#"\bFrom\b"#, "from"),
        (#"\bTo\b"#, "to"),
        (#"\bThe\b"#, "the"),
        (#"\bA\b"#, "a"),
        (#"\bAn\b"#, "an"),
        (#"\bWith\b"#, "with"),
        (#"\bAsr\b"#, "ASR"),
        (#"\bBfi\b"#, "BFI"),
        (#"\bCnaf\b"#, "CNAF"),
        (#"\bCrm\b"#, "CRM"),
        (#"\bEp\b"#, "EP"),
        (#"\bEps\b"#, "EPs"),
        (#"\bFms\b"#, "FMS"),
        (#"\bGca\b"#, "GCA"),
        (#"\bGps\b"#, "GPS"),
        (#"\bHilo\b"#, "HILO"),
        (#"\bHsi\b"#, "HSI"),
        (#"\bPel/P\b"#, "PEL/P"),
        (#"\bPel\b"#, "PEL"),
        (#"\bElp\b"#, "ELP"),
        (#"\bEnroute\b"#, "En Route"),
        (#"\bVfr\b"#, "VFR"),
        (#"\bIfr\b"#, "IFR"),
        (#"\bAim\b"#, "AIM"),
        (#"\bLoc\b"#, "LOC"),
        (#"\bNatops\b"#, "NATOPS"),
        (#"\bNwc\b"#, "NWC"),
        (#"\bNwcs\b"#, "NWCs"),
        (#"\bOcf\b"#, "OCF"),
        (#"\bOlf\b"#, "OLF"),
        (#"\bRdo\b"#, "RDO"),
        (#"\bRvfac\b"#, "RVFAC"),
        (#"\bSid/Star\b"#, "SID/STAR"),
        (#"\bSid\b"#, "SID"),
        (#"\bStar\b"#, "STAR"),
        (#"\bTrsa\b"#, "TRSA"),
        (#"\bCfs\b"#, "CFS"),
        (#"\bObogs\b"#, "OBOGS"),
        (#"\bHud\b"#, "HUD"),
        (#"\bHefoe\b"#, "HEFOE"),
        (#"\bPmu\b"#, "PMU"),
        (#"\bPar\b"#, "PAR"),
        (#"\bDd-1801\b"#, "DD-1801"),
        (#"\bT-6b\b"#, "T-6B"),
        (#"\bVn\b"#, "VN"),
        (#"\bVor\b"#, "VOR")
    ]

    for replacement in replacements {
        title = title.replacingOccurrences(
            of: replacement.0,
            with: replacement.1,
            options: [.regularExpression]
        )
    }

    if title == "Day Navigation" {
        return "Day Navigation"
    }

    return title
}

func resolveDuplicateShortTitles(
    in decisions: inout [String: ShortTitleDecision],
    records: [SyllabusEventReferenceRecord]
) {
    var titlesToCodes = Dictionary(grouping: records.map(\.code)) { code in
        decisions[code]?.title ?? code
    }

    for (_, codes) in titlesToCodes where codes.count > 1 {
        for code in codes {
            guard var decision = decisions[code] else { continue }
            guard decision.source != .override else { continue }
            if decision.eventKind == "sim", let discussionTitle = decision.fallbackDiscussionTitle, discussionTitle != decision.title {
                decision.title = discussionTitle
                decisions[code] = decision
            }
        }
    }

    titlesToCodes = Dictionary(grouping: records.map(\.code)) { code in
        decisions[code]?.title ?? code
    }

    for (_, codes) in titlesToCodes where codes.count > 1 {
        for code in codes.sorted() {
            guard var decision = decisions[code] else { continue }
            guard decision.source != .override else { continue }
            let suffix = decision.eventKind == "flight" ? " Flight" : " Sim"
            decision.title += suffix
            decisions[code] = decision
        }
    }
}

extension ComparisonResult {
    var isOrderedSame: Bool {
        self == .orderedSame
    }
}

func normalizeCode(_ value: String) -> String {
    value.replacingOccurrences(of: " ", with: "")
}
