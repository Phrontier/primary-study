import Foundation

enum StudyCategoryKind: String, Codable, Comparable {
    case groundSchool
    case sims
    case flights

    static func < (lhs: StudyCategoryKind, rhs: StudyCategoryKind) -> Bool {
        rank(lhs) < rank(rhs)
    }

    private static func rank(_ kind: StudyCategoryKind) -> Int {
        switch kind {
        case .groundSchool: 0
        case .sims: 1
        case .flights: 2
        }
    }
}

enum FlashcardKind: String, Codable {
    case standard
    case ep
}

enum FlashcardFilterToken: String, Codable, CaseIterable {
    case ep
    case limits
    case nwc

    var tagValue: String { rawValue }
}

struct LegacyFlashcardLibraryFile: Codable {
    let flashcards: [LegacyFlashcardDefinition]
}

struct LegacyFlashcardDefinition: Codable {
    let id: String
    let prompt: String
    let answer: String
    let tags: [String]
    let kind: FlashcardKind
    let requiresVerbatim: Bool
    let companionGroupID: String?
}

struct UnifiedFlashcardLibraryFile: Codable {
    let flashcards: [UnifiedFlashcardDefinition]
}

struct UnifiedFlashcardDefinition: Codable {
    let id: String
    let prompt: String
    let answer: String
    let tags: [String]
    let studyCategories: [StudyCategoryKind]
    let eventCodes: [String]
    let kind: FlashcardKind
    let requiresVerbatim: Bool
    let companionGroupID: String?
}

struct FlashcardDeckMappingFile: Codable {
    let eventDecks: [EventDeckMapping]
}

struct EventDeckMapping: Codable {
    let eventCode: String
    let decks: [DeckMapping]
}

struct DeckMapping: Codable {
    let cardIDs: [String]
}

struct ReferenceStudyConfigFile: Codable {
    let eventDeckReplacements: [ReferenceEventDeckReplacement]
}

struct ReferenceEventDeckReplacement: Codable {
    let eventCode: String
    let selections: [ReferenceDeckSelection]
}

struct ReferenceDeckSelection: Codable {
    let filter: FlashcardFilterToken
    let title: String?
    let includeAll: Bool?
    let includeCompanionNWC: Bool?
}

struct MinimalManifest: Codable {
    let phases: [MinimalPhase]
}

struct MinimalPhase: Codable {
    let categories: [MinimalCategory]
}

struct MinimalCategory: Codable {
    let kind: StudyCategoryKind
    let events: [MinimalEvent]
}

struct MinimalEvent: Codable {
    let code: String
}

let fileManager = FileManager.default
let cwd = URL(fileURLWithPath: fileManager.currentDirectoryPath)

let flashcardLibraryURL = cwd.appendingPathComponent("Primary Gouge/AppContent/FlashcardLibrary.json")
let flashcardBackupURL = cwd.appendingPathComponent("Primary Gouge/AppContent/FlashcardLibrary.legacy.json")
let deckMappingsURL = cwd.appendingPathComponent("Primary Gouge/AppContent/FlashcardDeckMappings.json")
let referenceConfigURL = cwd.appendingPathComponent("Primary Gouge/AppContent/ReferenceStudyConfig.json")
let manifestURL = cwd.appendingPathComponent("Primary Gouge/AppContent/StudyManifest.json")
let xmlDirectoryURL = cwd.appendingPathComponent("Primary Gouge/AppContent/XMLSources", isDirectory: true)

let decoder = JSONDecoder()
let encoder = JSONEncoder()
encoder.outputFormatting = [.prettyPrinted, .sortedKeys, .withoutEscapingSlashes]

let legacyLibrary = try decoder.decode(LegacyFlashcardLibraryFile.self, from: Data(contentsOf: flashcardLibraryURL))
let deckMappings = try decoder.decode(FlashcardDeckMappingFile.self, from: Data(contentsOf: deckMappingsURL))
let referenceConfig = try decoder.decode(ReferenceStudyConfigFile.self, from: Data(contentsOf: referenceConfigURL))
let manifest = try decoder.decode(MinimalManifest.self, from: Data(contentsOf: manifestURL))

