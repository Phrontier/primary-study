import Foundation

struct ManifestBuildError: LocalizedError {
    let message: String

    var errorDescription: String? { message }
}

enum StudyCategoryKind: String, Codable {
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
}

enum SourceDocumentKind: String, Codable {
    case briefingGuide
    case gradeSheet
    case scenario
    case sourceText
    case handout
    case worksheet
    case reference
}

struct StudyManifest: Codable {
    let phases: [Phase]
    let flashcards: [FlashcardDefinition]
    let sharedResources: [SharedResource]
    let libraryStudyHubs: [LibraryStudyHub]
    let videos: [VideoAsset]
    let procedureBlocks: [ProcedureBlock]
    let calloutBlocks: [CalloutBlock]
}

struct Phase: Codable {
    let id: String
    let title: String
    let summary: String
    let iconName: String
    let categories: [StudyCategory]
}

struct StudyCategory: Codable {
    let id: String
    let kind: StudyCategoryKind
    let summary: String
    let events: [Event]
}

struct Event: Codable {
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
    let scriptTemplate: ScriptTemplate?
    let resourceLinks: [EventResourceLink]
    let videoLinks: [EventVideoLink]
    let tags: [String]
}

struct EventStudyNotes: Codable {
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

struct EventStudyNotesSection: Codable {
    let title: String?
    let items: [EventStudyNotesItem]
}

struct EventStudyNotesItem: Codable {
    let text: String
    let children: [EventStudyNotesItem]?

    init(text: String, children: [EventStudyNotesItem]? = nil) {
        self.text = text
        self.children = children
    }
}

enum AssetPlacement: String, Codable {
    case primary
    case supplemental
    case generalLibrary
}

struct EventResourceLink: Codable {
    let resourceID: String
    let placement: AssetPlacement
}

struct EventVideoLink: Codable {
    let videoID: String
    let placement: AssetPlacement
}

struct SourceDocument: Codable {
    let id: String
    let title: String
    let relativePath: String
    let kind: SourceDocumentKind
    let summary: String
}

struct SharedResource: Codable {
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

struct LibraryStudyHub: Codable {
    let id: String
    let title: String
    let summary: String
    let resourceIDs: [String]
    let deck: FlashcardDeck
    let availableFilters: [FlashcardFilterToken]
}

enum SharedResourcePlacement: String, Codable {
    case generalLibrary
    case phaseKnowledge
    case eventOnly
}

enum SharedResourceSection: String, Codable {
    case videos
    case eps
    case limits
    case nwc
    case supplements
}

struct FlashcardDeck: Codable {
    let id: String
    let title: String
    let summary: String
    let cardIDs: [String]
}

enum FlashcardFilterToken: String, Codable, CaseIterable {
    case ep
    case limits
    case nwc

    var tagValue: String { rawValue }
}

enum FlashcardKind: String, Codable {
    case standard
    case ep
}

struct FlashcardDefinition: Codable {
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

struct ReferenceStudyConfigFile: Codable {
    let libraryStudyHubs: [ReferenceStudyHubConfig]
    let discussionItemEmergencyProcedureAliases: [String: String]?
}

struct ReferenceStudyHubConfig: Codable {
    let id: String
    let title: String
    let summary: String
    let resourceIDs: [String]
    let deckTitle: String
    let deckSummary: String
    let availableFilters: [FlashcardFilterToken]
}

struct DiscussionItemAuthoringConfigFile: Codable {
    let lockedEvents: [String]?
    let eventOverrides: [String: DiscussionItemAuthoringEventOverrideConfig]
}

struct DiscussionItemAuthoringEventOverrideConfig: Codable {
    let eventEmphasisKeywords: [String]?
    let itemSections: [DiscussionItemAuthoringItemSectionConfig]?
    let systemsBriefItems: [String]?
    let standardizeRequiredProcedureDisplay: Bool?
}

struct DiscussionItemAuthoringItemSectionConfig: Codable {
    let discussionItem: String
    let displayTitle: String?
    let manualOnly: Bool?
    let presentationStyle: String?
    let splitSectionTitles: [String]?
}

struct QuestionBank: Codable {
    let id: String
    let title: String
    let summary: String
    let questions: [Question]
}

struct Question: Codable {
    let id: String
    let prompt: String
    let answer: String
    let explanation: String?
}

struct ProcedureBlock: Codable {
    let id: String
    let title: String
    let body: String
    let tags: [String]
}

struct CalloutBlock: Codable {
    let id: String
    let title: String
    let body: String
    let tags: [String]
}

struct ScriptTemplate: Codable {
    let id: String
    let title: String
    let orderedProcedureBlockIDs: [String]
    let orderedCalloutBlockIDs: [String]
    let notes: [String]
}

struct VideoAsset: Codable {
    let id: String
    let title: String
    let url: URL
    let summary: String
    let tags: [String]
}

struct EventOverrideFile: Codable {
    let events: [EventOverride]
}

struct SyllabusEventReferenceFile: Codable {
    let sourceDocumentTitle: String
    let sourceDocumentDate: String
    let generatedAt: Date
    let aliases: [String: [String]]
    let events: [SyllabusEventReferenceEventRecord]
}

struct SyllabusEventReferenceEventRecord: Codable {
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
}

struct SyllabusEventAuditReport: Codable {
    let generatedAt: Date
    let canonicalEventCount: Int
    let canonicalEventsMissingFromManifest: [String]
    let canonicalEventsMissingAuthoredNotes: [String]
    let authoredNotesCoverageIssues: [AuthoredNotesCoverageIssue]
    let discussionItemAuthoringIssues: [DiscussionItemAuthoringIssue]
    let legacyAliasAttachmentsInUse: [LegacyAliasAttachmentIssue]
    let unresolvedEmergencyProcedureItems: [EmergencyProcedureAuditIssue]
    let emergencyProcedureAliasIssues: [EmergencyProcedureAliasIssue]
    let missingEmergencyProcedureCompanions: [EmergencyProcedureAuditIssue]
}

struct AuthoredNotesCoverageIssue: Codable {
    let code: String
    let missingCanonicalItems: [String]
    let unexpectedPrimaryItems: [String]
}

struct DiscussionItemAuthoringIssue: Codable {
    let code: String
    let missingStudyNotes: Bool
    let invalidHeadline: Bool
    let missingSummary: Bool
    let missingSystemsBriefItems: [String]
    let invalidSystemsBriefHeadline: Bool
    let boilerplateOverview: Bool
    let boilerplateNotesSummary: Bool
    let colloquialVisiblePhrases: [String]
    let eventEmphasisMismatch: Bool
    let missingRequiredProceduresSection: Bool
    let missingRequiredProcedures: [String]
    let unexpectedRequiredProcedures: [String]
    let requiredProceduresOutOfOrder: Bool
    let requiredProceduresCasingMismatch: [String]
    let missingCanonicalCoverageItems: [String]
    let canonicalItemsWithoutDedicatedSection: [String]
    let splitCoverageMismatchItems: [String]
    let multiItemVisibleSections: [String]
    let missingCoverageSectionTitles: [String]
    let missingEmergencyProcedureNWCItems: [String]
    let missingManeuverEntrySetupSections: [String]
    let missingManeuverCompletionCueSections: [String]
    let recoverySectionsMixingEjectLogic: [String]
    let manualOnlyAutogeneratedSections: [String]
    let localSpecificVisibleReferences: [String]
}

struct LegacyAliasAttachmentIssue: Codable {
    let canonicalCode: String
    let aliasCode: String
    let filePaths: [String]
}

struct EmergencyProcedureAuditIssue: Codable {
    let eventCode: String
    let discussionItem: String
    let canonicalTitle: String?
    let reason: String
}

struct EmergencyProcedureAliasIssue: Codable {
    let discussionItemKey: String
    let canonicalTitle: String
    let reason: String
}

struct CanonicalReferenceCardTemplate {
    let id: String
    let prompt: String
    let answer: String
    let tags: [String]
    let kind: FlashcardKind
    let requiresVerbatim: Bool
    let companionGroupID: String?
    let normalizedTitle: String
}

struct CanonicalEmergencyProcedureReferenceDeck {
    let allCards: [CanonicalReferenceCardTemplate]
    let epCardsByNormalizedTitle: [String: CanonicalReferenceCardTemplate]
    let nwcCardsByCompanionGroupID: [String: CanonicalReferenceCardTemplate]
}

struct SyllabusFlashcardBuildResult {
    let generatedDiscussionItemCards: [FlashcardDefinition]
    let deckCardIDsByEvent: [String: [String]]
    let referenceCardEventAssignments: [String: Set<String>]
    let unresolvedEmergencyProcedureItems: [EmergencyProcedureAuditIssue]
    let missingEmergencyProcedureCompanions: [EmergencyProcedureAuditIssue]
}

struct EventOverride: Codable {
    let code: String
    let title: String?
    let summary: String?
    let overview: String?
    let studyNotes: EventStudyNotes?
    let systemsBrief: EventStudyNotes?
    let canonicalCoverage: [String: [String]]?
    let primaryDocumentTitles: [String]?
    let sharedResources: [EventResourceLink]?
    let videos: [EventVideoLink]?
    let flashcardDeckTitle: String?
    let flashcardDeckSummary: String?
    let flashcards: [AuthoredFlashcard]?
}

struct VideoLibraryFile: Codable {
    let videos: [VideoAsset]
}

struct GroupedFlashcardFile: Codable {
    let events: [String: GroupedFlashcardEventSection]
    let libraryCards: [GroupedFlashcardSourceCard]?
}

struct GroupedFlashcardEventSection: Codable {
    let deckTitle: String?
    let deckSummary: String?
    let cards: [GroupedFlashcardSourceCard]
}

struct GroupedFlashcardSourceCard: Codable {
    let id: String?
    let prompt: String
    let answer: String
    let image: String?
    let tags: [String]?
    let studyCategories: [StudyCategoryKind]?
    let alsoIncludeInEvents: [String]?
    let kind: FlashcardKind?
}

struct AuthoredFlashcard: Codable {
    let id: String?
    let prompt: String
    let answer: String
    let tags: [String]?
    let studyCategories: [StudyCategoryKind]?
    let eventCodes: [String]?
    let kind: FlashcardKind?
    let requiresVerbatim: Bool?
    let companionGroupID: String?
}

struct PhaseSeed {
    let folderName: String
    let id: String
    let title: String
    let summary: String
    let iconName: String
}

struct ManifestBuilder {
    let rootURL: URL
    let fileManager = FileManager.default
    let eventOverrides: [String: EventOverride]
    let videoLibrary: [VideoAsset]
    let groupedFlashcardSections: [String: GroupedFlashcardEventSection]
    let groupedLibraryCards: [GroupedFlashcardSourceCard]
    let flashcardLibrary: [FlashcardDefinition]
    let validEventCodes: Set<String>
    let referenceStudyConfig: ReferenceStudyConfigFile
    let discussionAuthoringConfig: DiscussionItemAuthoringConfigFile
    let syllabusReference: [String: SyllabusEventReferenceEventRecord]
    let canonicalAttachmentAliases: [String: String]
    let auditReportURL: URL
    let syllabusDeckCardIDsByEvent: [String: [String]]
    let unresolvedEmergencyProcedureItems: [EmergencyProcedureAuditIssue]
    let emergencyProcedureAliasIssues: [EmergencyProcedureAliasIssue]
    let missingEmergencyProcedureCompanions: [EmergencyProcedureAuditIssue]

    private let phaseSeeds: [PhaseSeed] = [
        PhaseSeed(folderName: "1. FAM (Contacts)", id: "contacts", title: "Contacts", summary: "Contact phase prep with aircraft systems, procedures, patterns, and foundational flying workflows.", iconName: "airplane"),
        PhaseSeed(folderName: "2. INSTRUMENTS", id: "instruments", title: "Instruments", summary: "Instrument academics, sims, and flights centered on approaches, holding, planning, and IFR execution.", iconName: "location.north.circle.fill"),
        PhaseSeed(folderName: "3. VNAV", id: "vnav", title: "VNAV", summary: "Visual navigation events and route-building study material that bridge planning with execution.", iconName: "map.fill"),
        PhaseSeed(folderName: "4. FORMS", id: "formation", title: "Formation", summary: "Formation academics and sorties with reusable procedures, cues, and debrief-ready study tools.", iconName: "airplane.formation"),
        PhaseSeed(folderName: "5. CAPSTONE", id: "capstone", title: "Capstone", summary: "Capstone check-event prep with integrated planning, procedures, and performance review material.", iconName: "flag.checkered.2.crossed")
    ]

