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
    let sourceDocumentTitle: String
    let sourceDocumentDate: String
    let generatedAt: Date
    let aliases: [String: [String]]
    let events: [SyllabusEventReferenceRecord]
}

struct SyllabusEventReferenceRecord: Codable {
    let code: String
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

let arguments = CommandLine.arguments.dropFirst()
guard let rawPDFPath = arguments.first else {
    throw SyllabusBuildError.message("Usage: swift Tools/BuildSyllabusEventReference.swift <path-to-pdf>")
}

let currentDirectory = URL(fileURLWithPath: FileManager.default.currentDirectoryPath)
let outputURL = currentDirectory
    .appendingPathComponent("Primary Gouge/AppContent/SyllabusEventReference.json")
let pdfURL = URL(fileURLWithPath: rawPDFPath)

guard let document = PDFDocument(url: pdfURL) else {
    throw SyllabusBuildError.message("Unable to open PDF at \(pdfURL.path)")
}

let blockHeaderRegex = try NSRegularExpression(
    pattern: #"^((?:FAM|I|N|F|CS)\d{2})\s+(UTD(?:/MR|/OFT|/ER)?|VTD|OFT|T-6B)\b(.*)$"#,
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
        line != "CNATRAINST 1542.166D"
            && line != "15 Jul 2024"
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
        let discussionItems = normalizeDiscussionItems(from: rawDiscussion)
        guard !discussionItems.isEmpty else { continue }

        let isCheckride = code.hasSuffix("90")
        let isSolo = code == "FAM4501"
        records.append(
            SyllabusEventReferenceRecord(
                code: code,
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
                legacyReviewAliases: legacyAliases(for: code, block: block, isCheckride: isCheckride)
            )
        )
    }
}

records.sort { lhs, rhs in
    if lhs.category == rhs.category {
        return lhs.code < rhs.code
    }
    return lhs.category < rhs.category
}

let uniqueCodes = Set(records.map(\.code))
guard uniqueCodes.count == records.count else {
    throw SyllabusBuildError.message("Duplicate event codes detected while building syllabus reference.")
}

let requiredCodes = ["FAM2101", "FAM2202", "F2101", "N4101", "I4490", "F4290", "CS4290", "FAM4501"]
for code in requiredCodes {
    guard records.contains(where: { $0.code == code }) else {
        throw SyllabusBuildError.message("Missing required syllabus event \(code).")
    }
}

let file = SyllabusEventReferenceFile(
    sourceDocumentTitle: "CNATRAINST 1542.166D T-6B Joint Primary Pilot Training (JPPT) Curriculum",
    sourceDocumentDate: "2024-07-15",
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
    media == "T-6B" ? "flight" : "sim"
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

        if character == "," && depth == 0 {
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

    return commaSplitItems.map { item in
        item
            .replacingOccurrences(of: #"^\."#, with: "", options: .regularExpression)
            .trimmingCharacters(in: CharacterSet(charactersIn: ". "))
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