let eventCategoryMap = Dictionary(uniqueKeysWithValues: manifest.phases
    .flatMap(\.categories)
    .flatMap { category in
        category.events.map { (normalizeCode($0.code), category.kind) }
    })

var cardToEventCodes: [String: Set<String>] = [:]
for eventDeck in deckMappings.eventDecks {
    let eventCode = normalizeCode(eventDeck.eventCode)
    for deck in eventDeck.decks {
        for cardID in deck.cardIDs {
            cardToEventCodes[cardID, default: []].insert(eventCode)
        }
    }
}

let epCards = try parseCanonicalReferenceDeck(
    fileURL: xmlDirectoryURL.appendingPathComponent("T-6 EP's.xml"),
    filter: .ep,
    epGroupIDs: [:]
)
let epGroupIDs: [String: String] = Dictionary(uniqueKeysWithValues: epCards.compactMap { card in
    guard let group = card.companionGroupID else { return nil }
    return (group, group)
})
let limitCards = try parseCanonicalReferenceDeck(
    fileURL: xmlDirectoryURL.appendingPathComponent("T-6 Limits.xml"),
    filter: .limits,
    epGroupIDs: [:]
)
let nwcCards = try parseCanonicalReferenceDeck(
    fileURL: xmlDirectoryURL.appendingPathComponent("EP's N_W_C.xml"),
    filter: .nwc,
    epGroupIDs: epGroupIDs
)

let canonicalCards = epCards + limitCards + nwcCards
var canonicalEventAssignments: [String: Set<String>] = [:]

for replacement in referenceConfig.eventDeckReplacements {
    let eventCode = normalizeCode(replacement.eventCode)
    let selectedIDs = resolveReferenceSelections(replacement.selections, cards: canonicalCards)
    for cardID in selectedIDs {
        canonicalEventAssignments[cardID, default: []].insert(eventCode)
    }
}

let unifiedLegacyCards = legacyLibrary.flashcards
    .filter { !isLegacyReferenceCard($0) }
    .map { card in
        let eventCodes = sortedEventCodes(cardToEventCodes[card.id] ?? [])
        return UnifiedFlashcardDefinition(
            id: card.id,
            prompt: card.prompt,
            answer: card.answer,
            tags: dedupe(card.tags),
            studyCategories: studyCategories(for: eventCodes, eventCategoryMap: eventCategoryMap),
            eventCodes: eventCodes,
            kind: card.kind,
            requiresVerbatim: card.requiresVerbatim,
            companionGroupID: card.companionGroupID
        )
    }

let unifiedCanonicalCards = canonicalCards.map { card in
    let eventCodes = sortedEventCodes(canonicalEventAssignments[card.id] ?? [])
    return UnifiedFlashcardDefinition(
        id: card.id,
        prompt: card.prompt,
        answer: card.answer,
        tags: dedupe(card.tags),
        studyCategories: studyCategories(for: eventCodes, eventCategoryMap: eventCategoryMap),
        eventCodes: eventCodes,
        kind: card.kind,
        requiresVerbatim: card.requiresVerbatim,
        companionGroupID: card.companionGroupID
    )
}

let unifiedCards = (unifiedLegacyCards + unifiedCanonicalCards)
    .sorted {
        let promptCompare = $0.prompt.localizedCaseInsensitiveCompare($1.prompt)
        if promptCompare != .orderedSame {
            return promptCompare == .orderedAscending
        }
        return $0.id < $1.id
    }

if !fileManager.fileExists(atPath: flashcardBackupURL.path) {
    try fileManager.copyItem(at: flashcardLibraryURL, to: flashcardBackupURL)
}

let data = try encoder.encode(UnifiedFlashcardLibraryFile(flashcards: unifiedCards))
try data.write(to: flashcardLibraryURL, options: Data.WritingOptions.atomic)

print("Wrote unified flashcard library with \(unifiedCards.count) cards.")
print("Backup preserved at \(flashcardBackupURL.path).")

private func sortedEventCodes(_ eventCodes: Set<String>) -> [String] {
    eventCodes.sorted()
}