    private let categoryDirectoryMap: [(prefix: String, kind: StudyCategoryKind, summary: String)] = [
        ("1. Ground School", .groundSchool, "Exam-focused academics with notes, flashcards, and practice tests."),
        ("2. Sims", .sims, "Scripted simulator events with briefing guides, scenarios, and procedural study tools."),
        ("3. Flights", .flights, "Student-planned flight events with gradesheets, procedures, shared references, and execution aids.")
    ]

    private static let placeholderDiscussionItemAnswer = "Answer pending generation."

    private let syllabusCategoryByPhaseID: [String: String] = [
        "contacts": "familiarization",
        "instruments": "instruments",
        "vnav": "navigation",
        "formation": "formation",
        "capstone": "capstone"
    ]

    private let supplementalPrimaryTitles: Set<String> = [
        "required procedures",
        "optional procedures"
    ]

    private static let xmlSourceDirectory = "Primary Gouge/AppContent/XMLSources"

    init(rootURL: URL) throws {
        self.rootURL = rootURL

        let currentDirectory = URL(fileURLWithPath: FileManager.default.currentDirectoryPath)
        let overridesURL = currentDirectory.appendingPathComponent("Primary Gouge/AppContent/EventOverrides.json")
        let eventOverrideDirectoryURL = currentDirectory.appendingPathComponent("Primary Gouge/AppContent/EventContentOverrides", isDirectory: true)
        let videosURL = currentDirectory.appendingPathComponent("Primary Gouge/AppContent/VideoLibrary.json")
        let groupedFlashcardsURL = currentDirectory.appendingPathComponent("Primary Gouge/AppContent/FlashcardsByEvent.json")
        let flashcardImagesURL = currentDirectory.appendingPathComponent("Contents/FlashcardImages", isDirectory: true)
        let referenceConfigURL = currentDirectory.appendingPathComponent("Primary Gouge/AppContent/ReferenceStudyConfig.json")
        let discussionAuthoringConfigURL = currentDirectory.appendingPathComponent("Primary Gouge/AppContent/EventContentOverrides/FAMDiscussionAuthoringConfig.json")
        let syllabusReferenceURL = currentDirectory.appendingPathComponent("Primary Gouge/AppContent/SyllabusEventReference.json")
        let xmlDirectoryURL = currentDirectory.appendingPathComponent(Self.xmlSourceDirectory, isDirectory: true)
        self.auditReportURL = currentDirectory.appendingPathComponent("Primary Gouge/AppContent/SyllabusEventAuditReport.json")

        let legacyOverrides: [String: EventOverride]
        if let data = try? Data(contentsOf: overridesURL),
           let file = try? JSONDecoder().decode(EventOverrideFile.self, from: data) {
            legacyOverrides = Dictionary(uniqueKeysWithValues: file.events.map { ($0.code.replacingOccurrences(of: " ", with: ""), $0) })
        } else {
            legacyOverrides = [:]
        }

        let authoredOverrides = Self.loadEventOverrideDirectory(at: eventOverrideDirectoryURL)
        self.eventOverrides = Self.mergeEventOverrides(legacy: legacyOverrides, authored: authoredOverrides)
        try Self.validateDeprecatedOverrideFlashcards(self.eventOverrides)

        if let data = try? Data(contentsOf: videosURL),
           let file = try? JSONDecoder().decode(VideoLibraryFile.self, from: data) {
            self.videoLibrary = file.videos
        } else {
            self.videoLibrary = []
        }

        let syllabusDecoder = JSONDecoder()
        syllabusDecoder.dateDecodingStrategy = .iso8601
        if let data = try? Data(contentsOf: syllabusReferenceURL),
           let file = try? syllabusDecoder.decode(SyllabusEventReferenceFile.self, from: data) {
            self.syllabusReference = Dictionary(
                uniqueKeysWithValues: file.events.map { (Self.normalizeCode($0.code), $0) }
            )
        } else {
            self.syllabusReference = [:]
        }
        self.canonicalAttachmentAliases = Self.buildCanonicalAttachmentAliases(from: syllabusReference)
        self.validEventCodes = Self.discoverEventCodes(under: rootURL)
            .union(self.eventOverrides.keys)
            .union(self.syllabusReference.keys)
            .union(self.canonicalAttachmentAliases.keys)

        if let data = try? Data(contentsOf: referenceConfigURL),
           let file = try? JSONDecoder().decode(ReferenceStudyConfigFile.self, from: data) {
            self.referenceStudyConfig = file
        } else {
            self.referenceStudyConfig = ReferenceStudyConfigFile(libraryStudyHubs: [], discussionItemEmergencyProcedureAliases: [:])
        }

        if let data = try? Data(contentsOf: discussionAuthoringConfigURL),
           let file = try? JSONDecoder().decode(DiscussionItemAuthoringConfigFile.self, from: data) {
            self.discussionAuthoringConfig = file
        } else {
            self.discussionAuthoringConfig = DiscussionItemAuthoringConfigFile(lockedEvents: [], eventOverrides: [:])
        }

        let groupedFlashcardSource = try Self.loadGroupedFlashcardSource(
            at: groupedFlashcardsURL,
            validEventCodes: validEventCodes
        )
        self.groupedFlashcardSections = groupedFlashcardSource.sections
        self.groupedLibraryCards = groupedFlashcardSource.libraryCards

        let canonicalEmergencyProcedureReferenceDeck = try Self.loadCanonicalEmergencyProcedureReferenceDeck(from: xmlDirectoryURL)
        let emergencyProcedureAliasValidation = Self.validateEmergencyProcedureAliases(
            referenceStudyConfig.discussionItemEmergencyProcedureAliases ?? [:],
            availableEmergencyProcedures: canonicalEmergencyProcedureReferenceDeck.epCardsByNormalizedTitle
        )
        self.emergencyProcedureAliasIssues = emergencyProcedureAliasValidation

        let syllabusFlashcardBuildResult = try Self.buildSyllabusEventFlashcards(
            from: syllabusReference,
            emergencyProcedureReferenceDeck: canonicalEmergencyProcedureReferenceDeck,
            emergencyProcedureAliases: referenceStudyConfig.discussionItemEmergencyProcedureAliases ?? [:],
            placeholderAnswer: Self.placeholderDiscussionItemAnswer
        )
        self.syllabusDeckCardIDsByEvent = syllabusFlashcardBuildResult.deckCardIDsByEvent
        self.unresolvedEmergencyProcedureItems = syllabusFlashcardBuildResult.unresolvedEmergencyProcedureItems
        self.missingEmergencyProcedureCompanions = syllabusFlashcardBuildResult.missingEmergencyProcedureCompanions

        let canonicalReferenceCards = Self.materializeCanonicalReferenceCards(
            from: canonicalEmergencyProcedureReferenceDeck,
            eventAssignments: syllabusFlashcardBuildResult.referenceCardEventAssignments,
            syllabusReference: syllabusReference
        )

        self.flashcardLibrary = Self.dedupeFlashcards(
            syllabusFlashcardBuildResult.generatedDiscussionItemCards + (try Self.materializeGroupedFlashcards(
                libraryCards: groupedLibraryCards,
                validEventCodes: validEventCodes,
                imageRootURL: flashcardImagesURL
            )) + canonicalReferenceCards
            )
    }

    private static func loadEventOverrideDirectory(at url: URL) -> [String: EventOverride] {
        guard let files = try? FileManager.default.contentsOfDirectory(at: url, includingPropertiesForKeys: nil) else {
            return [:]
        }

        let decoder = JSONDecoder()
        let overrides = files
            .filter {
                $0.pathExtension.lowercased() == "json" &&
                $0.deletingPathExtension().lastPathComponent != "FAMDiscussionAuthoringConfig"
            }
            .compactMap { fileURL -> EventOverride? in
                do {
                    let data = try Data(contentsOf: fileURL)
                    return try decoder.decode(EventOverride.self, from: data)
                } catch {
                    fputs("Warning: Failed to decode event override \(fileURL.lastPathComponent): \(error)\n", stderr)
                    return nil
                }
            }

        return Dictionary(uniqueKeysWithValues: overrides.map { ($0.code.replacingOccurrences(of: " ", with: ""), $0) })
    }

    private static func mergeEventOverrides(legacy: [String: EventOverride], authored: [String: EventOverride]) -> [String: EventOverride] {
        var merged = legacy
        for (code, override) in authored {
            merged[code] = override
        }
        return merged
    }

    private static func dedupeFlashcards(_ cards: [FlashcardDefinition]) -> [FlashcardDefinition] {
        var seen = Set<String>()
        var result: [FlashcardDefinition] = []

        for card in cards.reversed() {
            guard !seen.contains(card.id) else { continue }
            seen.insert(card.id)
            result.append(card)
        }

        return result.reversed()
    }

    private static func loadGroupedFlashcardSource(
        at url: URL,
        validEventCodes: Set<String>
    ) throws -> (sections: [String: GroupedFlashcardEventSection], libraryCards: [GroupedFlashcardSourceCard]) {
        guard let data = try? Data(contentsOf: url) else {
            throw ManifestBuildError(message: "Missing grouped flashcard source at \(url.path).")
        }

        let decoder = JSONDecoder()
        let file: GroupedFlashcardFile
        do {
            file = try decoder.decode(GroupedFlashcardFile.self, from: data)
        } catch {
            throw ManifestBuildError(message: "Failed to decode grouped flashcard source \(url.lastPathComponent): \(error.localizedDescription)")
        }

        var normalizedSections: [String: GroupedFlashcardEventSection] = [:]
        for (rawCode, section) in file.events {
            let normalizedCode = normalizeCode(rawCode)
            guard !normalizedCode.isEmpty else {
                throw ManifestBuildError(message: "Flashcard source contains an empty event code section.")
            }
            guard validEventCodes.contains(normalizedCode) else {
                throw ManifestBuildError(message: "Flashcard source references unknown event code '\(rawCode)'.")
            }
            if normalizedSections[normalizedCode] != nil {
                throw ManifestBuildError(message: "Flashcard source contains duplicate event section '\(normalizedCode)'.")
            }
            normalizedSections[normalizedCode] = section
        }

        return (normalizedSections, file.libraryCards ?? [])
    }

    private static func buildCanonicalAttachmentAliases(from reference: [String: SyllabusEventReferenceEventRecord]) -> [String: String] {
        var aliases: [String: String] = [:]

        for (canonicalCode, event) in reference {
            for alias in event.legacyReviewAliases {
                let normalizedAlias = normalizeCode(alias)
                guard !normalizedAlias.isEmpty, normalizedAlias != canonicalCode else { continue }
                aliases[normalizedAlias] = canonicalCode
            }
        }

        return aliases
    }

    private static func loadCanonicalEmergencyProcedureReferenceDeck(from xmlDirectoryURL: URL) throws -> CanonicalEmergencyProcedureReferenceDeck {
        let epCards = try parseCanonicalReferenceDeck(
            fileURL: xmlDirectoryURL.appendingPathComponent("T-6 EP's.xml"),
            filter: .ep,
            epGroupIDs: [:]
        )
        let epGroupIDs = Dictionary(uniqueKeysWithValues: epCards.map { ($0.normalizedTitle, $0.normalizedTitle) })
        let nwcCards = try parseCanonicalReferenceDeck(
            fileURL: xmlDirectoryURL.appendingPathComponent("EP's N_W_C.xml"),
            filter: .nwc,
            epGroupIDs: epGroupIDs
        )

        return CanonicalEmergencyProcedureReferenceDeck(
            allCards: epCards + nwcCards,
            epCardsByNormalizedTitle: Dictionary(uniqueKeysWithValues: epCards.map { ($0.normalizedTitle, $0) }),
            nwcCardsByCompanionGroupID: Dictionary(uniqueKeysWithValues: nwcCards.compactMap { card in
                guard let companionGroupID = card.companionGroupID else { return nil }
                return (companionGroupID, card)
            })
        )
    }

    private static func validateEmergencyProcedureAliases(
        _ aliases: [String: String],
        availableEmergencyProcedures: [String: CanonicalReferenceCardTemplate]
    ) -> [EmergencyProcedureAliasIssue] {
        aliases.keys.sorted().compactMap { aliasKey in
            guard let canonicalTitle = aliases[aliasKey] else { return nil }
            let normalizedCanonicalTitle = normalizeReferenceTitle(canonicalTitle)
            guard availableEmergencyProcedures[normalizedCanonicalTitle] == nil else { return nil }
            return EmergencyProcedureAliasIssue(
                discussionItemKey: normalizedText(aliasKey),
                canonicalTitle: canonicalTitle,
                reason: "Alias points to a canonical emergency procedure title that was not found in the XML source."
            )
        }
    }

