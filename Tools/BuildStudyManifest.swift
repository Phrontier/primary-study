import Foundation

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
    let summary: String
    let focusAreas: [String]
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
    let tags: [String]
    let studyCategories: [StudyCategoryKind]
    let eventCodes: [String]
    let kind: FlashcardKind
    let requiresVerbatim: Bool
    let companionGroupID: String?
}

struct ReferenceStudyConfigFile: Codable {
    let libraryStudyHubs: [ReferenceStudyHubConfig]
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

struct EventOverride: Codable {
    let code: String
    let title: String?
    let summary: String?
    let overview: String?
    let studyNotes: EventStudyNotes?
    let primaryDocumentTitles: [String]?
    let sharedResources: [EventResourceLink]?
    let videos: [EventVideoLink]?
}

struct VideoLibraryFile: Codable {
    let videos: [VideoAsset]
}

struct FlashcardLibraryFile: Codable {
    let flashcards: [FlashcardDefinition]
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
    let flashcardLibrary: [FlashcardDefinition]
    let referenceStudyConfig: ReferenceStudyConfigFile

    private let phaseSeeds: [PhaseSeed] = [
        PhaseSeed(folderName: "1. FAM (Contacts)", id: "contacts", title: "Contacts", summary: "Contact phase prep with aircraft systems, procedures, patterns, and foundational flying workflows.", iconName: "figure.run"),
        PhaseSeed(folderName: "2. INSTRUMENTS", id: "instruments", title: "Instruments", summary: "Instrument academics, sims, and flights centered on approaches, holding, planning, and IFR execution.", iconName: "dial.medium"),
        PhaseSeed(folderName: "3. VNAV", id: "vnav", title: "VNAV", summary: "Visual navigation events and route-building study material that bridge planning with execution.", iconName: "map.fill"),
        PhaseSeed(folderName: "4. FORMS", id: "formation", title: "Formation", summary: "Formation academics and sorties with reusable procedures, cues, and debrief-ready study tools.", iconName: "square.3.layers.3d.down.right"),
        PhaseSeed(folderName: "5. CAPSTONE", id: "capstone", title: "Capstone", summary: "Capstone check-event prep with integrated planning, procedures, and performance review material.", iconName: "flag.checkered.2.crossed")
    ]

    private let categoryDirectoryMap: [(prefix: String, kind: StudyCategoryKind, summary: String)] = [
        ("1. Ground School", .groundSchool, "Exam-focused academics with notes, flashcards, and practice tests."),
        ("2. Sims", .sims, "Scripted simulator events with briefing guides, scenarios, and procedural study tools."),
        ("3. Flights", .flights, "Student-planned flight events with gradesheets, procedures, shared references, and execution aids.")
    ]

    init(rootURL: URL) {
        self.rootURL = rootURL

        let currentDirectory = URL(fileURLWithPath: FileManager.default.currentDirectoryPath)
        let overridesURL = currentDirectory.appendingPathComponent("Primary Gouge/AppContent/EventOverrides.json")
        let videosURL = currentDirectory.appendingPathComponent("Primary Gouge/AppContent/VideoLibrary.json")
        let flashcardsURL = currentDirectory.appendingPathComponent("Primary Gouge/AppContent/FlashcardLibrary.json")
        let referenceConfigURL = currentDirectory.appendingPathComponent("Primary Gouge/AppContent/ReferenceStudyConfig.json")

        if let data = try? Data(contentsOf: overridesURL),
           let file = try? JSONDecoder().decode(EventOverrideFile.self, from: data) {
            self.eventOverrides = Dictionary(uniqueKeysWithValues: file.events.map { ($0.code.replacingOccurrences(of: " ", with: ""), $0) })
        } else {
            self.eventOverrides = [:]
        }

        if let data = try? Data(contentsOf: videosURL),
           let file = try? JSONDecoder().decode(VideoLibraryFile.self, from: data) {
            self.videoLibrary = file.videos
        } else {
            self.videoLibrary = []
        }

        if let data = try? Data(contentsOf: flashcardsURL),
           let file = try? JSONDecoder().decode(FlashcardLibraryFile.self, from: data) {
            self.flashcardLibrary = file.flashcards
        } else {
            self.flashcardLibrary = []
        }

        if let data = try? Data(contentsOf: referenceConfigURL),
           let file = try? JSONDecoder().decode(ReferenceStudyConfigFile.self, from: data) {
            self.referenceStudyConfig = file
        } else {
            self.referenceStudyConfig = ReferenceStudyConfigFile(libraryStudyHubs: [])
        }
    }

