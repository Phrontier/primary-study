import Foundation

enum SyllabusEventCategory: String, Codable, CaseIterable, Hashable {
    case familiarization
    case instruments
    case navigation
    case formation
    case capstone

    var displayName: String {
        switch self {
        case .familiarization:
            return "Familiarization"
        case .instruments:
            return "Instruments"
        case .navigation:
            return "Navigation"
        case .formation:
            return "Formation"
        case .capstone:
            return "Capstone"
        }
    }
}

struct SyllabusEventReference: Codable, Hashable {
    let sourceDocumentTitle: String
    let sourceDocumentDate: String
    let generatedAt: Date
    let aliases: [String: [String]]
    let events: [SyllabusEventReferenceEvent]

    static let empty = SyllabusEventReference(
        sourceDocumentTitle: "",
        sourceDocumentDate: "",
        generatedAt: .distantPast,
        aliases: [:],
        events: []
    )

    func aliases(for category: SyllabusEventCategory) -> [String] {
        aliases[category.rawValue] ?? []
    }

    func category(forAlias value: String) -> SyllabusEventCategory? {
        let normalizedValue = Self.normalizedLookupKey(value)
        guard !normalizedValue.isEmpty else { return nil }

        for category in SyllabusEventCategory.allCases {
            let candidateKeys = [category.rawValue, category.displayName] + aliases(for: category)
            if candidateKeys.contains(where: { Self.normalizedLookupKey($0) == normalizedValue }) {
                return category
            }
        }

        return nil
    }

    func event(code: String) -> SyllabusEventReferenceEvent? {
        let normalizedCode = Self.normalizedLookupKey(code)
        return events.first { Self.normalizedLookupKey($0.code) == normalizedCode }
    }

    func matchingEvent(named value: String, kind: InstructorReviewEventKind? = nil) -> SyllabusEventReferenceEvent? {
        let normalizedValue = Self.normalizedLookupKey(value)
        guard !normalizedValue.isEmpty else { return nil }

        let filteredEvents = events.filter { event in
            guard let kind else { return true }
            return event.eventKind == kind
        }

        return filteredEvents.first { event in
            searchTerms(for: event).contains { Self.normalizedLookupKey($0) == normalizedValue }
        }
    }

    func searchTerms(for event: SyllabusEventReferenceEvent) -> [String] {
        var results = [event.code, event.shortTitle, event.blockCode, event.blockTitle]
        results.append(contentsOf: event.legacyReviewAliases)
        results.append(contentsOf: aliases(for: event.category))
        results.append(event.category.displayName)
        return results
    }

    static func normalizedLookupKey(_ value: String) -> String {
        value
            .trimmingCharacters(in: .whitespacesAndNewlines)
            .folding(options: [.diacriticInsensitive, .caseInsensitive], locale: .current)
            .replacingOccurrences(of: "[^a-z0-9]+", with: "", options: .regularExpression)
            .lowercased()
    }
}

struct SyllabusEventReferenceEvent: Codable, Hashable, Identifiable {
    var id: String { code }

    let code: String
    let shortTitle: String
    let category: SyllabusEventCategory
    let categoryDisplayName: String
    let media: String
    let eventKind: InstructorReviewEventKind
    let isCheckride: Bool
    let isSolo: Bool
    let blockCode: String
    let blockTitle: String
    let discussionItems: [String]
    let sourcePages: [Int]
    let mediaNotes: String?
    let legacyReviewAliases: [String]
}