    private static func buildSyllabusEventFlashcards(
        from reference: [String: SyllabusEventReferenceEventRecord],
        emergencyProcedureReferenceDeck: CanonicalEmergencyProcedureReferenceDeck,
        emergencyProcedureAliases: [String: String],
        placeholderAnswer: String
    ) throws -> SyllabusFlashcardBuildResult {
        let normalizedAliasMap = Dictionary(
            uniqueKeysWithValues: emergencyProcedureAliases.map { (normalizedText($0.key), normalizeReferenceTitle($0.value)) }
        )

        var generatedDiscussionItemCards: [FlashcardDefinition] = []
        var deckCardIDsByEvent: [String: [String]] = [:]
        var referenceCardEventAssignments: [String: Set<String>] = [:]
        var unresolvedEmergencyProcedureItems: [EmergencyProcedureAuditIssue] = []
        var missingEmergencyProcedureCompanions: [EmergencyProcedureAuditIssue] = []

        for event in reference.values.sorted(by: { normalizeCode($0.code) < normalizeCode($1.code) }) {
            let normalizedCode = normalizeCode(event.code)
            let categoryKind = event.eventKind.lowercased() == "flight" ? StudyCategoryKind.flights : StudyCategoryKind.sims
            var deckCardIDs: [String] = []

            for (index, rawPrompt) in event.discussionItems.enumerated() {
                let normalizedDiscussionItem = normalizeReferenceTitle(rawPrompt)
                let matchedEmergencyProcedure = emergencyProcedureReferenceDeck.epCardsByNormalizedTitle[normalizedDiscussionItem]
                    ?? normalizedAliasMap[normalizedText(rawPrompt)].flatMap { emergencyProcedureReferenceDeck.epCardsByNormalizedTitle[$0] }

                if let emergencyProcedureCard = matchedEmergencyProcedure {
                    deckCardIDs.append(emergencyProcedureCard.id)
                    referenceCardEventAssignments[emergencyProcedureCard.id, default: []].insert(normalizedCode)

                    guard let companionGroupID = emergencyProcedureCard.companionGroupID,
                          let nwcCard = emergencyProcedureReferenceDeck.nwcCardsByCompanionGroupID[companionGroupID] else {
                        missingEmergencyProcedureCompanions.append(
                            EmergencyProcedureAuditIssue(
                                eventCode: normalizedCode,
                                discussionItem: rawPrompt,
                                canonicalTitle: emergencyProcedureCard.prompt,
                                reason: "Matched emergency procedure is missing its canonical companion N/W/C card."
                            )
                        )
                        continue
                    }

                    deckCardIDs.append(nwcCard.id)
                    referenceCardEventAssignments[nwcCard.id, default: []].insert(normalizedCode)
                    continue
                }

                if looksLikeEmergencyProcedureDiscussionItem(rawPrompt) {
                    unresolvedEmergencyProcedureItems.append(
                        EmergencyProcedureAuditIssue(
                            eventCode: normalizedCode,
                            discussionItem: rawPrompt,
                            canonicalTitle: nil,
                            reason: "Discussion item looked emergency-procedure-related but did not resolve to a canonical EP title or alias."
                        )
                    )
                }

                let displayPrompt = titleCasedDiscussionItemPrompt(rawPrompt)
                let card = FlashcardDefinition(
                    id: sanitizedIdentifier("flashcard-\(normalizedCode)-discussion-item-\(index + 1)"),
                    prompt: displayPrompt,
                    answer: placeholderAnswer,
                    imageRelativePath: nil,
                    tags: buildSyllabusFlashcardTags(for: event, prompt: displayPrompt),
                    studyCategories: [categoryKind],
                    eventCodes: [normalizedCode],
                    kind: .standard,
                    requiresVerbatim: false,
                    companionGroupID: nil
                )
                generatedDiscussionItemCards.append(card)
                deckCardIDs.append(card.id)
            }

            deckCardIDsByEvent[normalizedCode] = deckCardIDs
        }

        return SyllabusFlashcardBuildResult(
            generatedDiscussionItemCards: generatedDiscussionItemCards,
            deckCardIDsByEvent: deckCardIDsByEvent,
            referenceCardEventAssignments: referenceCardEventAssignments,
            unresolvedEmergencyProcedureItems: unresolvedEmergencyProcedureItems,
            missingEmergencyProcedureCompanions: missingEmergencyProcedureCompanions
        )
    }

    private static func buildSyllabusFlashcardTags(for event: SyllabusEventReferenceEventRecord, prompt: String) -> [String] {
        var tags: [String] = [
            normalizeCode(event.code).lowercased(),
            categoryTag(for: event.category),
            event.eventKind.lowercased(),
            "discussion-item"
        ]

        let normalizedPrompt = normalizedText(prompt)
        if normalizedPrompt.contains("emergency") ||
            normalizedPrompt.contains("engine failure") ||
            normalizedPrompt.contains("pel") ||
            normalizedPrompt.contains("elp") ||
            normalizedPrompt.contains("lost aircraft") ||
            normalizedPrompt.contains("unintentional instrument") {
            tags.append("emergency-procedures")
        }

        if normalizedPrompt.contains("maneuver") ||
            normalizedPrompt.contains("landing") ||
            normalizedPrompt.contains("takeoff") ||
            normalizedPrompt.contains("approach") {
            tags.append("maneuvers")
        }

        return uniqueStrings(tags)
    }

    private static func categoryTag(for category: String) -> String {
        switch category {
        case "familiarization":
            return "fam"
        case "instruments":
            return "instruments"
        case "navigation":
            return "nav"
        case "formation":
            return "formation"
        case "capstone":
            return "capstone"
        default:
            return normalizedText(category)
        }
    }

    private static func materializeCanonicalReferenceCards(
        from deck: CanonicalEmergencyProcedureReferenceDeck,
        eventAssignments: [String: Set<String>],
        syllabusReference: [String: SyllabusEventReferenceEventRecord]
    ) -> [FlashcardDefinition] {
        deck.allCards.map { card in
            let eventCodes = sortedEventCodes(eventAssignments[card.id] ?? [])
            return FlashcardDefinition(
                id: card.id,
                prompt: card.prompt,
                answer: card.answer,
                imageRelativePath: nil,
                tags: card.tags,
                studyCategories: studyCategories(for: eventCodes, syllabusReference: syllabusReference),
                eventCodes: eventCodes,
                kind: card.kind,
                requiresVerbatim: card.requiresVerbatim,
                companionGroupID: card.companionGroupID
            )
        }
    }

    private static func materializeGroupedFlashcards(
        libraryCards: [GroupedFlashcardSourceCard],
        validEventCodes: Set<String>,
        imageRootURL: URL
    ) throws -> [FlashcardDefinition] {
        var cards: [FlashcardDefinition] = []
        var seenExplicitIDs = Set<String>()

        for (index, card) in libraryCards.enumerated() {
            if isLegacyEmergencyProcedureReferenceCard(card) {
                continue
            }

            let eventCodes = uniqueEventCodes((card.alsoIncludeInEvents ?? []).map(normalizeCode))
            for mappedCode in eventCodes {
                guard validEventCodes.contains(mappedCode) else {
                    throw ManifestBuildError(message: "Library flashcard '\(card.prompt)' references unknown event code '\(mappedCode)'.")
                }
            }

            if let explicitID = card.id {
                guard seenExplicitIDs.insert(explicitID).inserted else {
                    throw ManifestBuildError(message: "Duplicate flashcard id '\(explicitID)' found in grouped flashcard source.")
                }
            }

            let fallbackID = sanitizedIdentifier(
                "flashcard-library-\(String(sanitizedIdentifier(card.prompt).prefix(48)))-\(index + 1)"
            )

            cards.append(
                FlashcardDefinition(
                    id: card.id ?? fallbackID,
                    prompt: card.prompt,
                    answer: card.answer,
                    imageRelativePath: try manifestImageRelativePath(for: card.image, imageRootURL: imageRootURL),
                    tags: card.tags ?? [],
                    studyCategories: card.studyCategories ?? [],
                    eventCodes: eventCodes,
                    kind: card.kind ?? .standard,
                    requiresVerbatim: false,
                    companionGroupID: nil
                )
            )
        }

        return dedupeFlashcards(cards)
    }

    private static func isLegacyEmergencyProcedureReferenceCard(_ card: GroupedFlashcardSourceCard) -> Bool {
        let tags = Set(card.tags ?? [])
        return tags.contains(FlashcardFilterToken.ep.tagValue) || tags.contains(FlashcardFilterToken.nwc.tagValue)
    }

    private static func manifestImageRelativePath(for image: String?, imageRootURL: URL) throws -> String? {
        guard let rawImage = image?.trimmingCharacters(in: .whitespacesAndNewlines), !rawImage.isEmpty else {
            return nil
        }

        guard !rawImage.hasPrefix("/"), !rawImage.contains("..") else {
            throw ManifestBuildError(message: "Flashcard image path '\(rawImage)' must be relative to FlashcardImages.")
        }

        let candidateURL = imageRootURL.appendingPathComponent(rawImage)
        guard FileManager.default.fileExists(atPath: candidateURL.path) else {
            throw ManifestBuildError(message: "Flashcard image '\(rawImage)' was not found at \(candidateURL.path).")
        }

        return "FlashcardImages/\(rawImage)"
    }

    private static func uniqueEventCodes(_ codes: [String]) -> [String] {
        var seen = Set<String>()
        var result: [String] = []

        for code in codes {
            guard !code.isEmpty, seen.insert(code).inserted else { continue }
            result.append(code)
        }

        return result
    }

    private static func validateDeprecatedOverrideFlashcards(_ overrides: [String: EventOverride]) throws {
        let deprecatedCodes = overrides.values
            .filter { !($0.flashcards ?? []).isEmpty }
            .map(\.code)
            .sorted()

        guard deprecatedCodes.isEmpty else {
            throw ManifestBuildError(
                message: "Inline event override flashcards are deprecated. Move flashcards for \(deprecatedCodes.joined(separator: ", ")) into FlashcardsByEvent.json."
            )
        }
    }

    private static func discoverEventCodes(under rootURL: URL) -> Set<String> {
        let enumerator = FileManager.default.enumerator(at: rootURL, includingPropertiesForKeys: nil)
        var results = Set<String>()

        while let item = enumerator?.nextObject() as? URL {
            var isDirectory: ObjCBool = false
            guard FileManager.default.fileExists(atPath: item.path, isDirectory: &isDirectory), !isDirectory.boolValue else { continue }
            guard let code = inferredEventCode(from: item.lastPathComponent) else { continue }
            results.insert(code)
        }

        return results
    }

    private static func inferredEventCode(from filename: String) -> String? {
        let patterns = [
            #"[A-Z]{1,4}\s?\d{4}"#,
            #"CS\s?\d{4}"#
        ]

        for pattern in patterns {
            if let regex = try? NSRegularExpression(pattern: pattern) {
                let range = NSRange(location: 0, length: filename.utf16.count)
                if let match = regex.firstMatch(in: filename, range: range),
                   let swiftRange = Range(match.range, in: filename) {
                    return normalizeCode(String(filename[swiftRange]))
                }
            }
        }

        return nil
    }

    private static func normalizeCode(_ value: String) -> String {
        value.replacingOccurrences(of: " ", with: "")
    }

    func build() throws -> StudyManifest {
        let phases = try phaseSeeds.map { try buildPhase(from: $0) }
        let flashcards = flashcardLibrary
        let sharedResources = buildSharedResources()
        let libraryStudyHubs = buildLibraryStudyHubs()
        let videos = videoLibrary
        let procedureBlocks = buildProcedureBlocks()
        let calloutBlocks = buildCalloutBlocks()
        let manifest = StudyManifest(phases: phases, flashcards: flashcards, sharedResources: sharedResources, libraryStudyHubs: libraryStudyHubs, videos: videos, procedureBlocks: procedureBlocks, calloutBlocks: calloutBlocks)
        try writeAuditReport(for: manifest)
        let discussionItemIssues = discussionItemAuthoringIssues()
        if !discussionItemIssues.isEmpty {
            let codes = discussionItemIssues.map(\.code).joined(separator: ", ")
            throw ManifestBuildError(message: "FAM discussion-item authoring validation failed for: \(codes). Check SyllabusEventAuditReport.json for details.")
        }
        if !missingEmergencyProcedureCompanions.isEmpty {
            let details = missingEmergencyProcedureCompanions
                .map { "\($0.eventCode): \($0.discussionItem)" }
                .joined(separator: ", ")
            throw ManifestBuildError(message: "Matched emergency procedures are missing canonical companion N/W/C cards: \(details)")
        }
        return manifest
    }