private func studyCategories(for eventCodes: [String], eventCategoryMap: [String: StudyCategoryKind]) -> [StudyCategoryKind] {
    Array(Set(eventCodes.compactMap { eventCategoryMap[normalizeCode($0)] })).sorted()
}

private func parseCanonicalReferenceDeck(
    fileURL: URL,
    filter: FlashcardFilterToken,
    epGroupIDs: [String: String]
) throws -> [LegacyFlashcardDefinition] {
    let text = try String(contentsOf: fileURL, encoding: .utf8)
    let cardBlocks = regexMatches(for: #"<card>(.*?)</card>"#, in: text)

    return cardBlocks.compactMap { cardXML in
        guard let frontRaw = firstRegexMatch(for: #"<rich-text name='Front'>(.*?)</rich-text>"#, in: cardXML),
              let backRaw = firstRegexMatch(for: #"<rich-text name='Back'>(.*?)</rich-text>"#, in: cardXML) else {
            return nil
        }

        let prompt = normalizedRichText(from: frontRaw)
        let answer = normalizedRichText(from: backRaw)
        guard !prompt.isEmpty, !answer.isEmpty else { return nil }

        let groupID = normalizeReferenceTitle(prompt)
        let companionGroupID: String?
        switch filter {
        case .ep:
            companionGroupID = groupID
        case .nwc:
            companionGroupID = epGroupIDs[groupID]
        case .limits:
            companionGroupID = nil
        }

        return LegacyFlashcardDefinition(
            id: canonicalReferenceCardID(filter: filter, title: prompt),
            prompt: prompt,
            answer: answer,
            tags: [filter.tagValue],
            kind: filter == .ep ? .ep : .standard,
            requiresVerbatim: filter == .ep,
            companionGroupID: companionGroupID
        )
    }
}

private func resolveReferenceSelections(_ selections: [ReferenceDeckSelection], cards: [LegacyFlashcardDefinition]) -> [String] {
    var resolved: [String] = []

    for selection in selections {
        let matchingCards = cards.filter { $0.tags.contains(selection.filter.tagValue) }

        if selection.includeAll == true {
            resolved.append(contentsOf: matchingCards.map(\.id))
            continue
        }

        guard let title = selection.title else { continue }
        let normalizedTitle = normalizeReferenceTitle(title)

        switch selection.filter {
        case .ep:
            if let epCard = matchingCards.first(where: { normalizeReferenceTitle($0.prompt) == normalizedTitle }) {
                resolved.append(epCard.id)
                if selection.includeCompanionNWC ?? true {
                    let companions = cards
                        .filter { $0.tags.contains(FlashcardFilterToken.nwc.tagValue) && $0.companionGroupID == epCard.companionGroupID }
                        .map(\.id)
                    resolved.append(contentsOf: companions)
                }
            }
        case .limits, .nwc:
            resolved.append(contentsOf: matchingCards.filter { normalizeReferenceTitle($0.prompt) == normalizedTitle }.map(\.id))
        }
    }

    return dedupe(resolved)
}

private func normalizedRichText(from rawXML: String) -> String {
    var rendered = rawXML
        .replacingOccurrences(of: "<br/>", with: "\n")
        .replacingOccurrences(of: "<br />", with: "\n")
        .replacingOccurrences(of: "</p>", with: "\n")
        .replacingOccurrences(of: "<p>", with: "")
        .replacingOccurrences(of: "<ol>", with: "")
        .replacingOccurrences(of: "</ol>", with: "\n")
        .replacingOccurrences(of: "<ul>", with: "")
        .replacingOccurrences(of: "</ul>", with: "\n")
        .replacingOccurrences(of: "<li>", with: "- ")
        .replacingOccurrences(of: "</li>", with: "\n")
        .replacingOccurrences(of: "&lt;", with: "<")
        .replacingOccurrences(of: "&gt;", with: ">")
        .replacingOccurrences(of: "&amp;", with: "&")
        .replacingOccurrences(of: "&quot;", with: "\"")
        .replacingOccurrences(of: "&#39;", with: "'")

    rendered = rendered.replacingOccurrences(of: #"<[^>]+>"#, with: "", options: .regularExpression)
    let lines = rendered
        .components(separatedBy: .newlines)
        .map { $0.replacingOccurrences(of: "\u{00A0}", with: " ") }
        .map { $0.replacingOccurrences(of: #"\s+"#, with: " ", options: .regularExpression) }
        .map { $0.trimmingCharacters(in: .whitespacesAndNewlines) }
        .filter { !$0.isEmpty }

    return lines.joined(separator: "\n")
}

private func canonicalReferenceCardID(filter: FlashcardFilterToken, title: String) -> String {
    sanitizeID("reference-\(filter.rawValue)-\(title)")
}

private func normalizeReferenceTitle(_ title: String) -> String {
    title
        .lowercased()
        .replacingOccurrences(of: "&amp;", with: "and")
        .replacingOccurrences(of: "&", with: "and")
        .replacingOccurrences(of: "/", with: " ")
        .replacingOccurrences(of: #"[^\p{L}\p{N}]+"#, with: " ", options: .regularExpression)
        .replacingOccurrences(of: #"\s+"#, with: " ", options: .regularExpression)
        .trimmingCharacters(in: .whitespacesAndNewlines)
}

private func isLegacyReferenceCard(_ card: LegacyFlashcardDefinition) -> Bool {
    let prompt = card.prompt.lowercased()
    let answer = card.answer.lowercased()

    if prompt.contains("n/w/c") || prompt == "warning" || prompt == "caution" || prompt == "note" || prompt == "n/w/cs:" || prompt == "n/w/cs" {
        return true
    }

    if prompt.range(of: #"^\*?\s*\d+\."#, options: .regularExpression) != nil {
        return true
    }

    let referenceSignals = [
        "immediate airstart",
        "emergency ground egress",
        "chip detector warning",
        "forced landing",
        "obogs failure",
        "emergency engine shutdown",
        "fire in flight",
        "high fuel flow",
        "low fuel pressure",
        "abort start procedure",
        "compressor stalls",
        "inadvertent departure",
        "precautionary emergency landing",
        "oil system malfunction",
        "engine failure during flight",
        "engine failure immediately after takeoff",
        "uncommanded power changes",
        "eject",
        "limits"
    ]

    return referenceSignals.contains { signal in
        prompt.contains(signal) || answer.contains(signal)
    }
}

private func dedupe(_ values: [String]) -> [String] {
    var seen = Set<String>()
    return values.filter { seen.insert($0).inserted }
}

private func regexMatches(for pattern: String, in text: String) -> [String] {
    guard let regex = try? NSRegularExpression(pattern: pattern, options: [.dotMatchesLineSeparators]) else {
        return []
    }

    let range = NSRange(text.startIndex..., in: text)
    return regex.matches(in: text, range: range).compactMap { match in
        guard match.numberOfRanges > 1, let swiftRange = Range(match.range(at: 1), in: text) else { return nil }
        return String(text[swiftRange])
    }
}

private func firstRegexMatch(for pattern: String, in text: String) -> String? {
    regexMatches(for: pattern, in: text).first
}

private func normalizeCode(_ code: String) -> String {
    code.replacingOccurrences(of: " ", with: "").uppercased()
}

private func sanitizeID(_ raw: String) -> String {
    let simplified = raw
        .folding(options: .diacriticInsensitive, locale: .current)
        .lowercased()
        .replacingOccurrences(of: #"[^\p{L}\p{N}]+"#, with: "-", options: .regularExpression)
        .trimmingCharacters(in: CharacterSet(charactersIn: "-"))

    let digest = SHA256.hash(data: Data(raw.utf8)).map { String(format: "%02x", $0) }.joined().prefix(10)
    return simplified + "-" + digest
}

private enum SHA256 {
    static func hash(data: Data) -> [UInt8] {
        let message = Array(data)
        let messageLengthBits = UInt64(message.count * 8)

        var tmp = message
        tmp.append(0x80)
        while (tmp.count % 64) != 56 {
            tmp.append(0x00)
        }

        tmp.append(contentsOf: withUnsafeBytes(of: messageLengthBits.bigEndian, Array.init))

        var h0: UInt32 = 0x6a09e667
        var h1: UInt32 = 0xbb67ae85
        var h2: UInt32 = 0x3c6ef372
        var h3: UInt32 = 0xa54ff53a
        var h4: UInt32 = 0x510e527f
        var h5: UInt32 = 0x9b05688c
        var h6: UInt32 = 0x1f83d9ab
        var h7: UInt32 = 0x5be0cd19

        let k: [UInt32] = [
            0x428a2f98, 0x71374491, 0xb5c0fbcf, 0xe9b5dba5, 0x3956c25b, 0x59f111f1, 0x923f82a4, 0xab1c5ed5,
            0xd807aa98, 0x12835b01, 0x243185be, 0x550c7dc3, 0x72be5d74, 0x80deb1fe, 0x9bdc06a7, 0xc19bf174,
            0xe49b69c1, 0xefbe4786, 0x0fc19dc6, 0x240ca1cc, 0x2de92c6f, 0x4a7484aa, 0x5cb0a9dc, 0x76f988da,
            0x983e5152, 0xa831c66d, 0xb00327c8, 0xbf597fc7, 0xc6e00bf3, 0xd5a79147, 0x06ca6351, 0x14292967,
            0x27b70a85, 0x2e1b2138, 0x4d2c6dfc, 0x53380d13, 0x650a7354, 0x766a0abb, 0x81c2c92e, 0x92722c85,
            0xa2bfe8a1, 0xa81a664b, 0xc24b8b70, 0xc76c51a3, 0xd192e819, 0xd6990624, 0xf40e3585, 0x106aa070,
            0x19a4c116, 0x1e376c08, 0x2748774c, 0x34b0bcb5, 0x391c0cb3, 0x4ed8aa4a, 0x5b9cca4f, 0x682e6ff3,
            0x748f82ee, 0x78a5636f, 0x84c87814, 0x8cc70208, 0x90befffa, 0xa4506ceb, 0xbef9a3f7, 0xc67178f2
        ]

        for chunkStart in stride(from: 0, to: tmp.count, by: 64) {
            let chunk = Array(tmp[chunkStart..<(chunkStart + 64)])
            var w = Array(repeating: UInt32(0), count: 64)

            for i in 0..<16 {
                let j = i * 4
                w[i] = (UInt32(chunk[j]) << 24) | (UInt32(chunk[j + 1]) << 16) | (UInt32(chunk[j + 2]) << 8) | UInt32(chunk[j + 3])
            }

            for i in 16..<64 {
                let s0 = rotateRight(w[i - 15], by: 7) ^ rotateRight(w[i - 15], by: 18) ^ (w[i - 15] >> 3)
                let s1 = rotateRight(w[i - 2], by: 17) ^ rotateRight(w[i - 2], by: 19) ^ (w[i - 2] >> 10)
                w[i] = w[i - 16] &+ s0 &+ w[i - 7] &+ s1
            }

            var a = h0
            var b = h1
            var c = h2
            var d = h3
            var e = h4
            var f = h5
            var g = h6
            var h = h7

            for i in 0..<64 {
                let s1 = rotateRight(e, by: 6) ^ rotateRight(e, by: 11) ^ rotateRight(e, by: 25)
                let ch = (e & f) ^ ((~e) & g)
                let temp1 = h &+ s1 &+ ch &+ k[i] &+ w[i]
                let s0 = rotateRight(a, by: 2) ^ rotateRight(a, by: 13) ^ rotateRight(a, by: 22)
                let maj = (a & b) ^ (a & c) ^ (b & c)
                let temp2 = s0 &+ maj

                h = g
                g = f
                f = e
                e = d &+ temp1
                d = c
                c = b
                b = a
                a = temp1 &+ temp2
            }

            h0 = h0 &+ a
            h1 = h1 &+ b
            h2 = h2 &+ c
            h3 = h3 &+ d
            h4 = h4 &+ e
            h5 = h5 &+ f
            h6 = h6 &+ g
            h7 = h7 &+ h
        }

        return [h0, h1, h2, h3, h4, h5, h6, h7].flatMap { word in
            withUnsafeBytes(of: word.bigEndian, Array.init)
        }
    }

    private static func rotateRight(_ value: UInt32, by shift: UInt32) -> UInt32 {
        (value >> shift) | (value << (32 - shift))
    }
}
