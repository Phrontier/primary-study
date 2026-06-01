import Foundation
import SwiftUI

struct StudyManifest: Codable {
    var phases: [Phase]
    var flashcards: [FlashcardDefinition]
    var sharedResources: [SharedResource]
    var libraryStudyHubs: [LibraryStudyHub]
    var videos: [VideoAsset]

    static let placeholder = StudyManifest(
        phases: [],
        flashcards: [],
        sharedResources: [],
        libraryStudyHubs: [],
        videos: []
    )
}

struct Phase: Codable, Identifiable, Hashable {
    let id: String
    let title: String
    let summary: String
    let iconName: String
    let categories: [StudyCategory]
}

extension Phase {
    var accentColor: Color {
        switch id {
        case "contacts":
            return AppTheme.domainColor(.flights)
        case "instruments":
            return AppTheme.color(0x7B7CFF)
        case "vnav":
            return AppTheme.color(0x34C4C6)
        case "formation":
            return AppTheme.domainColor(.sims)
        case "capstone":
            return AppTheme.color(0xE35E73)
        default:
            return AppTheme.accent
        }
    }
}

struct StudyCategory: Codable, Identifiable, Hashable {
    let id: String
    let kind: StudyCategoryKind
    let summary: String
    let events: [Event]

    var displayName: String { kind.displayName }
    var iconName: String { kind.iconName }
}

enum StudyCategoryKind: String, Codable, CaseIterable, Hashable {
    case groundSchool
    case sims
    case flights

    var displayName: String {
        switch self {
        case .groundSchool: "Ground School"
        case .sims: "Sims"
        case .flights: "Flights"
        }
    }

    var iconName: String {
        switch self {
        case .groundSchool: "text.book.closed.fill"
        case .sims: "display.2"
        case .flights: "airplane"
        }
    }

    var domainColor: Color {
        switch self {
        case .groundSchool:
            return AppTheme.domainColor(.groundSchool)
        case .sims:
            return AppTheme.domainColor(.sims)
        case .flights:
            return AppTheme.domainColor(.flights)
        }
    }
}

struct Event: Codable, Identifiable, Hashable {
    let id: String
    let code: String
    let title: String
    let summary: String
    let overview: String
    let categoryKind: StudyCategoryKind
    let sourceDocuments: [SourceDocument]
    let studyNotes: EventStudyNotes?
    let systemsBrief: EventStudyNotes?
    let primaryDocumentIDs: [String]
    let flashcardDecks: [FlashcardDeck]
    let questionBanks: [QuestionBank]
    let resourceLinks: [EventResourceLink]
    let videoLinks: [EventVideoLink]
    let tags: [String]

    var availableToolCount: Int {
        var count = 0
        if studyNotes != nil { count += 1 }
        if systemsBrief != nil { count += 1 }
        if !flashcardDecks.isEmpty { count += 1 }
        if !questionBanks.isEmpty { count += 1 }
        if !primaryDocumentIDs.isEmpty { count += 1 }
        if !videoLinks.isEmpty { count += 1 }
        return count
    }

    var displayTitle: String {
        let normalized = title.trimmingCharacters(in: .whitespacesAndNewlines)
        if normalized.isEmpty || normalized.caseInsensitiveCompare(code) == .orderedSame || normalized.caseInsensitiveCompare("Event \(code)") == .orderedSame {
            return code
        }
        return normalized
    }
}

struct EventStudyNotes: Codable, Hashable {
    let headline: String
    let summary: String?
    let sections: [EventStudyNotesSection]

    init(headline: String, summary: String? = nil, sections: [EventStudyNotesSection]) {
        self.headline = headline
        self.summary = summary
        self.sections = sections
    }

    init(headline: String, summary: String? = nil, focusAreas: [String]) {
        self.headline = headline
        self.summary = summary
        self.sections = [
            EventStudyNotesSection(
                title: nil,
                items: focusAreas.map { EventStudyNotesItem(text: $0) }
            )
        ]
    }

    private enum CodingKeys: String, CodingKey {
        case headline
        case summary
        case sections
        case focusAreas
    }

    init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        headline = try container.decode(String.self, forKey: .headline)
        summary = try container.decodeIfPresent(String.self, forKey: .summary)

        if let sections = try container.decodeIfPresent([EventStudyNotesSection].self, forKey: .sections) {
            self.sections = sections
        } else {
            let focusAreas = try container.decodeIfPresent([String].self, forKey: .focusAreas) ?? []
            self.sections = [
                EventStudyNotesSection(
                    title: nil,
                    items: focusAreas.map { EventStudyNotesItem(text: $0) }
                )
            ]
        }
    }

    func encode(to encoder: Encoder) throws {
        var container = encoder.container(keyedBy: CodingKeys.self)
        try container.encode(headline, forKey: .headline)
        try container.encodeIfPresent(summary, forKey: .summary)
        try container.encode(sections, forKey: .sections)
    }
}