    private func buildPhase(from seed: PhaseSeed) throws -> Phase {
        let phaseURL = rootURL.appendingPathComponent(seed.folderName, isDirectory: true)
        let categories = try categoryDirectoryMap.compactMap { categorySeed -> StudyCategory? in
            guard let categoryDirectory = try? fileManager.contentsOfDirectory(at: phaseURL, includingPropertiesForKeys: nil)
                .first(where: { $0.lastPathComponent.hasPrefix(categorySeed.prefix) }) else {
                return nil
            }

            let events = try buildEvents(in: categoryDirectory, phaseID: seed.id, categoryKind: categorySeed.kind)
            return StudyCategory(id: "\(seed.id)-\(categorySeed.kind.rawValue)", kind: categorySeed.kind, summary: categorySeed.summary, events: events)
        }

        return Phase(id: seed.id, title: seed.title, summary: seed.summary, iconName: seed.iconName, categories: categories)
    }

    private func buildEvents(in categoryURL: URL, phaseID: String, categoryKind: StudyCategoryKind) throws -> [Event] {
        if categoryKind != .groundSchool, syllabusCategoryByPhaseID[phaseID] != nil {
            return buildCanonicalSyllabusEvents(in: categoryURL, phaseID: phaseID, categoryKind: categoryKind)
        }

        let files = allFiles(under: categoryURL)
        let grouped = Dictionary(grouping: files.compactMap { file -> (String, URL)? in
            guard let code = eventCode(from: file.lastPathComponent) else { return nil }
            return (normalizeCode(code), file)
        }, by: \.0)

        var events: [Event] = grouped.keys.sorted().compactMap { code -> Event? in
            guard let eventFiles = grouped[code]?.map(\.1), !eventFiles.isEmpty else { return nil }
            return buildEvent(code: code, files: eventFiles, phaseID: phaseID, categoryKind: categoryKind)
        }

        let groupedPaths = Set(grouped.values.flatMap { $0.map(\.1.path) })
        let unassigned = files.filter { !groupedPaths.contains($0.path) }
        if !unassigned.isEmpty {
            let syntheticCode = "\(phaseID.uppercased())-\(syntheticCodeSuffix(for: categoryKind))"
            events.append(buildEvent(code: syntheticCode, files: unassigned, phaseID: phaseID, categoryKind: categoryKind))
        }

        return events.sorted { $0.code < $1.code }
    }

    private func buildCanonicalSyllabusEvents(in categoryURL: URL, phaseID: String, categoryKind: StudyCategoryKind) -> [Event] {
        let files = allFiles(under: categoryURL)
        let canonicalEvents = canonicalSyllabusEvents(forPhaseID: phaseID, categoryKind: categoryKind)
        let allowedCodes = Set(canonicalEvents.map { normalizeCode($0.code) })
        let groupedFiles = groupedFilesByCanonicalCode(files, allowedCodes: allowedCodes)

        return canonicalEvents.map { event in
            let code = normalizeCode(event.code)
            return buildEvent(
                code: code,
                files: groupedFiles[code] ?? [],
                phaseID: phaseID,
                categoryKind: categoryKind
            )
        }
    }

    private func buildEvent(code: String, files: [URL], phaseID: String, categoryKind: StudyCategoryKind) -> Event {
        let sortedFiles = files.sorted { $0.lastPathComponent < $1.lastPathComponent }
        let sourceDocuments = sortedFiles.filter(isUserVisibleDocumentFile(_:)).map(buildSourceDocument)
        let normalizedCode = normalizeCode(code)
        let override = eventOverrides[normalizedCode]
        let syllabusEvent = syllabusReference[normalizedCode]

        let questionBanks = sortedFiles
            .filter { isQuestionFile($0.lastPathComponent) }
            .compactMap { file -> QuestionBank? in
                guard let text = extractText(from: file) else { return nil }
                let questions = parseQuestions(from: text, deckID: sanitizeID(file.deletingPathExtension().lastPathComponent))
                guard !questions.isEmpty else { return nil }
                return QuestionBank(
                    id: sanitizeID("\(code)-\(file.deletingPathExtension().lastPathComponent)-test"),
                    title: "Practice Test",
                    summary: "Converted from the source practice-question document for cleaner event prep.",
                    questions: questions
                )
            }

        let noteCandidate = sortedFiles.first(where: isStudyNoteFile(_:))
        let noteText = noteCandidate.flatMap(extractText)
        let overview = override?.overview ?? buildOverview(for: code, phaseID: phaseID, categoryKind: categoryKind, text: noteText)
        let studyNotes = override?.studyNotes
            ?? buildStudyNotes(fromSyllabusReferenceFor: code)
            ?? noteText.flatMap { buildStudyNotes(from: $0, code: code, categoryKind: categoryKind) }
        let systemsBrief = override?.systemsBrief
        let primaryDocumentIDs = resolvePrimaryDocumentIDs(from: sourceDocuments, override: override)
        let flashcardDecks = resolvedFlashcardDecks(for: code, override: override)

        let scriptTemplate = buildScriptTemplate(for: code, phaseID: phaseID, categoryKind: categoryKind)
        let resourceLinks = override?.sharedResources ?? defaultResourceLinks(for: phaseID, categoryKind: categoryKind, files: sortedFiles)
        let videoLinks = override?.videos ?? []
        let title = syllabusEvent?.shortTitle ?? override?.title ?? inferTitle(for: code, from: sortedFiles)
        let summary = override?.summary ?? summaryText(from: overview)

        return Event(
            id: sanitizeID("\(phaseID)-\(categoryKind.rawValue)-\(code)"),
            code: code,
            title: title,
            summary: summary,
            overview: overview,
            categoryKind: categoryKind,
            sourceDocuments: sourceDocuments,
            studyNotes: studyNotes,
            systemsBrief: systemsBrief,
            primaryDocumentIDs: primaryDocumentIDs,
            flashcardDecks: flashcardDecks,
            questionBanks: questionBanks,
            scriptTemplate: scriptTemplate,
            resourceLinks: resourceLinks,
            videoLinks: videoLinks,
            tags: uniqueStrings([phaseID, categoryKind.rawValue, normalizedCode.lowercased()])
        )
    }

    private func buildSourceDocument(for file: URL) -> SourceDocument {
        let relativePath = "Contents/" + file.path.replacingOccurrences(of: rootURL.path + "/", with: "")
        let filename = file.lastPathComponent
        return SourceDocument(
            id: sanitizeID(relativePath),
            title: file.deletingPathExtension().lastPathComponent,
            relativePath: relativePath,
            kind: sourceDocumentKind(for: filename),
            summary: documentSummary(for: filename)
        )
    }

    private func buildOverview(for code: String, phaseID: String, categoryKind: StudyCategoryKind, text: String?) -> String {
        switch (phaseID, categoryKind) {
        case ("contacts", .sims):
            return "\(code) builds cockpit familiarity, checklist discipline, safety-call consistency, and a smoother sim setup before later contact events."
        case ("contacts", .flights):
            return "\(code) prepares the student to brief, plan, and execute the assigned contact flight with the required maneuvers and standards in mind."
        case ("instruments", .sims):
            return "\(code) focuses on sim execution, instrument setup, approach flow, and the discussion items students need to brief confidently."
        case ("instruments", .flights):
            return "\(code) prepares the student to plan and fly the assigned instrument profile with the required procedures, comm flow, and standards."
        case (_, .groundSchool):
            return "\(code) packages the academic material, official source references, and practice questions students need for exam prep."
        default:
            if let text {
                let lines = contentLines(from: text)
                let prompts = lines.filter(isLikelyPrompt)
                if let firstPrompt = prompts.first {
                    return "\(code) centers on \(firstPrompt.lowercased()) and the key procedures students need to explain and execute."
                }
            }
            return "\(code) packages the most relevant study material for this event in a single prep flow."
        }
    }

    private func buildStudyNotes(from text: String, code: String, categoryKind: StudyCategoryKind) -> EventStudyNotes? {
        let bullets = contentLines(from: text)
        let pairs = studyPairs(from: bullets, code: code)
        guard !pairs.isEmpty else { return nil }

        let focusAreas = pairs.prefix(5).map { pair in
            let prompt = pair.prompt.trimmingCharacters(in: CharacterSet(charactersIn: "*: ")).lowercased()
            let answer = shorten(pair.answer, maxLength: 130)
            return "Know why \(prompt) matters and be able to explain it simply: \(answer)"
        }

        let summary: String
        switch categoryKind {
        case .groundSchool:
            summary = "Use this page to translate the official academics into the plain-language ideas the exam is really testing. Focus on why the rule exists, how it is applied, and what distinction usually trips students up."
        case .sims:
            summary = "Use this page to translate the bullet gouge into what the sim is actually trying to build. Focus on what right looks like, what the instructor is likely to probe, and where students usually get behind the aircraft."
        case .flights:
            summary = "Use this page to turn the official standards into a practical flight-prep picture. Focus on what you need to brief, what you need to recognize in the cockpit, and what execution traps are most likely to show up."
        }

        return EventStudyNotes(
            headline: "Discussion items",
            summary: summary,
            sections: [
                EventStudyNotesSection(
                    title: nil,
                    items: Array(focusAreas).map { EventStudyNotesItem(text: $0) }
                )
            ]
        )
    }

    private func buildStudyNotes(fromSyllabusReferenceFor code: String) -> EventStudyNotes? {
        guard let event = syllabusReference[normalizeCode(code)], !event.discussionItems.isEmpty else {
            return nil
        }

        let summary = "Generated from the canonical syllabus event reference so the app, review workflow, and event detail notes stay aligned."
        return EventStudyNotes(
            headline: "Discussion items",
            summary: summary,
            sections: [
                EventStudyNotesSection(
                    title: event.blockTitle,
                    items: event.discussionItems.map { EventStudyNotesItem(text: $0) }
                )
            ]
        )
    }

    private func parseQuestions(from text: String, deckID: String) -> [Question] {
        let lines = contentLines(from: text)
        var questions: [Question] = []
        var index = 0

        while index < lines.count - 1 {
            let prompt = lines[index]
            guard isLikelyQuestion(prompt) else {
                index += 1
                continue
            }

            let answer = lines[index + 1]
            var explanationLines: [String] = []
            var probe = index + 2
            while probe < lines.count && !isLikelyQuestion(lines[probe]) && explanationLines.count < 3 {
                explanationLines.append(lines[probe])
                probe += 1
            }

            questions.append(
                Question(
                    id: sanitizeID("\(deckID)-\(questions.count)-\(prompt)"),
                    prompt: prompt,
                    answer: answer,
                    explanation: explanationLines.isEmpty ? nil : explanationLines.joined(separator: "\n")
                )
            )

            index = probe
        }

        return questions
    }

    private func buildScriptTemplate(for code: String, phaseID: String, categoryKind: StudyCategoryKind) -> ScriptTemplate? {
        guard categoryKind != .groundSchool else { return nil }

        let procedureBlockIDs: [String]
        let calloutBlockIDs: [String]

        switch categoryKind {
        case .sims:
            procedureBlockIDs = ["mission-brief", "taxi-flow", "takeoff-flow", "mission-execution", "recovery-flow"]
            calloutBlockIDs = ["ground-comm", "tower-comm", "approach-comm"]
        case .flights:
            procedureBlockIDs = ["mission-brief", "taxi-flow", "takeoff-flow", "maneuver-flow", "recovery-flow"]
            calloutBlockIDs = ["ground-comm", "tower-comm", "pattern-comm"]
        case .groundSchool:
            procedureBlockIDs = []
            calloutBlockIDs = []
        }

        return ScriptTemplate(
            id: sanitizeID("\(phaseID)-\(categoryKind.rawValue)-\(code)-script"),
            title: "\(code) Script",
            orderedProcedureBlockIDs: procedureBlockIDs,
            orderedCalloutBlockIDs: calloutBlockIDs,
            notes: [
                "Adjust specifics to match the assigned profile, weather, and local procedures.",
                "Because the blocks are shared, one edit updates every event that references the same procedure or comm call."
            ]
        )
    }