    func build() throws -> StudyManifest {
        let phases = try phaseSeeds.map { try buildPhase(from: $0) }
        let flashcards = flashcardLibrary
        let sharedResources = buildSharedResources()
        let libraryStudyHubs = buildLibraryStudyHubs()
        let videos = videoLibrary
        let procedureBlocks = buildProcedureBlocks()
        let calloutBlocks = buildCalloutBlocks()
        return StudyManifest(phases: phases, flashcards: flashcards, sharedResources: sharedResources, libraryStudyHubs: libraryStudyHubs, videos: videos, procedureBlocks: procedureBlocks, calloutBlocks: calloutBlocks)
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

    private func buildEvent(code: String, files: [URL], phaseID: String, categoryKind: StudyCategoryKind) -> Event {
        let sortedFiles = files.sorted { $0.lastPathComponent < $1.lastPathComponent }
        let sourceDocuments = sortedFiles.filter(isUserVisibleDocumentFile(_:)).map(buildSourceDocument)
        let override = eventOverrides[normalizeCode(code)]

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
        let studyNotes = override?.studyNotes ?? noteText.flatMap { buildStudyNotes(from: $0, code: code, categoryKind: categoryKind) }
        let primaryDocumentIDs = resolvePrimaryDocumentIDs(from: sourceDocuments, override: override)
        let flashcardDecks = resolvedFlashcardDecks(for: code)

        let scriptTemplate = buildScriptTemplate(for: code, phaseID: phaseID, categoryKind: categoryKind)
        let resourceLinks = override?.sharedResources ?? defaultResourceLinks(for: phaseID, categoryKind: categoryKind, files: sortedFiles)
        let videoLinks = override?.videos ?? []
        let title = override?.title ?? inferTitle(for: code, from: sortedFiles)
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
            primaryDocumentIDs: primaryDocumentIDs,
            flashcardDecks: flashcardDecks,
            questionBanks: questionBanks,
            scriptTemplate: scriptTemplate,
            resourceLinks: resourceLinks,
            videoLinks: videoLinks,
            tags: [phaseID, categoryKind.rawValue]
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
            headline: "What to focus on",
            summary: summary,
            focusAreas: Array(focusAreas)
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

    private func resolvedFlashcardDecks(for code: String) -> [FlashcardDeck] {
        let normalizedCode = normalizeCode(code)
        let cardIDs = flashcardLibrary
            .filter { card in
                card.eventCodes.contains { normalizeCode($0) == normalizedCode }
            }
            .map(\.id)

        guard !cardIDs.isEmpty else { return [] }

        return [
            FlashcardDeck(
                id: sanitizeID("\(normalizedCode)-flashcards"),
                title: "Discussion Items",
                summary: "Official discussion items and repeated memory references for focused recall practice.",
                cardIDs: cardIDs
            )
        ]
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
        let patterns = [
            #"[A-Z]{1,4}\s?\d{4}"#,
            #"CS\s?\d{4}"#
        ]

        for pattern in patterns {
            if let regex = try? NSRegularExpression(pattern: pattern) {
                let range = NSRange(location: 0, length: filename.utf16.count)
                if let match = regex.firstMatch(in: filename, range: range),
                   let swiftRange = Range(match.range, in: filename) {
                    return String(filename[swiftRange])
                }
            }
        }
        return nil
    }

    private func normalizeCode(_ value: String) -> String {
        value.replacingOccurrences(of: " ", with: "")
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

let builder = ManifestBuilder(rootURL: sourceURL)
let manifest = try builder.build()
let encoder = JSONEncoder()
encoder.outputFormatting = [.prettyPrinted, .sortedKeys]
let data = try encoder.encode(manifest)
try data.write(to: outputURL)
print("Wrote manifest to \(outputURL.path)")