struct EventStudyNotesSection: Codable, Hashable {
    let title: String?
    let items: [EventStudyNotesItem]
}

struct EventStudyNotesItem: Codable, Hashable {
    let text: String
    let children: [EventStudyNotesItem]?

    init(text: String, children: [EventStudyNotesItem]? = nil) {
        self.text = text
        self.children = children
    }
}

enum AssetPlacement: String, Codable, Hashable, CaseIterable {
    case primary
    case supplemental
    case generalLibrary

    var displayName: String {
        switch self {
        case .primary: "Primary"
        case .supplemental: "Supplemental"
        case .generalLibrary: "General library"
        }
    }
}

struct EventResourceLink: Codable, Hashable {
    let resourceID: String
    let placement: AssetPlacement
}

struct EventVideoLink: Codable, Hashable {
    let videoID: String
    let placement: AssetPlacement
}

struct SourceDocument: Codable, Identifiable, Hashable {
    let id: String
    let title: String
    let relativePath: String
    let kind: SourceDocumentKind
    let summary: String
}

extension SourceDocument {
    var isWordDocument: Bool {
        let ext = URL(fileURLWithPath: relativePath).pathExtension.lowercased()
        return ext == "doc" || ext == "docx"
    }
}

enum SourceDocumentKind: String, Codable, Hashable {
    case briefingGuide
    case gradeSheet
    case scenario
    case sourceText
    case handout
    case worksheet
    case reference

    var displayName: String {
        switch self {
        case .briefingGuide: "Briefing guide"
        case .gradeSheet: "Gradesheet"
        case .scenario: "Scenario"
        case .sourceText: "Source text"
        case .handout: "Handout"
        case .worksheet: "Worksheet"
        case .reference: "Reference"
        }
    }
}

struct SharedResource: Codable, Identifiable, Hashable {
    let id: String
    let title: String
    let summary: String
    let relativePath: String?
    let topicIDs: [String]
    let phaseIDs: [String]
    let tags: [String]
    let placement: SharedResourcePlacement
    let librarySection: SharedResourceSection
}

struct LibraryStudyHub: Codable, Identifiable, Hashable {
    let id: String
    let title: String
    let summary: String
    let resourceIDs: [String]
    let deck: FlashcardDeck
    let availableFilters: [FlashcardFilterToken]
}

enum SharedResourcePlacement: String, Codable, Hashable, CaseIterable {
    case generalLibrary
    case phaseKnowledge
    case eventOnly
}

enum SharedResourceSection: String, Codable, Hashable, CaseIterable {
    case videos
    case eps
    case limits
    case nwc
    case supplements

    var displayName: String {
        switch self {
        case .videos: "Videos"
        case .eps: "EPs"
        case .limits: "Limits"
        case .nwc: "Notes / Warnings / Cautions"
        case .supplements: "Other supplements"
        }
    }

    var domainColor: Color {
        switch self {
        case .videos:
            return AppTheme.domainColor(.videos)
        case .eps, .limits, .nwc, .supplements:
            return AppTheme.domainColor(.resources)
        }
    }
}

struct FlashcardDeck: Codable, Identifiable, Hashable {
    let id: String
    let title: String
    let summary: String
    let cardIDs: [String]
}

enum FlashcardFilterToken: String, Codable, Hashable, CaseIterable {
    case ep
    case limits
    case nwc

    var displayName: String {
        switch self {
        case .ep: "EPs"
        case .limits: "Limits"
        case .nwc: "N/W/Cs"
        }
    }

    var tagValue: String { rawValue }

    var domainColor: Color {
        switch self {
        case .ep:
            return AppTheme.domainColor(.resources)
        case .limits:
            return AppTheme.domainColor(.flashcards)
        case .nwc:
            return AppTheme.domainColor(.documents)
        }
    }
}

enum FlashcardKind: String, Codable, Hashable, CaseIterable {
    case standard
    case ep
}

struct FlashcardDefinition: Codable, Identifiable, Hashable {
    let id: String
    let prompt: String
    let answer: String
    let imageRelativePath: String?
    let tags: [String]
    let studyCategories: [StudyCategoryKind]
    let eventCodes: [String]
    let kind: FlashcardKind
    let requiresVerbatim: Bool
    let companionGroupID: String?
}

struct QuestionBank: Codable, Identifiable, Hashable {
    let id: String
    let title: String
    let summary: String
    let questions: [Question]
}

struct Question: Codable, Identifiable, Hashable {
    let id: String
    let prompt: String
    let answer: String
    let explanation: String?
}

struct VideoAsset: Codable, Identifiable, Hashable {
    let id: String
    let title: String
    let url: URL
    let summary: String
    let tags: [String]
}