    private func buildLibraryStudyHubs() -> [LibraryStudyHub] {
        referenceStudyConfig.libraryStudyHubs.map { config in
            let filterTags = Set(config.availableFilters.map(\.tagValue))
            let cardIDs = flashcardLibrary
                .filter { !Set($0.tags).isDisjoint(with: filterTags) }
                .map(\.id)

            return LibraryStudyHub(
                id: config.id,
                title: config.title,
                summary: config.summary,
                resourceIDs: config.resourceIDs,
                deck: FlashcardDeck(
                    id: sanitizeID(config.id + "-deck"),
                    title: config.deckTitle,
                    summary: config.deckSummary,
                    cardIDs: cardIDs
                ),
                availableFilters: config.availableFilters
            )
        }
    }

    private func resolvedFlashcardDecks(for code: String, override: EventOverride?) -> [FlashcardDeck] {
        let normalizedCode = normalizeCode(code)
        let cardIDs = syllabusDeckCardIDsByEvent[normalizedCode] ?? flashcardLibrary
            .filter { card in
                card.eventCodes.contains { normalizeCode($0) == normalizedCode }
            }
            .map(\.id)

        guard !cardIDs.isEmpty else { return [] }

        return [
            FlashcardDeck(
                id: sanitizeID("\(normalizedCode)-flashcards"),
                title: "\(normalizedCode) Discussion Item Flashcards",
                summary: override?.flashcardDeckSummary
                    ?? "Canonical syllabus discussion items for \(normalizedCode), ready for answer generation and event-specific study.",
                cardIDs: cardIDs
            )
        ]
    }

    private func canonicalSyllabusEvents(forPhaseID phaseID: String, categoryKind: StudyCategoryKind) -> [SyllabusEventReferenceEventRecord] {
        guard let syllabusCategory = syllabusCategoryByPhaseID[phaseID] else { return [] }

        return syllabusReference.values
            .filter { event in
                guard event.category == syllabusCategory else { return false }
                switch categoryKind {
                case .sims:
                    return event.eventKind.lowercased() == "sim"
                case .flights:
                    return event.eventKind.lowercased() == "flight"
                case .groundSchool:
                    return false
                }
            }
            .sorted { normalizeCode($0.code) < normalizeCode($1.code) }
    }

    private func groupedFilesByCanonicalCode(_ files: [URL], allowedCodes: Set<String>) -> [String: [URL]] {
        Dictionary(grouping: files.compactMap { file -> (String, URL)? in
            guard let rawCode = eventCode(from: file.lastPathComponent) else { return nil }
            let normalizedRawCode = normalizeCode(rawCode)
            let canonicalCode = canonicalAttachmentAliases[normalizedRawCode] ?? normalizedRawCode
            guard allowedCodes.contains(canonicalCode) else { return nil }
            return (canonicalCode, file)
        }, by: \.0).mapValues { $0.map(\.1) }
    }

    private func writeAuditReport(for manifest: StudyManifest) throws {
        let canonicalCodes = syllabusReference.keys.sorted()
        let manifestCodes = Set(
            manifest.phases
                .flatMap(\.categories)
                .flatMap(\.events)
                .map { normalizeCode($0.code) }
        )
        let discussionItemIssues = discussionItemAuthoringIssues()

        let report = SyllabusEventAuditReport(
            generatedAt: Date(),
            canonicalEventCount: canonicalCodes.count,
            canonicalEventsMissingFromManifest: canonicalCodes.filter { !manifestCodes.contains($0) },
            canonicalEventsMissingAuthoredNotes: canonicalCodes.filter { eventOverrides[normalizeCode($0)]?.studyNotes == nil },
            authoredNotesCoverageIssues: authoredNotesCoverageIssues(),
            discussionItemAuthoringIssues: discussionItemIssues,
            legacyAliasAttachmentsInUse: legacyAliasAttachmentIssues(),
            unresolvedEmergencyProcedureItems: unresolvedEmergencyProcedureItems,
            emergencyProcedureAliasIssues: emergencyProcedureAliasIssues,
            missingEmergencyProcedureCompanions: missingEmergencyProcedureCompanions
        )

        let encoder = JSONEncoder()
        encoder.dateEncodingStrategy = .iso8601
        encoder.outputFormatting = [.prettyPrinted, .sortedKeys]
        let data = try encoder.encode(report)
        try data.write(to: auditReportURL)
    }

    private func authoredNotesCoverageIssues() -> [AuthoredNotesCoverageIssue] {
        syllabusReference.keys.sorted().compactMap { code in
            guard let override = eventOverrides[code],
                  let studyNotes = override.studyNotes,
                  let referenceEvent = syllabusReference[code],
                  !referenceEvent.discussionItems.isEmpty else {
                return nil
            }

            let primaryItems = primaryDiscussionItems(from: studyNotes)
            let allTexts = flattenedStudyNoteTexts(from: studyNotes)

            let missingCanonicalItems = referenceEvent.discussionItems.filter { canonicalItem in
                !allTexts.contains { notesText in itemsRoughlyMatch(canonicalItem, notesText) }
            }

            let unexpectedPrimaryItems = primaryItems.filter { item in
                guard !supplementalPrimaryTitles.contains(normalizedText(item)) else { return false }
                return !referenceEvent.discussionItems.contains { canonicalItem in
                    itemsRoughlyMatch(canonicalItem, item)
                }
            }

            guard !missingCanonicalItems.isEmpty || !unexpectedPrimaryItems.isEmpty else {
                return nil
            }

            return AuthoredNotesCoverageIssue(
                code: code,
                missingCanonicalItems: missingCanonicalItems,
                unexpectedPrimaryItems: unexpectedPrimaryItems
            )
        }
    }

    private func discussionItemAuthoringIssues() -> [DiscussionItemAuthoringIssue] {
        famCanonicalEventCodes().compactMap { code in
            guard let referenceEvent = syllabusReference[code] else { return nil }
            let override = eventOverrides[code]
            let studyNotes = override?.studyNotes
            let usesStrictPerItemSections = strictPerItemSectionsEnabled(for: code)
            let overrideConfig = discussionAuthoringConfig.eventOverrides[code]

            let missingStudyNotes = studyNotes == nil
            let invalidHeadline = studyNotes?.headline != "Discussion items"
            let missingSummary = studyNotes?.summary?.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty ?? true
            let configuredSystemsBriefItems = overrideConfig?.systemsBriefItems ?? []
            let missingSystemsBriefItems = configuredSystemsBriefItems.filter { _ in
                override?.systemsBrief == nil
            }
            let invalidSystemsBriefHeadline = override?.systemsBrief != nil && override?.systemsBrief?.headline != "Systems brief"
            let boilerplateOverview = Self.containsFAMOverviewBoilerplate(override?.overview) ||
                (usesStrictPerItemSections && Self.containsReusableDiscussionOverviewBoilerplate(override?.overview))
            let boilerplateNotesSummary = Self.containsFAMNotesSummaryBoilerplate(studyNotes?.summary) ||
                (usesStrictPerItemSections && Self.containsReusableDiscussionSummaryBoilerplate(studyNotes?.summary))
            let colloquialVisiblePhrases = colloquialVisiblePhrases(in: studyNotes)
            let eventEmphasisMismatch = emphasisMismatch(
                for: code,
                override: override,
                studyNotes: studyNotes,
                keywords: overrideConfig?.eventEmphasisKeywords ?? []
            )

            let requiredProceduresSection = studyNotes?.sections.last.flatMap { section in
                normalizedText(section.title ?? "") == normalizedText("Required Procedures") ? section : nil
            }
            let missingRequiredProceduresSection = requiredProceduresSection == nil
            let actualRequiredProcedures = requiredProceduresSection?.items.map(\.text) ?? []
            let expectedRequiredProcedures = referenceEvent.discussionItems
            let normalizedActualRequiredProcedures = actualRequiredProcedures.map(normalizedText)
            let normalizedExpectedRequiredProcedures = expectedRequiredProcedures.map(normalizedText)

            let missingRequiredProcedures = expectedRequiredProcedures.filter { expected in
                !normalizedActualRequiredProcedures.contains(normalizedText(expected))
            }
            let unexpectedRequiredProcedures = actualRequiredProcedures.filter { actual in
                !normalizedExpectedRequiredProcedures.contains(normalizedText(actual))
            }
            let requiredProceduresOutOfOrder = normalizedActualRequiredProcedures != normalizedExpectedRequiredProcedures
            let requiredProceduresCasingMismatch: [String]
            if overrideConfig?.standardizeRequiredProcedureDisplay == true {
                requiredProceduresCasingMismatch = expectedRequiredProcedures.compactMap { expected in
                    guard let actual = actualRequiredProcedures.first(where: {
                        normalizedText($0) == normalizedText(expected)
                    }) else {
                        return nil
                    }
                    let standardized = Self.titleCasedDiscussionItemPrompt(expected)
                    return actual == standardized ? nil : actual
                }
            } else {
                requiredProceduresCasingMismatch = []
            }

            let coverage = override?.canonicalCoverage ?? [:]
            let normalizedCoverage = Dictionary(
                uniqueKeysWithValues: coverage.map { (normalizedText($0.key), $0.value) }
            )
            let sectionConfigs = overrideConfig?.itemSections ?? []
            let missingCanonicalCoverageItems = expectedRequiredProcedures.filter { item in
                normalizedCoverage[normalizedText(item)]?.isEmpty != false
            }
            let canonicalItemsWithoutDedicatedSection = expectedRequiredProcedures.filter { item in
                guard usesStrictPerItemSections else { return false }
                let expectedCoverageCount = expectedCoverageCount(for: item, using: sectionConfigs)
                return normalizedCoverage[normalizedText(item)]?.count != expectedCoverageCount
            }
            let splitCoverageMismatchItems = expectedRequiredProcedures.filter { item in
                guard usesStrictPerItemSections,
                      let config = itemSectionConfig(for: item, using: sectionConfigs),
                      let splitSectionTitles = config.splitSectionTitles,
                      !splitSectionTitles.isEmpty else {
                    return false
                }

                let actualTitles = Set((normalizedCoverage[normalizedText(item)] ?? []).map(normalizedText))
                let expectedTitles = Set(splitSectionTitles.map(normalizedText))
                return actualTitles != expectedTitles
            }

            let multiItemVisibleSections: [String]
            if usesStrictPerItemSections {
                var coverageBySection: [String: [String]] = [:]
                for item in expectedRequiredProcedures {
                    let mappedTitles = normalizedCoverage[normalizedText(item)] ?? []
                    for title in mappedTitles {
                        coverageBySection[normalizedText(title), default: []].append(item)
                    }
                }

                multiItemVisibleSections = coverageBySection.compactMap { normalizedTitle, items in
                    items.count > 1 ? normalizedTitle : nil
                }
            } else {
                multiItemVisibleSections = []
            }

            let sectionTitles = Set(studyNotes?.sections.compactMap(\.title).map(normalizedText) ?? [])
            let missingCoverageSectionTitles = expectedRequiredProcedures.flatMap { item -> [String] in
                let mappedTitles = normalizedCoverage[normalizedText(item)] ?? []
                return mappedTitles.filter { !sectionTitles.contains(normalizedText($0)) }
            }

            let missingEmergencyProcedureNWCItems = expectedRequiredProcedures.filter { item in
                guard Self.looksLikeEmergencyProcedureDiscussionItem(item) else { return false }
                let mappedTitles = normalizedCoverage[normalizedText(item)] ?? [item]
                let matchedSections = studyNotes?.sections.filter { section in
                    guard let title = section.title else { return false }
                    return mappedTitles.contains { normalizedText($0) == normalizedText(title) }
                } ?? []
                let sectionTexts = matchedSections.flatMap { flattenedStudyNoteTexts(from: $0) }
                return !sectionTexts.contains { text in
                    let normalized = normalizedText(text)
                    return normalized.contains("nwc") ||
                        normalized.contains("n w c") ||
                        normalized.contains("warning caution note") ||
                        normalized.contains("warning caution notes")
                }
            }

            let missingManeuverEntrySetupSections = sectionConfigs.compactMap { config -> String? in
                guard normalizedText(config.presentationStyle ?? "") == normalizedText("maneuver") else { return nil }
                let title = config.displayTitle ?? Self.titleCasedDiscussionItemPrompt(config.discussionItem)
                guard let section = studyNotes?.sections.first(where: {
                    normalizedText($0.title ?? "") == normalizedText(title)
                }) else {
                    return nil
                }

                guard sectionHasItemLabel(section, label: "Entry setup") else {
                    return title
                }

                let entryTexts = sectionTexts(forItemLabel: "Entry setup", in: section)
                let combinedEntryText = normalizedText(entryTexts.joined(separator: " "))
                let hasPowerCue = combinedEntryText.contains("pcl") || combinedEntryText.contains("power")
                let hasSpeedCue = combinedEntryText.contains("airspeed") || combinedEntryText.contains("kias")
                return (hasPowerCue && hasSpeedCue) ? nil : title
            }

            let missingManeuverCompletionCueSections = sectionConfigs.compactMap { config -> String? in
                guard normalizedText(config.presentationStyle ?? "") == normalizedText("maneuver") else { return nil }
                let title = config.displayTitle ?? Self.titleCasedDiscussionItemPrompt(config.discussionItem)
                guard let section = studyNotes?.sections.first(where: {
                    normalizedText($0.title ?? "") == normalizedText(title)
                }) else {
                    return nil
                }
                return sectionHasItemLabel(section, label: "Maneuver complete when") ? nil : title
            }

            let recoverySectionsMixingEjectLogic = sectionConfigs.compactMap { config -> String? in
                guard normalizedText(config.presentationStyle ?? "") == normalizedText("recovery") else { return nil }
                let title = config.displayTitle ?? Self.titleCasedDiscussionItemPrompt(config.discussionItem)
                guard let section = studyNotes?.sections.first(where: {
                    normalizedText($0.title ?? "") == normalizedText(title)
                }) else {
                    return nil
                }
                let recoveryTexts = sectionTexts(forItemLabel: "Recovery", in: section)
                return recoveryTexts.contains(where: { normalizedText($0).contains("eject") }) ? title : nil
            }

            let manualOnlyAutogeneratedSections = sectionConfigs.compactMap { config -> String? in
                guard config.manualOnly == true else { return nil }
                let title = config.displayTitle ?? Self.titleCasedDiscussionItemPrompt(config.discussionItem)
                guard let section = studyNotes?.sections.first(where: {
                    normalizedText($0.title ?? "") == normalizedText(title)
                }) else {
                    return title
                }

                let sectionTexts = flattenedStudyNoteTexts(from: section).map(normalizedText)
                let genericManualOnlySignals = [
                    normalizedText("Key cues"),
                    normalizedText("Key points"),
                    normalizedText("Setup cues"),
                    normalizedText("Execution priorities"),
                    normalizedText("Numbers / traps"),
                    normalizedText("Why it matters"),
                    normalizedText("Application")
                ]
                return sectionTexts.contains(where: { genericManualOnlySignals.contains($0) }) ? title : nil
            }

            let localSpecificVisibleReferences = sectionConfigs.compactMap { config -> String? in
                guard normalizedText(config.presentationStyle ?? "") == normalizedText("local-generalized") else { return nil }
                let title = config.displayTitle ?? Self.titleCasedDiscussionItemPrompt(config.discussionItem)
                guard let section = studyNotes?.sections.first(where: {
                    normalizedText($0.title ?? "") == normalizedText(title)
                }) else {
                    return nil
                }

                let texts = flattenedStudyNoteTexts(from: section)
                let offenders = localSpecificReferenceSignals(in: texts)
                guard !offenders.isEmpty else { return nil }
                return "\(title): \(offenders.joined(separator: ", "))"
            }

            guard missingStudyNotes ||
                    invalidHeadline ||
                    missingSummary ||
                    !missingSystemsBriefItems.isEmpty ||
                    invalidSystemsBriefHeadline ||
                    boilerplateOverview ||
                    boilerplateNotesSummary ||
                    !colloquialVisiblePhrases.isEmpty ||
                    eventEmphasisMismatch ||
                    missingRequiredProceduresSection ||
                    !missingRequiredProcedures.isEmpty ||
                    !unexpectedRequiredProcedures.isEmpty ||
                    requiredProceduresOutOfOrder ||
                    !requiredProceduresCasingMismatch.isEmpty ||
                    !missingCanonicalCoverageItems.isEmpty ||
                    !canonicalItemsWithoutDedicatedSection.isEmpty ||
                    !splitCoverageMismatchItems.isEmpty ||
                    !multiItemVisibleSections.isEmpty ||
                    !missingCoverageSectionTitles.isEmpty ||
                    !missingEmergencyProcedureNWCItems.isEmpty ||
                    !missingManeuverEntrySetupSections.isEmpty ||
                    !missingManeuverCompletionCueSections.isEmpty ||
                    !recoverySectionsMixingEjectLogic.isEmpty ||
                    !manualOnlyAutogeneratedSections.isEmpty ||
                    !localSpecificVisibleReferences.isEmpty else {
                return nil
            }

            return DiscussionItemAuthoringIssue(
                code: code,
                missingStudyNotes: missingStudyNotes,
                invalidHeadline: invalidHeadline,
                missingSummary: missingSummary,
                missingSystemsBriefItems: missingSystemsBriefItems,
                invalidSystemsBriefHeadline: invalidSystemsBriefHeadline,
                boilerplateOverview: boilerplateOverview,
                boilerplateNotesSummary: boilerplateNotesSummary,
                colloquialVisiblePhrases: uniqueStrings(colloquialVisiblePhrases),
                eventEmphasisMismatch: eventEmphasisMismatch,
                missingRequiredProceduresSection: missingRequiredProceduresSection,
                missingRequiredProcedures: missingRequiredProcedures,
                unexpectedRequiredProcedures: unexpectedRequiredProcedures,
                requiredProceduresOutOfOrder: requiredProceduresOutOfOrder,
                requiredProceduresCasingMismatch: requiredProceduresCasingMismatch,
                missingCanonicalCoverageItems: missingCanonicalCoverageItems,
                canonicalItemsWithoutDedicatedSection: canonicalItemsWithoutDedicatedSection,
                splitCoverageMismatchItems: splitCoverageMismatchItems,
                multiItemVisibleSections: uniqueStrings(multiItemVisibleSections),
                missingCoverageSectionTitles: uniqueStrings(missingCoverageSectionTitles),
                missingEmergencyProcedureNWCItems: missingEmergencyProcedureNWCItems,
                missingManeuverEntrySetupSections: uniqueStrings(missingManeuverEntrySetupSections),
                missingManeuverCompletionCueSections: uniqueStrings(missingManeuverCompletionCueSections),
                recoverySectionsMixingEjectLogic: uniqueStrings(recoverySectionsMixingEjectLogic),
                manualOnlyAutogeneratedSections: uniqueStrings(manualOnlyAutogeneratedSections),
                localSpecificVisibleReferences: uniqueStrings(localSpecificVisibleReferences)
            )
        }
    }

    private func primaryDiscussionItems(from notes: EventStudyNotes) -> [String] {
        var items: [String] = []

        for section in notes.sections {
            if let title = section.title?.trimmingCharacters(in: .whitespacesAndNewlines), !title.isEmpty {
                items.append(title)
            } else {
                items.append(contentsOf: section.items.map(\.text))
            }
        }

        return uniqueStrings(items)
    }

    private func flattenedStudyNoteTexts(from notes: EventStudyNotes) -> [String] {
        var texts = primaryDiscussionItems(from: notes)

        func walk(_ item: EventStudyNotesItem) {
            texts.append(item.text)
            item.children?.forEach(walk)
        }

        for section in notes.sections {
            section.items.forEach(walk)
        }

        return uniqueStrings(texts)
    }

    private func flattenedStudyNoteTexts(from section: EventStudyNotesSection) -> [String] {
        var texts: [String] = []
        if let title = section.title, !title.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty {
            texts.append(title)
        }

        func walk(_ item: EventStudyNotesItem) {
            texts.append(item.text)
            item.children?.forEach(walk)
        }

        section.items.forEach(walk)
        return uniqueStrings(texts)
    }

    private func sectionHasItemLabel(_ section: EventStudyNotesSection, label: String) -> Bool {
        section.items.contains { normalizedText($0.text) == normalizedText(label) }
    }

    private func sectionTexts(forItemLabel label: String, in section: EventStudyNotesSection) -> [String] {
        guard let item = section.items.first(where: {
            normalizedText($0.text) == normalizedText(label)
        }) else {
            return []
        }

        return flattenedStudyNoteTexts(from: item)
    }

    private func flattenedStudyNoteTexts(from item: EventStudyNotesItem) -> [String] {
        var texts = [item.text]
        item.children?.forEach { child in
            texts.append(contentsOf: flattenedStudyNoteTexts(from: child))
        }
        return uniqueStrings(texts)
    }

    private func emphasisMismatch(
        for code: String,
        override: EventOverride?,
        studyNotes: EventStudyNotes?,
        keywords: [String]
    ) -> Bool {
        let normalizedKeywords = keywords.map(normalizedText).filter { !$0.isEmpty }
        guard !normalizedKeywords.isEmpty else { return false }

        let titleText = (override?.title ?? syllabusReference[code]?.shortTitle) ?? code
        let textsToCheck = [
            titleText,
            override?.summary ?? "",
            override?.overview ?? "",
            studyNotes?.summary ?? ""
        ]

        return textsToCheck.contains { value in
            let normalizedValue = normalizedText(value)
            return !normalizedKeywords.contains(where: { normalizedValue.contains($0) })
        }
    }

    private func itemSectionConfig(
        for discussionItem: String,
        using configs: [DiscussionItemAuthoringItemSectionConfig]
    ) -> DiscussionItemAuthoringItemSectionConfig? {
        configs.first { normalizedText($0.discussionItem) == normalizedText(discussionItem) }
    }

    private func expectedCoverageCount(
        for discussionItem: String,
        using configs: [DiscussionItemAuthoringItemSectionConfig]
    ) -> Int {
        guard let config = itemSectionConfig(for: discussionItem, using: configs) else { return 1 }
        let explicitCount = config.splitSectionTitles?.count ?? 1
        return max(1, explicitCount)
    }

    private func colloquialVisiblePhrases(in studyNotes: EventStudyNotes?) -> [String] {
        guard let studyNotes else { return [] }

        let prohibitedPhrases = [
            "know the limit before you need it",
            "the whole game is",
            "cleanest pure roll",
            "in this block it should",
            "matter most in this block"
        ]

        return studyNotes.sections
            .filter { normalizedText($0.title ?? "") != normalizedText("Required Procedures") }
            .flatMap { flattenedStudyNoteTexts(from: $0) }
            .filter { text in
                let normalized = normalizedText(text)
                return prohibitedPhrases.contains(where: normalized.contains)
            }
    }

    private func localSpecificReferenceSignals(in texts: [String]) -> [String] {
        let signals = [
            "waldron",
            "rusty",
            "high bridge",
            "mustang",
            "camel humps",
            "pt sunrise",
            "pt silver",
            "beachline",
            "nueces",
            "oso",
            "shamrock",
            "corpus departure",
            "cabaniss",
            "boomer",
            "wtd"
        ]

        let flattened = texts.map(normalizedText).joined(separator: " ")
        return signals.filter { flattened.contains(normalizedText($0)) }
    }

    private func itemsRoughlyMatch(_ lhs: String, _ rhs: String) -> Bool {
        let lhsTokens = significantTokens(in: lhs)
        let rhsTokens = significantTokens(in: rhs)
        guard !lhsTokens.isEmpty, !rhsTokens.isEmpty else {
            return normalizedText(lhs) == normalizedText(rhs)
        }

        let overlap = lhsTokens.intersection(rhsTokens).count
        let requiredOverlap = min(lhsTokens.count, rhsTokens.count)
        if overlap == requiredOverlap {
            return true
        }

        return Double(overlap) / Double(requiredOverlap) >= 0.6
    }

    private func significantTokens(in value: String) -> Set<String> {
        let ignoredWords: Set<String> = [
            "a", "an", "and", "the", "to", "of", "or", "for", "in", "on", "prior",
            "with", "all", "any", "be", "is"
        ]

        return Set(
            Self.normalizedText(value)
                .split(separator: " ")
                .map(String.init)
                .filter { $0.count > 1 && !ignoredWords.contains($0) }
        )
    }

    private func famCanonicalEventCodes() -> [String] {
        syllabusReference.values
            .filter { $0.category == "familiarization" }
            .map { normalizeCode($0.code) }
            .sorted()
    }

    private func legacyAliasAttachmentIssues() -> [LegacyAliasAttachmentIssue] {
        let files = allFiles(under: rootURL)
        var grouped: [String: [String: [String]]] = [:]

        for file in files {
            guard let rawCode = eventCode(from: file.lastPathComponent) else { continue }
            let normalizedRawCode = normalizeCode(rawCode)
            guard let canonicalCode = canonicalAttachmentAliases[normalizedRawCode] else { continue }

            let relativePath = file.path.replacingOccurrences(of: rootURL.path + "/", with: "")
            grouped[canonicalCode, default: [:]][normalizedRawCode, default: []].append(relativePath)
        }

        return grouped.keys.sorted().flatMap { canonicalCode in
            grouped[canonicalCode, default: [:]].keys.sorted().map { aliasCode in
                LegacyAliasAttachmentIssue(
                    canonicalCode: canonicalCode,
                    aliasCode: aliasCode,
                    filePaths: grouped[canonicalCode]?[aliasCode, default: []].sorted() ?? []
                )
            }
        }
    }

    private static func sanitizedIdentifier(_ value: String) -> String {
        let allowed = CharacterSet.alphanumerics.union(CharacterSet(charactersIn: "-"))
        return value.lowercased()
            .map { char in
                String(char).rangeOfCharacter(from: allowed) != nil ? String(char) : "-"
            }
            .joined()
            .replacingOccurrences(of: "--", with: "-")
            .trimmingCharacters(in: CharacterSet(charactersIn: "-"))
    }

    private static func normalizedText(_ value: String) -> String {
        value
            .folding(options: [.diacriticInsensitive, .caseInsensitive], locale: .current)
            .replacingOccurrences(of: "[^a-z0-9]+", with: " ", options: .regularExpression)
            .trimmingCharacters(in: .whitespacesAndNewlines)
            .lowercased()
    }

    private func normalizedText(_ value: String) -> String {
        Self.normalizedText(value)
    }

    private func uniqueStrings(_ values: [String]) -> [String] {
        Self.uniqueStrings(values)
    }

    private func strictPerItemSectionsEnabled(for code: String) -> Bool {
        let normalizedCode = Self.normalizeCode(code)
        return !(discussionAuthoringConfig.eventOverrides[normalizedCode]?.itemSections ?? []).isEmpty
    }

    private static func uniqueStrings(_ values: [String]) -> [String] {
        var seen = Set<String>()
        var result: [String] = []

        for value in values {
            guard seen.insert(value).inserted else { continue }
            result.append(value)
        }

        return result
    }

    private static func sortedEventCodes(_ eventCodes: Set<String>) -> [String] {
        eventCodes.sorted()
    }

    private static func studyCategories(
        for eventCodes: [String],
        syllabusReference: [String: SyllabusEventReferenceEventRecord]
    ) -> [StudyCategoryKind] {
        uniqueStudyCategories(
            eventCodes.compactMap { code in
                guard let event = syllabusReference[normalizeCode(code)] else { return nil }
                return event.eventKind.lowercased() == "flight" ? .flights : .sims
            }
        )
    }

    private static func uniqueStudyCategories(_ categories: [StudyCategoryKind]) -> [StudyCategoryKind] {
        var seen = Set<StudyCategoryKind>()
        var result: [StudyCategoryKind] = []

        for category in categories {
            guard seen.insert(category).inserted else { continue }
            result.append(category)
        }

        return result
    }

    private static func parseCanonicalReferenceDeck(
        fileURL: URL,
        filter: FlashcardFilterToken,
        epGroupIDs: [String: String]
    ) throws -> [CanonicalReferenceCardTemplate] {
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

            return CanonicalReferenceCardTemplate(
                id: canonicalReferenceCardID(filter: filter, title: prompt),
                prompt: prompt,
                answer: answer,
                tags: [filter.tagValue],
                kind: filter == .ep ? .ep : .standard,
                requiresVerbatim: filter == .ep || filter == .nwc,
                companionGroupID: companionGroupID,
                normalizedTitle: groupID
            )
        }
    }

    private static func normalizedRichText(from rawXML: String) -> String {
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

    private static func canonicalReferenceCardID(filter: FlashcardFilterToken, title: String) -> String {
        sanitizedIdentifier("reference-\(filter.rawValue)-\(title)")
    }

    private static func normalizeReferenceTitle(_ title: String) -> String {
        title
            .lowercased()
            .replacingOccurrences(of: "&amp;", with: "and")
            .replacingOccurrences(of: "&", with: "and")
            .replacingOccurrences(of: "/", with: " ")
            .replacingOccurrences(of: #"[^\p{L}\p{N}]+"#, with: " ", options: .regularExpression)
            .replacingOccurrences(of: #"\s+"#, with: " ", options: .regularExpression)
            .trimmingCharacters(in: .whitespacesAndNewlines)
    }

    private static func titleCasedDiscussionItemPrompt(_ value: String) -> String {
        let trimmed = value.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !trimmed.isEmpty else { return trimmed }

        var result = trimmed.lowercased().localizedCapitalized
        let lowercaseJoiners = ["And", "Or", "Of", "In", "On", "To", "The", "A", "An"]
        for joiner in lowercaseJoiners {
            let pattern = #"(?<![-/])\b\#(joiner)\b(?![-/])"#
            result = result.replacingOccurrences(of: pattern, with: joiner.lowercased(), options: [.regularExpression])
        }

        let tokenReplacements: [(pattern: String, replacement: String)] = [
            (#"\bEp\b"#, "EP"),
            (#"\bN/W/C\b"#, "N/W/C"),
            (#"\bCrm\b"#, "CRM"),
            (#"\bPel/P\b"#, "PEL(P)"),
            (#"\bPel\b"#, "PEL"),
            (#"\bElp\b"#, "ELP"),
            (#"\bOft\b"#, "OFT"),
            (#"\bUtd/Mr\b"#, "UTD/MR"),
            (#"\bUtd\b"#, "UTD"),
            (#"\bVtd\b"#, "VTD"),
            (#"\bT-6b\b"#, "T-6B"),
            (#"\bRdo\b"#, "RDO"),
            (#"\bOlf\b"#, "OLF"),
            (#"\bSid\b"#, "SID"),
            (#"\bStar\b"#, "STAR"),
            (#"\bIls\b"#, "ILS"),
            (#"\bVfr\b"#, "VFR"),
            (#"\bIfr\b"#, "IFR"),
            (#"\bAim\b"#, "AIM"),
            (#"\bNatops\b"#, "NATOPS"),
            (#"\bCfs\b"#, "CFS"),
            (#"\bObogs\b"#, "OBOGS"),
            (#"\bPmu\b"#, "PMU"),
            (#"\bBfi\b"#, "BFI"),
            (#"\bHud\b"#, "HUD"),
            (#"\bUfcp\b"#, "UFCP"),
            (#"\bLop\b"#, "LOP"),
            (#"\bAoa\b"#, "AOA"),
            (#"\bOcf\b"#, "OCF"),
            (#"\bNws\b"#, "NWS"),
            (#"\bEicas\b"#, "EICAS"),
            (#"\bAgsm\b"#, "AGSM"),
            (#"\bTcas\b"#, "TCAS"),
            (#"\bOdo/Fdo\b"#, "ODO/FDO"),
            (#"\bOlf\b"#, "OLF"),
            (#"\bScatsafe\b"#, "SCATSAFE"),
            (#"\bSop\b"#, "SOP"),
            (#"\bTouch-And-Goes\b"#, "Touch-and-Goes")
        ]

        for replacement in tokenReplacements {
            result = result.replacingOccurrences(
                of: replacement.pattern,
                with: replacement.replacement,
                options: [.regularExpression]
            )
        }

        if let firstCharacter = result.first {
            result.replaceSubrange(result.startIndex...result.startIndex, with: String(firstCharacter).uppercased())
        }

        return result
    }

    private static func looksLikeEmergencyProcedureDiscussionItem(_ value: String) -> Bool {
        let normalized = normalizedText(value)
        let signals = [
            "abort",
            "engine failure",
            "pel",
            "elp",
            "emergency",
            "eject",
            "forced landing",
            "chip detector",
            "fire",
            "oil",
            "power changes",
            "airstart",
            "obogs",
            "fuel pressure",
            "compressor stall",
            "high fuel flow",
            "precautionary",
            "ground egress",
            "cfs"
        ]

        return signals.contains { normalized.contains($0) }
    }

    private static func containsFAMOverviewBoilerplate(_ value: String?) -> Bool {
        guard let value else { return true }
        let normalized = normalizedText(value)
        return normalized.contains("is a sim event focused on") ||
            normalized.contains("is a flight event focused on")
    }

    private static func containsReusableDiscussionOverviewBoilerplate(_ value: String?) -> Bool {
        guard let value else { return true }
        let normalized = normalizedText(value)
        return normalized.contains("this event ties together") ||
            normalized.contains("this event pulls together") ||
            normalized.contains("use this event as a cumulative review of")
    }

    private static func containsFAMNotesSummaryBoilerplate(_ value: String?) -> Bool {
        guard let value else { return true }
        let normalized = normalizedText(value)
        return normalized.contains("use these notes to cover every required discussion item in syllabus order")
    }

    private static func containsReusableDiscussionSummaryBoilerplate(_ value: String?) -> Bool {
        guard let value else { return true }
        let normalized = normalizedText(value)
        return normalized.contains("keep the event priorities organized early") ||
            normalized.contains("treat the cumulative brief like a spot check on the whole block") ||
            normalized.contains("prepare this like a cumulative check event")
    }

    private static func regexMatches(for pattern: String, in text: String) -> [String] {
        guard let regex = try? NSRegularExpression(pattern: pattern, options: [.dotMatchesLineSeparators]) else {
            return []
        }

        let range = NSRange(text.startIndex..., in: text)
        return regex.matches(in: text, range: range).compactMap { match in
            guard match.numberOfRanges > 1, let swiftRange = Range(match.range(at: 1), in: text) else { return nil }
            return String(text[swiftRange])
        }
    }

    private static func firstRegexMatch(for pattern: String, in text: String) -> String? {
        regexMatches(for: pattern, in: text).first
    }

    private func defaultResourceLinks(for phaseID: String, categoryKind: StudyCategoryKind, files: [URL]) -> [EventResourceLink] {
        _ = phaseID
        _ = categoryKind
        _ = files
        return []
    }

    private func buildSharedResources() -> [SharedResource] {
        [
            SharedResource(id: "ep-limits-key", title: "T-6B EP & OP Limits Key", summary: "Core emergency procedures and operating limits reference used throughout training.", relativePath: "Contents/6. Admin-iPad Docs/T6 Docs (NATOPS etc)/T-6B EP & OP LIMITS KEY.pdf", topicIDs: ["eps", "limits"], phaseIDs: phaseSeeds.map(\.id), tags: ["eps", "limits"], placement: .generalLibrary, librarySection: .eps),
            SharedResource(id: "ep-nwcs-admin", title: "EP NWCs", summary: "Cross-phase notes, warnings, and cautions reference for T-6 emergency procedures.", relativePath: "Contents/6. Admin-iPad Docs/T6 Docs (NATOPS etc)/EP NWCs.pdf", topicIDs: ["eps", "nwc"], phaseIDs: phaseSeeds.map(\.id), tags: ["eps", "nwc"], placement: .generalLibrary, librarySection: .nwc),
            SharedResource(id: "expanded-checklist", title: "Expanded Checklist", summary: "Reference version of the expanded checklist for recurring systems and procedures study.", relativePath: "Contents/6. Admin-iPad Docs/Hollywood (TW4)/(current) Expanded Checklist.pdf", topicIDs: ["checklists"], phaseIDs: phaseSeeds.map(\.id), tags: ["checklist"], placement: .generalLibrary, librarySection: .supplements),
            SharedResource(id: "contact-pattern-driver", title: "Landing Pattern Driver", summary: "Phase-wide contact reference for pattern setup, flow, and sight picture reminders.", relativePath: "Contents/1. FAM (Contacts)/4. Landing Px Gouge (TW4)/Landing_Pattern_T6b_Driver.pdf", topicIDs: ["pattern"], phaseIDs: ["contacts"], tags: ["pattern"], placement: .phaseKnowledge, librarySection: .supplements),
            SharedResource(id: "contact-pattern-guide", title: "Landing Pattern Guide", summary: "Reusable landing pattern reference students keep using throughout contacts.", relativePath: "Contents/1. FAM (Contacts)/4. Landing Px Gouge (TW4)/Landing Pattern PDF 2.pdf", topicIDs: ["pattern"], phaseIDs: ["contacts"], tags: ["pattern"], placement: .phaseKnowledge, librarySection: .supplements),
            SharedResource(id: "contact-pattern-slideshow", title: "Landing Pattern Slideshow", summary: "Additional visual pattern walkthrough for repeated use across contact events.", relativePath: "Contents/1. FAM (Contacts)/4. Landing Px Gouge (TW4)/landing_pattern_slideshow.pdf", topicIDs: ["pattern"], phaseIDs: ["contacts"], tags: ["pattern", "slides"], placement: .phaseKnowledge, librarySection: .supplements),
            SharedResource(id: "contact-ep-nwcs", title: "Contacts EP NWCs", summary: "Contacts-specific emergency procedure notes, warnings, and cautions study packet.", relativePath: "Contents/1. FAM (Contacts)/1. Ground School/EP NWCs.pdf", topicIDs: ["eps", "nwc"], phaseIDs: ["contacts"], tags: ["eps", "nwc"], placement: .phaseKnowledge, librarySection: .nwc),
            SharedResource(id: "instrument-ifg", title: "KNGP IFG", summary: "Instrument field guide reference that stays relevant across instrument planning and execution.", relativePath: "Contents/6. Admin-iPad Docs/KNGP IFG FY25v1.2.pdf", topicIDs: ["airfield"], phaseIDs: ["instruments"], tags: ["field-guide"], placement: .phaseKnowledge, librarySection: .supplements),
            SharedResource(id: "vnav-routes", title: "VNAV Routes", summary: "Reusable route packet for recurring VNAV planning and execution.", relativePath: "Contents/3. VNAV/VNAV Routes.pdf", topicIDs: ["routes"], phaseIDs: ["vnav"], tags: ["routes"], placement: .phaseKnowledge, librarySection: .supplements),
            SharedResource(id: "formation-supp", title: "Formation Supplement", summary: "Common formation reference for contracts, admin, and recurring procedures.", relativePath: "Contents/4. FORMS/TW4 Form Supp (JUN 24).pdf", topicIDs: ["formation"], phaseIDs: ["formation"], tags: ["supplement"], placement: .phaseKnowledge, librarySection: .supplements)
        ]
    }

    private func buildProcedureBlocks() -> [ProcedureBlock] {
        [
            ProcedureBlock(id: "mission-brief", title: "Mission brief flow", body: "Review weather, NOTAMs, profile objectives, fuel, risks, and contingencies before stepping. Confirm source references and grading emphasis for the event.", tags: ["brief"]),
            ProcedureBlock(id: "taxi-flow", title: "Taxi flow", body: "Confirm startup complete, taxi diagram ready, checklists flowing challenge-action-response, and taxi brief aligned before movement.", tags: ["taxi"]),
            ProcedureBlock(id: "takeoff-flow", title: "Takeoff flow", body: "Set lineup items from memory, confirm departure considerations, and brief the initial maneuver or departure routing before brake release.", tags: ["takeoff"]),
            ProcedureBlock(id: "mission-execution", title: "Mission execution", body: "Move event-by-event through the published profile, discussing setup, standards, and likely coaching points before each phase.", tags: ["mission"]),
            ProcedureBlock(id: "maneuver-flow", title: "Maneuver execution", body: "Use a deterministic setup: clear, configure, brief, execute, assess, and reset. Tie each maneuver back to the standards and common errors.", tags: ["maneuvers"]),
            ProcedureBlock(id: "recovery-flow", title: "Recovery flow", body: "Transition to the recovery plan, approach, pattern, or overhead as assigned. Re-brief landing considerations and after-landing priorities before shutdown.", tags: ["recovery"])
        ]
    }

    private func buildCalloutBlocks() -> [CalloutBlock] {
        [
            CalloutBlock(id: "ground-comm", title: "Ground / taxi comms", body: "Request taxi with location, ATIS, and mission intent. Read back taxi instructions fully and confirm hold shorts, crossings, and runway changes.", tags: ["comms"]),
            CalloutBlock(id: "tower-comm", title: "Tower / takeoff comms", body: "Use standard ready-for-departure phrasing, read back takeoff clearance, and verbalize immediate post-takeoff actions before the roll.", tags: ["comms"]),
            CalloutBlock(id: "approach-comm", title: "Approach / radar comms", body: "State callsign, current position, altitude, and request. Read back approach, hold, or vector instructions with the key restrictions intact.", tags: ["comms"]),
            CalloutBlock(id: "pattern-comm", title: "Pattern / landing comms", body: "Use standard pattern entry and landing verbiage. Confirm runway, traffic, touch-and-go or full-stop intent, and go-around plan.", tags: ["comms"])
        ]
    }

    private func extractText(from file: URL) -> String? {
        let ext = file.pathExtension.lowercased()
        guard ext == "docx" || ext == "doc" else { return nil }

        let process = Process()
        process.executableURL = URL(fileURLWithPath: "/usr/bin/textutil")
        process.arguments = ["-convert", "txt", "-stdout", file.path]

        let pipe = Pipe()
        process.standardOutput = pipe
        process.standardError = Pipe()

        do {
            try process.run()
            let timeoutDate = Date().addingTimeInterval(2.5)
            while process.isRunning && Date() < timeoutDate {
                Thread.sleep(forTimeInterval: 0.05)
            }

            if process.isRunning {
                process.terminate()
                return nil
            }

            guard process.terminationStatus == 0 else { return nil }
            let data = pipe.fileHandleForReading.readDataToEndOfFile()
            return String(decoding: data, as: UTF8.self)
        } catch {
            return nil
        }
    }

    private func allFiles(under root: URL) -> [URL] {
        let enumerator = fileManager.enumerator(at: root, includingPropertiesForKeys: nil)
        var results: [URL] = []
        while let item = enumerator?.nextObject() as? URL {
            var isDirectory: ObjCBool = false
            guard fileManager.fileExists(atPath: item.path, isDirectory: &isDirectory), !isDirectory.boolValue else { continue }
            results.append(item)
        }
        return results
    }

    private func eventCode(from filename: String) -> String? {
        Self.inferredEventCode(from: filename)
    }

    private func normalizeCode(_ value: String) -> String {
        Self.normalizeCode(value)
    }

    private func sanitizeID(_ value: String) -> String {
        let allowed = CharacterSet.alphanumerics.union(CharacterSet(charactersIn: "-"))
        return value.lowercased()
            .map { char in
                String(char).rangeOfCharacter(from: allowed) != nil ? String(char) : "-"
            }
            .joined()
            .replacingOccurrences(of: "--", with: "-")
            .trimmingCharacters(in: CharacterSet(charactersIn: "-"))
    }

    private func sourceDocumentKind(for filename: String) -> SourceDocumentKind {
        let name = filename.lowercased()
        if name.contains("briefing guide") { return .briefingGuide }
        if name.contains("1801") || name.contains("mr") || name.contains("gradesheet") { return .gradeSheet }
        if name.contains("scenario") { return .scenario }
        if name.contains("prax") || name.contains("questions") { return .worksheet }
        if name.contains("handout") { return .handout }
        if name.contains("fti") || name.contains("sop") || name.contains("natops") { return .reference }
        return .sourceText
    }

    private func documentSummary(for filename: String) -> String {
        switch sourceDocumentKind(for: filename) {
        case .briefingGuide: return "Primary event briefing packet."
        case .gradeSheet: return "Performance and grading reference."
        case .scenario: return "Scenario or route setup for the event."
        case .sourceText: return "Source document tied to this event."
        case .handout: return "Reference handout for prep."
        case .worksheet: return "Worksheet or practice-question source."
        case .reference: return "Shared reference tied to procedures or standards."
        }
    }

    private func inferTitle(for code: String, from files: [URL]) -> String {
        let best = files.first { $0.pathExtension.lowercased() == "docx" }?.deletingPathExtension().lastPathComponent ?? code
        let cleaned = best.replacingOccurrences(of: code, with: "").trimmingCharacters(in: CharacterSet(charactersIn: " -_()"))
        return cleaned.isEmpty ? "Event \(code)" : cleaned
    }

    private func resolvePrimaryDocumentIDs(from documents: [SourceDocument], override: EventOverride?) -> [String] {
        if let overrideTitles = override?.primaryDocumentTitles, !overrideTitles.isEmpty {
            let ids = overrideTitles.compactMap { title in
                documents.first { $0.title == title }?.id
            }
            if !ids.isEmpty { return ids }
        }

        let briefingGuideIDs = documents.filter { $0.kind == .briefingGuide }.map(\.id)
        if !briefingGuideIDs.isEmpty { return briefingGuideIDs }
        return documents.first.map { [$0.id] } ?? []
    }

    private func summaryText(from overview: String) -> String {
        let trimmed = overview.trimmingCharacters(in: .whitespacesAndNewlines)
        guard trimmed.count > 120 else { return trimmed }
        let index = trimmed.index(trimmed.startIndex, offsetBy: 117)
        return String(trimmed[..<index]) + "..."
    }

    private func syntheticCodeSuffix(for categoryKind: StudyCategoryKind) -> String {
        switch categoryKind {
        case .groundSchool: "GS"
        case .sims: "SIM"
        case .flights: "FLT"
        }
    }

    private func dedupeLinks(_ links: [EventResourceLink]) -> [EventResourceLink] {
        var seen = Set<String>()
        var result: [EventResourceLink] = []
        for link in links {
            guard !seen.contains(link.resourceID) else { continue }
            seen.insert(link.resourceID)
            result.append(link)
        }
        return result
    }

    private func isQuestionFile(_ filename: String) -> Bool {
        let value = filename.lowercased()
        return value.contains("prax") || value.contains("questions") || value.contains("practice test")
    }

    private func isUserVisibleDocumentFile(_ file: URL) -> Bool {
        let ext = file.pathExtension.lowercased()
        guard ext != "doc", ext != "docx" else { return false }
        return true
    }

    private func isStudyNoteFile(_ file: URL) -> Bool {
        let filename = file.lastPathComponent.lowercased()
        guard ["docx", "doc"].contains(file.pathExtension.lowercased()) else { return false }
        if isQuestionFile(filename) { return false }
        return filename.contains("gouge") ||
            filename.contains("outline") ||
            filename.contains("study guide") ||
            filename.contains("tlos") ||
            eventCode(from: file.lastPathComponent) != nil
    }

    private func contentLines(from text: String) -> [String] {
        text
            .components(separatedBy: .newlines)
            .map { $0.replacingOccurrences(of: "\t", with: " ").trimmingCharacters(in: .whitespacesAndNewlines) }
            .map { $0.replacingOccurrences(of: "•", with: "").trimmingCharacters(in: .whitespacesAndNewlines) }
            .filter { !$0.isEmpty }
            .filter { !$0.lowercased().hasSuffix(".docx") }
    }

    private func studyPairs(from lines: [String], code: String) -> [(prompt: String, answer: String)] {
        var pairs: [(prompt: String, answer: String)] = []
        var index = 0

        while index < lines.count - 1 {
            let prompt = lines[index]
            let next = lines[index + 1]

            guard isLikelyPrompt(prompt),
                  !prompt.localizedCaseInsensitiveContains(code),
                  !isLikelyPrompt(next) else {
                index += 1
                continue
            }

            var answerLines = [next]
            var probe = index + 2
            while probe < lines.count && !isLikelyPrompt(lines[probe]) && answerLines.count < 4 {
                answerLines.append(lines[probe])
                probe += 1
            }

            pairs.append((prompt: prompt, answer: answerLines.joined(separator: " ")))
            index = probe
        }

        return pairs
    }

    private func shorten(_ text: String, maxLength: Int) -> String {
        let collapsed = text.replacingOccurrences(of: "\n", with: " ")
            .replacingOccurrences(of: "  ", with: " ")
            .trimmingCharacters(in: .whitespacesAndNewlines)

        guard collapsed.count > maxLength else { return collapsed }
        let index = collapsed.index(collapsed.startIndex, offsetBy: maxLength - 3)
        return String(collapsed[..<index]) + "..."
    }

    private func isLikelyPrompt(_ line: String) -> Bool {
        if isLikelyQuestion(line) { return true }
        if line.count <= 65 { return true }
        if line.hasSuffix(":") { return true }
        return false
    }

    private func isLikelyQuestion(_ line: String) -> Bool {
        line.contains("?") || line.localizedCaseInsensitiveContains("(t/f)") || line.localizedCaseInsensitiveContains("what ")
    }
}

let arguments = CommandLine.arguments
let sourcePath = arguments.dropFirst().first ?? "Contents"
let outputPath = arguments.dropFirst(2).first ?? "Primary Gouge/AppContent/StudyManifest.json"

let sourceURL = URL(fileURLWithPath: sourcePath, relativeTo: URL(fileURLWithPath: FileManager.default.currentDirectoryPath)).standardizedFileURL
let outputURL = URL(fileURLWithPath: outputPath, relativeTo: URL(fileURLWithPath: FileManager.default.currentDirectoryPath)).standardizedFileURL

let builder = try ManifestBuilder(rootURL: sourceURL)
let manifest = try builder.build()
let encoder = JSONEncoder()
encoder.outputFormatting = [.prettyPrinted, .sortedKeys]
let data = try encoder.encode(manifest)
try data.write(to: outputURL)
print("Wrote manifest to \(outputURL.path)")
