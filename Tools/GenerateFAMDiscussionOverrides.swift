import Foundation
import PDFKit

// This tool is intentionally a source-harvesting draft generator.
// Its output should be treated as a starting point for manual authoring,
// not as the final student-facing discussion-item voice.

struct SyllabusEventReferenceFile: Decodable {
    let events: [SyllabusEventReferenceEventRecord]
}

struct SyllabusEventReferenceEventRecord: Decodable {
    let code: String
    let shortTitle: String
    let category: String
    let media: String
    let eventKind: String
    let blockCode: String
    let blockTitle: String
    let discussionItems: [String]
    let legacyReviewAliases: [String]
}

struct ReferenceStudyConfigFile: Decodable {
    let discussionItemEmergencyProcedureAliases: [String: String]?
}

struct FAMDiscussionAuthoringConfigFile: Decodable {
    let lockedEvents: [String]
    let blockDefaults: [String: FAMAuthoringBlockDefaults]
    let eventOverrides: [String: FAMDiscussionAuthoringEventOverride]
}

struct FAMAuthoringBlockDefaults: Decodable {
    let maxGroupedChildrenPerItem: Int?
    let maxStandaloneBullets: Int?
    let maxStandaloneChildren: Int?
    let fallbackSourceTitles: [String]?
    let preserveExistingVisibleContent: Bool?
}

struct FAMDiscussionAuthoringEventOverride: Decodable {
    let authoringProfile: String?
    let preserveExistingVisibleContent: Bool?
    let sections: [FAMDiscussionAuthoringSection]?
    let summary: String?
    let overview: String?
    let notesSummary: String?
    let fallbackSourceTitles: [String]?
}

struct FAMDiscussionAuthoringSection: Decodable {
    let title: String
    let discussionItems: [String]
    let sourceKeywordHints: [String]?
}

struct FAMResolvedSectionDefinition {
    let title: String
    let discussionItems: [String]
    let sourceKeywordHints: [String]
}

enum FAMAuthoringProfile: String {
    case sim
    case flight
    case reviewSim
    case checkFlight
    case solo
}

struct ExistingOverride: Decodable {
    let code: String
    let title: String?
    let summary: String?
    let overview: String?
    let canonicalCoverage: [String: [String]]?
    let primaryDocumentTitles: [String]?
    let studyNotes: ExistingStudyNotes?
}

struct ExistingStudyNotes: Decodable {
    let headline: String
    let summary: String?
    let sections: [ExistingStudyNotesSection]
}

struct ExistingStudyNotesSection: Decodable {
    let title: String?
    let items: [ExistingStudyNotesItem]
}

struct ExistingStudyNotesItem: Decodable {
    let text: String
    let children: [ExistingStudyNotesItem]?
}

struct EventContentOverrideOutput: Encodable {
    let code: String
    let title: String
    let summary: String
    let overview: String
    let canonicalCoverage: [String: [String]]
    let primaryDocumentTitles: [String]
    let studyNotes: StudyNotesOutput
}

struct StudyNotesOutput: Encodable {
    let headline: String
    let summary: String
    let sections: [StudyNotesSectionOutput]
}

struct StudyNotesSectionOutput: Encodable {
    let title: String?
    let items: [StudyNotesItemOutput]
}

struct StudyNotesItemOutput: Encodable {
    let text: String
    let children: [StudyNotesItemOutput]?
}

struct ReferenceCardTemplate {
    let prompt: String
    let answer: String
    let normalizedTitle: String
}

struct EventDocumentContext {
    let primaryTitles: [String]
    let primaryLinesByTitle: [String: [String]]
    let supplementalLinesByTitle: [String: [String]]
}

enum DiscussionItemStyle {
    case knowledge
    case maneuver
    case emergencyProcedure
}

let cwd = URL(fileURLWithPath: FileManager.default.currentDirectoryPath)
let appContentURL = cwd.appendingPathComponent("Primary Gouge/AppContent", isDirectory: true)
let overridesURL = appContentURL.appendingPathComponent("EventContentOverrides", isDirectory: true)
let famAuthoringConfigURL = overridesURL.appendingPathComponent("FAMDiscussionAuthoringConfig.json")
let syllabusReferenceURL = appContentURL.appendingPathComponent("SyllabusEventReference.json")
let referenceConfigURL = appContentURL.appendingPathComponent("ReferenceStudyConfig.json")
let xmlDirectoryURL = appContentURL.appendingPathComponent("XMLSources", isDirectory: true)
let famContentsURL = cwd.appendingPathComponent("Contents/1. FAM (Contacts)", isDirectory: true)
let contactFTIURL = URL(fileURLWithPath: "/Users/conwaybolt/Library/CloudStorage/OneDrive-Personal/Documents/Marine Corps/Flight School/MATSG-22/Pubs/Contact FTI.pdf")

let referenceDecoder = JSONDecoder()
referenceDecoder.dateDecodingStrategy = .iso8601
let referenceData = try Data(contentsOf: syllabusReferenceURL)
let referenceFile = try referenceDecoder.decode(SyllabusEventReferenceFile.self, from: referenceData)

let famEvents = referenceFile.events
    .filter { $0.category == "familiarization" }
    .sorted { normalizeCode($0.code) < normalizeCode($1.code) }

let referenceConfig: ReferenceStudyConfigFile
if let data = try? Data(contentsOf: referenceConfigURL),
   let decoded = try? JSONDecoder().decode(ReferenceStudyConfigFile.self, from: data) {
    referenceConfig = decoded
} else {
    referenceConfig = ReferenceStudyConfigFile(discussionItemEmergencyProcedureAliases: [:])
}

let famAuthoringConfig: FAMDiscussionAuthoringConfigFile
if let data = try? Data(contentsOf: famAuthoringConfigURL),
   let decoded = try? JSONDecoder().decode(FAMDiscussionAuthoringConfigFile.self, from: data) {
    famAuthoringConfig = decoded
} else {
    famAuthoringConfig = FAMDiscussionAuthoringConfigFile(
        lockedEvents: [],
        blockDefaults: [:],
        eventOverrides: [:]
    )
}

let emergencyProcedureAliases = Dictionary(
    uniqueKeysWithValues: (referenceConfig.discussionItemEmergencyProcedureAliases ?? [:]).map {
        (normalizedText($0.key), normalizeReferenceTitle($0.value))
    }
)

let epCards = try parseReferenceCards(from: xmlDirectoryURL.appendingPathComponent("T-6 EP's.xml"))
let nwcCards = try parseReferenceCards(from: xmlDirectoryURL.appendingPathComponent("EP's N_W_C.xml"))
let epCardsByTitle = dictionaryLastWins(epCards.map { ($0.normalizedTitle, $0) })
let nwcCardsByTitle = dictionaryLastWins(nwcCards.map { ($0.normalizedTitle, $0) })

let canonicalAliasMap = dictionaryLastWins(famEvents.flatMap { event in
    event.legacyReviewAliases.map { (normalizeCode($0), normalizeCode(event.code)) }
})

let existingOverrides = loadExistingOverrides(at: overridesURL)
let allFamFiles = allFiles(under: famContentsURL).filter {
    let ext = $0.pathExtension.lowercased()
    return ext == "docx" || ext == "pdf"
}
let courseRulesCorpusURL = allFamFiles.first { $0.lastPathComponent == "Course Rules Corpus.docx" }
let famBasicManeuversURL = allFamFiles.first { $0.lastPathComponent == "FAM Basic Maneuvers.docx" }
let fam4304URL = allFamFiles.first { normalizeCode(inferredEventCode(from: $0.lastPathComponent) ?? "") == "FAM4304" && $0.pathExtension.lowercased() == "docx" }
let fam4490AliasURL = allFamFiles.first { normalizeCode(inferredEventCode(from: $0.lastPathComponent) ?? "") == "FAM4401" && $0.pathExtension.lowercased() == "docx" }

var extractionCache: [String: [String]] = [:]

for event in famEvents {
    let output = buildOverride(
        for: event,
        famEvents: famEvents,
        allFamFiles: allFamFiles,
        canonicalAliasMap: canonicalAliasMap,
        existingOverrides: existingOverrides,
        epCardsByTitle: epCardsByTitle,
        nwcCardsByTitle: nwcCardsByTitle,
        emergencyProcedureAliases: emergencyProcedureAliases,
        extractionCache: &extractionCache,
        courseRulesCorpusURL: courseRulesCorpusURL,
        famBasicManeuversURL: famBasicManeuversURL,
        fam4304URL: fam4304URL,
        fam4490AliasURL: fam4490AliasURL
    )

    let outputURL = overridesURL.appendingPathComponent("\(normalizeCode(event.code)).json")
    try writeOverride(output, to: outputURL)
    print("Generated \(outputURL.lastPathComponent)")
}

private func buildOverride(
    for event: SyllabusEventReferenceEventRecord,
    famEvents: [SyllabusEventReferenceEventRecord],
    allFamFiles: [URL],
    canonicalAliasMap: [String: String],
    existingOverrides: [String: ExistingOverride],
    epCardsByTitle: [String: ReferenceCardTemplate],
    nwcCardsByTitle: [String: ReferenceCardTemplate],
    emergencyProcedureAliases: [String: String],
    extractionCache: inout [String: [String]],
    courseRulesCorpusURL: URL?,
    famBasicManeuversURL: URL?,
    fam4304URL: URL?,
    fam4490AliasURL: URL?
) -> EventContentOverrideOutput {
    let normalizedCode = normalizeCode(event.code)
    let existingOverride = existingOverrides[normalizedCode]
    let authoringOverride = famAuthoringConfig.eventOverrides[normalizedCode]
    let authoringProfile = resolvedAuthoringProfile(for: event, override: authoringOverride)

    let context = buildEventDocumentContext(
        for: event,
        allFamFiles: allFamFiles,
        canonicalAliasMap: canonicalAliasMap,
        extractionCache: &extractionCache,
        courseRulesCorpusURL: courseRulesCorpusURL,
        famBasicManeuversURL: famBasicManeuversURL,
        fam4304URL: fam4304URL,
        fam4490AliasURL: fam4490AliasURL,
        authoringOverride: authoringOverride,
        authoringProfile: authoringProfile
    )

    if lockedEventCodes().contains(normalizedCode),
       let existingOverride {
        return preservedLockedOverride(
            existingOverride,
            for: event,
            authoringProfile: authoringProfile,
            context: context
        )
    }

    let priorEvents = famEvents.filter { normalizeCode($0.code) < normalizedCode }
    let sectionDefinitions = resolvedSectionDefinitions(for: event, override: authoringOverride)
    var sections: [StudyNotesSectionOutput] = []
    var canonicalCoverage: [String: [String]] = [:]

    for sectionDefinition in sectionDefinitions {
        let section = buildReadableSection(
            definition: sectionDefinition,
            event: event,
            authoringProfile: authoringProfile,
            existingOverride: existingOverride,
            priorEvents: priorEvents,
            context: context,
            epCardsByTitle: epCardsByTitle,
            nwcCardsByTitle: nwcCardsByTitle,
            emergencyProcedureAliases: emergencyProcedureAliases
        )
        sections.append(section)

        for item in sectionDefinition.discussionItems {
            canonicalCoverage[item] = [sectionDefinition.title]
        }
    }

    sections.append(
        StudyNotesSectionOutput(
            title: "Required Procedures",
            items: event.discussionItems.map { StudyNotesItemOutput(text: $0, children: nil) }
        )
    )

    let summary = authoringOverride?.summary
        ?? buildEventSummary(for: event, sections: sectionDefinitions)
    let overview = authoringOverride?.overview
        ?? buildEventOverview(for: event, authoringProfile: authoringProfile, sections: sectionDefinitions)
    let notesSummary = authoringOverride?.notesSummary
        ?? buildStudyNotesSummary(for: event, authoringProfile: authoringProfile, sections: sectionDefinitions)

    return EventContentOverrideOutput(
        code: normalizedCode,
        title: event.shortTitle,
        summary: summary,
        overview: overview,
        canonicalCoverage: canonicalCoverage,
        primaryDocumentTitles: context.primaryTitles,
        studyNotes: StudyNotesOutput(
            headline: "Discussion items",
            summary: notesSummary,
            sections: sections
        )
    )
}

private func lockedEventCodes() -> Set<String> {
    Set(famAuthoringConfig.lockedEvents.map(normalizeCode))
}

private func resolvedAuthoringProfile(
    for event: SyllabusEventReferenceEventRecord,
    override: FAMDiscussionAuthoringEventOverride?
) -> FAMAuthoringProfile {
    if let rawValue = override?.authoringProfile?.trimmingCharacters(in: .whitespacesAndNewlines).lowercased(),
       let profile = FAMAuthoringProfile(rawValue: rawValue) {
        return profile
    }

    let code = normalizeCode(event.code)
    if code == "FAM4490" {
        return .checkFlight
    }
    if code == "FAM4501" {
        return .solo
    }
    if event.eventKind.lowercased() == "flight" {
        return .flight
    }
    if event.blockCode.hasPrefix("FAM6") {
        return .reviewSim
    }
    return .sim
}

private func resolvedSectionDefinitions(
    for event: SyllabusEventReferenceEventRecord,
    override: FAMDiscussionAuthoringEventOverride?
) -> [FAMResolvedSectionDefinition] {
    if let sections = override?.sections, !sections.isEmpty {
        return sections.map {
            FAMResolvedSectionDefinition(
                title: $0.title,
                discussionItems: $0.discussionItems,
                sourceKeywordHints: $0.sourceKeywordHints ?? []
            )
        }
    }

    return event.discussionItems.map { item in
        FAMResolvedSectionDefinition(
            title: titleCasedDiscussionItemPrompt(item),
            discussionItems: [item],
            sourceKeywordHints: []
        )
    }
}

private func preservedLockedOverride(
    _ existingOverride: ExistingOverride,
    for event: SyllabusEventReferenceEventRecord,
    authoringProfile: FAMAuthoringProfile,
    context: EventDocumentContext
) -> EventContentOverrideOutput {
    let existingNotes = existingOverride.studyNotes
    let sectionDefinitions = (existingNotes?.sections ?? []).compactMap { section -> FAMResolvedSectionDefinition? in
        guard let title = section.title,
              normalizedText(title) != normalizedText("Required Procedures") else {
            return nil
        }

        let mappedItems = (existingOverride.canonicalCoverage ?? [:]).compactMap { key, value -> String? in
            value.contains { normalizedText($0) == normalizedText(title) } ? key : nil
        }

        return FAMResolvedSectionDefinition(
            title: title,
            discussionItems: uniqueStrings(mappedItems),
            sourceKeywordHints: []
        )
    }

    let summary = existingOverride.summary ?? buildEventSummary(for: event, sections: sectionDefinitions)
    let overview = isBoilerplateOverview(existingOverride.overview)
        ? buildEventOverview(for: event, authoringProfile: authoringProfile, sections: sectionDefinitions)
        : (existingOverride.overview ?? buildEventOverview(for: event, authoringProfile: authoringProfile, sections: sectionDefinitions))
    let notesSummary = isBoilerplateNotesSummary(existingNotes?.summary)
        ? buildStudyNotesSummary(for: event, authoringProfile: authoringProfile, sections: sectionDefinitions)
        : (existingNotes?.summary ?? buildStudyNotesSummary(for: event, authoringProfile: authoringProfile, sections: sectionDefinitions))

    let notes = StudyNotesOutput(
        headline: existingNotes?.headline ?? "Discussion items",
        summary: notesSummary,
        sections: (existingNotes?.sections ?? []).map { section in
            StudyNotesSectionOutput(
                title: section.title,
                items: section.items.map(convertExistingItem)
            )
        }
    )

    return EventContentOverrideOutput(
        code: normalizeCode(event.code),
        title: existingOverride.title ?? event.shortTitle,
        summary: summary,
        overview: overview,
        canonicalCoverage: existingOverride.canonicalCoverage ?? [:],
        primaryDocumentTitles: existingOverride.primaryDocumentTitles ?? context.primaryTitles,
        studyNotes: notes
    )
}

private func convertExistingItem(_ item: ExistingStudyNotesItem) -> StudyNotesItemOutput {
    StudyNotesItemOutput(
        text: item.text,
        children: item.children?.map(convertExistingItem)
    )
}

private func buildEventDocumentContext(
    for event: SyllabusEventReferenceEventRecord,
    allFamFiles: [URL],
    canonicalAliasMap: [String: String],
    extractionCache: inout [String: [String]],
    courseRulesCorpusURL: URL?,
    famBasicManeuversURL: URL?,
    fam4304URL: URL?,
    fam4490AliasURL: URL?,
    authoringOverride: FAMDiscussionAuthoringEventOverride?,
    authoringProfile: FAMAuthoringProfile
) -> EventDocumentContext {
    let normalizedCode = normalizeCode(event.code)
    let primaryFiles = allFamFiles
        .filter { file in
            guard let rawCode = inferredEventCode(from: file.lastPathComponent) else { return false }
            let canonicalCode = canonicalAliasMap[normalizeCode(rawCode)] ?? normalizeCode(rawCode)
            return canonicalCode == normalizedCode
        }
        .sorted(by: sourceFileSort)

    var supplementalFiles: [URL] = []
    if event.discussionItems.contains(where: needsCourseRulesSupplement(_:)), let courseRulesCorpusURL {
        supplementalFiles.append(courseRulesCorpusURL)
    }
    if event.discussionItems.contains(where: needsManeuverSupplement(_:)), let famBasicManeuversURL {
        supplementalFiles.append(famBasicManeuversURL)
    }
    if normalizedCode == "FAM4490" || normalizedCode == "FAM4501" {
        if let fam4304URL { supplementalFiles.append(fam4304URL) }
        if let fam4490AliasURL { supplementalFiles.append(fam4490AliasURL) }
    }
    let fallbackSourceTitles = uniqueStrings(
        (famAuthoringConfig.blockDefaults[authoringProfile.rawValue]?.fallbackSourceTitles ?? []) +
        (authoringOverride?.fallbackSourceTitles ?? [])
    )
    if !fallbackSourceTitles.isEmpty {
        supplementalFiles.append(contentsOf: allFamFiles.filter { file in
            let stem = normalizeCode(file.deletingPathExtension().lastPathComponent)
            return fallbackSourceTitles.contains { normalizeCode($0) == stem }
        })
    }

    let primaryLinesTotal = primaryFiles.reduce(0) { partial, file in
        partial + extractedLines(from: file, cache: &extractionCache).count
    }
    let shouldUseContactFTI = FileManager.default.fileExists(atPath: contactFTIURL.path) &&
        (primaryFiles.isEmpty || primaryLinesTotal < 40)
    if shouldUseContactFTI {
        supplementalFiles.append(contactFTIURL)
    }

    let primaryTitles = primaryFiles.map { $0.deletingPathExtension().lastPathComponent }
    let primaryLinesByTitle = dictionaryLastWins(primaryFiles.map { file in
        (file.deletingPathExtension().lastPathComponent, extractedLines(from: file, cache: &extractionCache))
    })
    let supplementalLinesByTitle = dictionaryLastWins(uniqueURLs(supplementalFiles).map { file in
        (file.deletingPathExtension().lastPathComponent, extractedLines(from: file, cache: &extractionCache))
    })

    return EventDocumentContext(
        primaryTitles: primaryTitles,
        primaryLinesByTitle: primaryLinesByTitle,
        supplementalLinesByTitle: supplementalLinesByTitle
    )
}

private func buildReadableSection(
    definition: FAMResolvedSectionDefinition,
    event: SyllabusEventReferenceEventRecord,
    authoringProfile: FAMAuthoringProfile,
    existingOverride: ExistingOverride?,
    priorEvents: [SyllabusEventReferenceEventRecord],
    context: EventDocumentContext,
    epCardsByTitle: [String: ReferenceCardTemplate],
    nwcCardsByTitle: [String: ReferenceCardTemplate],
    emergencyProcedureAliases: [String: String]
) -> StudyNotesSectionOutput {
    let profileDefaults = famAuthoringConfig.blockDefaults[authoringProfile.rawValue]
    let maxGroupedChildren = profileDefaults?.maxGroupedChildrenPerItem ?? 4
    let maxStandaloneBullets = profileDefaults?.maxStandaloneBullets ?? 4
    let maxStandaloneChildren = profileDefaults?.maxStandaloneChildren ?? 4

    if definition.discussionItems.count > 1 {
        let items = definition.discussionItems.compactMap { item in
            groupedStudyBullet(
                for: item,
                event: event,
                existingOverride: existingOverride,
                priorEvents: priorEvents,
                context: context,
                sectionKeywordHints: definition.sourceKeywordHints,
                maxChildren: maxGroupedChildren,
                epCardsByTitle: epCardsByTitle,
                nwcCardsByTitle: nwcCardsByTitle,
                emergencyProcedureAliases: emergencyProcedureAliases
            )
        }

        return StudyNotesSectionOutput(
            title: definition.title,
            items: items.isEmpty ? [fallbackSectionBullet(for: definition.title)] : items
        )
    }

    let item = definition.discussionItems.first ?? definition.title
    if let special = readableSpecialSection(
        for: item,
        title: definition.title,
        event: event,
        priorEvents: priorEvents,
        context: context,
        sectionKeywordHints: definition.sourceKeywordHints,
        epCardsByTitle: epCardsByTitle,
        nwcCardsByTitle: nwcCardsByTitle,
        emergencyProcedureAliases: emergencyProcedureAliases
    ) {
        return special
    }

    let style = discussionItemStyle(for: item, event: event, epCardsByTitle: epCardsByTitle, emergencyProcedureAliases: emergencyProcedureAliases)
    let primaryLines = relevantLines(
        for: item,
        in: context.primaryLinesByTitle,
        fallback: existingOverride
    )
    let supplementalLines = filteredReadableLines(
        relevantLines(for: item, in: context.supplementalLinesByTitle, fallback: existingOverride) +
        keywordHintLines(definition.sourceKeywordHints, in: context.supplementalLinesByTitle)
        ,
        excluding: item
    )
    let combinedLines = filteredReadableLines(primaryLines + supplementalLines, excluding: item)
    let sectionItems = buildStandaloneItems(
        for: item,
        style: style,
        lines: combinedLines,
        maxBullets: maxStandaloneBullets,
        maxChildren: maxStandaloneChildren,
        epCardsByTitle: epCardsByTitle,
        nwcCardsByTitle: nwcCardsByTitle,
        emergencyProcedureAliases: emergencyProcedureAliases
    )

    return StudyNotesSectionOutput(
        title: definition.title,
        items: sectionItems.isEmpty ? [fallbackSectionBullet(for: definition.title)] : sectionItems
    )
}

private func groupedStudyBullet(
    for item: String,
    event: SyllabusEventReferenceEventRecord,
    existingOverride: ExistingOverride?,
    priorEvents: [SyllabusEventReferenceEventRecord],
    context: EventDocumentContext,
    sectionKeywordHints: [String],
    maxChildren: Int,
    epCardsByTitle: [String: ReferenceCardTemplate],
    nwcCardsByTitle: [String: ReferenceCardTemplate],
    emergencyProcedureAliases: [String: String]
) -> StudyNotesItemOutput? {
    if let special = readableSpecialGroupedBullet(
        for: item,
        event: event,
        priorEvents: priorEvents,
        context: context,
        sectionKeywordHints: sectionKeywordHints,
        epCardsByTitle: epCardsByTitle,
        nwcCardsByTitle: nwcCardsByTitle,
        emergencyProcedureAliases: emergencyProcedureAliases
    ) {
        return special
    }

    let style = discussionItemStyle(for: item, event: event, epCardsByTitle: epCardsByTitle, emergencyProcedureAliases: emergencyProcedureAliases)
    let primaryLines = relevantLines(for: item, in: context.primaryLinesByTitle, fallback: existingOverride)
    let supplementalLines = filteredReadableLines(
        relevantLines(for: item, in: context.supplementalLinesByTitle, fallback: existingOverride) +
        keywordHintLines(sectionKeywordHints, in: context.supplementalLinesByTitle)
        ,
        excluding: item
    )
    let combinedLines = filteredReadableLines(primaryLines + supplementalLines, excluding: item)
    let categorized = categorize(lines: combinedLines)
    let epTemplate = resolvedEmergencyProcedureTemplate(
        for: item,
        epCardsByTitle: epCardsByTitle,
        emergencyProcedureAliases: emergencyProcedureAliases
    )
    let nwcTemplate = epTemplate.flatMap { nwcCardsByTitle[$0.normalizedTitle] }
    let children = readableChildLines(
        for: item,
        style: style,
        categorized: categorized,
        epTemplate: epTemplate,
        nwcTemplate: nwcTemplate,
        maxChildren: maxChildren
    )

    return StudyNotesItemOutput(
        text: "\(titleCasedDiscussionItemPrompt(item)):",
        children: children.map { StudyNotesItemOutput(text: $0, children: nil) }
    )
}

private func buildStandaloneItems(
    for item: String,
    style: DiscussionItemStyle,
    lines: [String],
    maxBullets: Int,
    maxChildren: Int,
    epCardsByTitle: [String: ReferenceCardTemplate],
    nwcCardsByTitle: [String: ReferenceCardTemplate],
    emergencyProcedureAliases: [String: String]
) -> [StudyNotesItemOutput] {
    let categorized = categorize(lines: lines)
    let epTemplate = resolvedEmergencyProcedureTemplate(
        for: item,
        epCardsByTitle: epCardsByTitle,
        emergencyProcedureAliases: emergencyProcedureAliases
    )
    let nwcTemplate = epTemplate.flatMap { nwcCardsByTitle[$0.normalizedTitle] }

    switch style {
    case .knowledge:
        let lead = firstUsefulLine(
            categorized.purpose + categorized.keyKnowledge,
            fallback: genericWhyItMatters(for: item)
        )
        var bullets: [StudyNotesItemOutput] = [StudyNotesItemOutput(text: lead, children: nil)]
        let keyPoints = readableKnowledgeLines(
            for: item,
            categorized: categorized,
            maxChildren: maxChildren
        ).filter { normalizedText($0) != normalizedText(lead) }
        if !keyPoints.isEmpty {
            bullets.append(
                StudyNotesItemOutput(
                    text: "Key points:",
                    children: keyPoints.map { StudyNotesItemOutput(text: $0, children: nil) }
                )
            )
        }
        return Array(bullets.prefix(maxBullets))

    case .maneuver:
        let lead = firstUsefulLine(
            categorized.purpose,
            fallback: genericPurpose(for: item)
        )
        var bullets: [StudyNotesItemOutput] = [StudyNotesItemOutput(text: lead, children: nil)]
        let setupChildren = pickLines(categorized.setup, maxCount: maxChildren, fallback: [genericSetup(for: item)])
        let executionChildren = pickLines(categorized.execution + categorized.keyKnowledge, maxCount: maxChildren, fallback: [genericExecution(for: item)])
        let numbersAndTraps = pickLines(
            categorized.standards + categorized.commonErrors + categorized.nwc.filter { containsNumbers($0) || normalizedText($0).contains("warning") || normalizedText($0).contains("caution") },
            maxCount: maxChildren,
            fallback: [genericStandards(for: item)]
        )

        bullets.append(StudyNotesItemOutput(text: "Setup cues:", children: setupChildren.map { StudyNotesItemOutput(text: $0, children: nil) }))
        bullets.append(StudyNotesItemOutput(text: "Execution priorities:", children: executionChildren.map { StudyNotesItemOutput(text: $0, children: nil) }))
        if !numbersAndTraps.isEmpty {
            bullets.append(StudyNotesItemOutput(text: "Numbers / traps:", children: numbersAndTraps.map { StudyNotesItemOutput(text: $0, children: nil) }))
        }
        return Array(bullets.prefix(maxBullets))

    case .emergencyProcedure:
        let recognitionLead = firstUsefulLine(
            categorized.recognition + categorized.purpose,
            fallback: genericRecognition(for: item)
        )
        let procedureLines = epTemplate.map(answerLines) ?? pickLines(categorized.execution + categorized.keyKnowledge, maxCount: maxChildren, fallback: [genericProcedureFallback(for: item)])
        let decisionLines = pickLines(categorized.application + categorized.setup + categorized.standards, maxCount: maxChildren, fallback: [genericDecisionLogic(for: item)])
        let nwcLines = nwcTemplate.map(answerLines) ?? pickLines(categorized.nwc, maxCount: maxChildren, fallback: [genericNWCRequirement(for: item)])

        return [
            StudyNotesItemOutput(text: recognitionLead, children: nil),
            StudyNotesItemOutput(text: "Immediate actions:", children: procedureLines.map { StudyNotesItemOutput(text: $0, children: nil) }),
            StudyNotesItemOutput(text: "Decision cues:", children: decisionLines.map { StudyNotesItemOutput(text: $0, children: nil) }),
            StudyNotesItemOutput(text: "N/W/C focus:", children: nwcLines.map { StudyNotesItemOutput(text: $0, children: nil) })
        ].prefix(maxBullets).map { $0 }
    }
}

private func readableSpecialSection(
    for item: String,
    title: String,
    event: SyllabusEventReferenceEventRecord,
    priorEvents: [SyllabusEventReferenceEventRecord],
    context: EventDocumentContext,
    sectionKeywordHints: [String],
    epCardsByTitle: [String: ReferenceCardTemplate],
    nwcCardsByTitle: [String: ReferenceCardTemplate],
    emergencyProcedureAliases: [String: String]
) -> StudyNotesSectionOutput? {
    let normalizedItem = normalizeReferenceTitle(item)

    if normalizedItem == "any ep" ||
        normalizedItem == "any emergency procedure" ||
        normalizedItem == "emergency procedures" ||
        normalizedItem == "any critical action emergency procedure" ||
        normalizedItem == "any critical action emergency procedures" {
        let priorEPs = uniqueStrings(
            priorEvents
                .flatMap(\.discussionItems)
                .filter { discussionItemStyle(for: $0, event: event, epCardsByTitle: epCardsByTitle, emergencyProcedureAliases: emergencyProcedureAliases) == .emergencyProcedure }
                .map(titleCasedDiscussionItemPrompt)
        )

        return StudyNotesSectionOutput(
            title: title,
            items: [
                StudyNotesItemOutput(text: "Treat this as a cumulative EP brief. The instructor can move quickly between recognition, memory items, and the branch logic that decides whether you continue, land, or eject.", children: nil),
                StudyNotesItemOutput(
                    text: "Expected review set:",
                    children: pickLines(priorEPs, maxCount: 12, fallback: ["Review every previously introduced FAM emergency procedure before the event."]).map { StudyNotesItemOutput(text: $0, children: nil) }
                ),
                StudyNotesItemOutput(
                    text: "How to study it:",
                    children: [
                        StudyNotesItemOutput(text: "Be able to state the recognition cue before you recite the steps.", children: nil),
                        StudyNotesItemOutput(text: "Know the associated N/W/Cs, not just the memory items.", children: nil),
                        StudyNotesItemOutput(text: "Have a clear answer for when the EP becomes a PEL, forced-landing, or ejection problem.", children: nil)
                    ]
                )
            ]
        )
    }

    if normalizedItem == "per the odo fdo solo brief" {
        return StudyNotesSectionOutput(
            title: title,
            items: [
                StudyNotesItemOutput(text: "Treat the solo brief as a go/no-go gate, not an admin step. You should arrive already knowing the weather, runway, emergency, and support-agency items that will drive the brief.", children: nil),
                StudyNotesItemOutput(
                    text: "Show up ready to cover:",
                    children: [
                        StudyNotesItemOutput(text: "Solo weather, runway, crosswind, BASH, landing, and divert limits.", children: nil),
                        StudyNotesItemOutput(text: "Rear-cockpit securing items, unauthorized solo maneuver limits, and what will terminate the sortie early.", children: nil),
                        StudyNotesItemOutput(text: "Emergency, lost-aircraft, and support-agency expectations if the profile does not stay routine.", children: nil)
                    ]
                ),
                StudyNotesItemOutput(text: "The day-of ODO/FDO solo brief still remains required, even if these notes already make the overall picture familiar.", children: nil)
            ]
        )
    }

    if normalizedItem == "maneuvers" || normalizedItem == "any maneuver performed in this block" {
        let maneuverTopics = uniqueStrings(
            priorEvents
                .flatMap(\.discussionItems)
                .filter { discussionItemStyle(for: $0, event: event, epCardsByTitle: epCardsByTitle, emergencyProcedureAliases: emergencyProcedureAliases) == .maneuver }
                .map(titleCasedDiscussionItemPrompt)
        )

        return StudyNotesSectionOutput(
            title: title,
            items: [
                StudyNotesItemOutput(text: "Treat this as a cumulative maneuver brief. You should be able to move from setup to recovery without needing a rescue cue once the instructor picks the maneuver.", children: nil),
                StudyNotesItemOutput(
                    text: "Be ready to brief:",
                    children: pickLines(maneuverTopics, maxCount: 8, fallback: ["Review every maneuver already introduced in the relevant FAM block."]).map { StudyNotesItemOutput(text: $0, children: nil) }
                ),
                StudyNotesItemOutput(text: "Know the entry picture, the recovery picture, and the common grading misses for each maneuver you expect to be fair game.", children: nil)
            ]
        )
    }

    if normalizedItem == "emergency procedures" {
        let priorEPs = uniqueStrings(
            priorEvents
                .flatMap(\.discussionItems)
                .filter { discussionItemStyle(for: $0, event: event, epCardsByTitle: epCardsByTitle, emergencyProcedureAliases: emergencyProcedureAliases) == .emergencyProcedure }
                .map(titleCasedDiscussionItemPrompt)
        )

        return StudyNotesSectionOutput(
            title: title,
            items: [
                StudyNotesItemOutput(text: "Treat the EP set as one connected decision tree instead of isolated memory items. Recognition, immediate action, branch logic, and N/W/Cs all need to show up in the brief.", children: nil),
                StudyNotesItemOutput(
                    text: "Expected review set:",
                    children: pickLines(priorEPs, maxCount: 8, fallback: ["Review the previously introduced familiarization emergency-procedure set."]).map { StudyNotesItemOutput(text: $0, children: nil) }
                ),
                StudyNotesItemOutput(text: "If the instructor changes the scenario mid-brief, you should still be able to say what now makes it a continue, PEL, forced-landing, or ejection problem.", children: nil)
            ]
        )
    }

    return nil
}

private func readableSpecialGroupedBullet(
    for item: String,
    event: SyllabusEventReferenceEventRecord,
    priorEvents: [SyllabusEventReferenceEventRecord],
    context: EventDocumentContext,
    sectionKeywordHints: [String],
    epCardsByTitle: [String: ReferenceCardTemplate],
    nwcCardsByTitle: [String: ReferenceCardTemplate],
    emergencyProcedureAliases: [String: String]
) -> StudyNotesItemOutput? {
    let normalizedItem = normalizeReferenceTitle(item)

    if normalizedItem == "any previously discussed items" {
        let priorTopics = uniqueStrings(
            priorEvents
                .flatMap(\.discussionItems)
                .filter { normalizeReferenceTitle($0) != normalizedItem }
                .map(titleCasedDiscussionItemPrompt)
        )
        return StudyNotesItemOutput(
            text: "Any Previously Discussed Items:",
            children: pickLines(priorTopics, maxCount: 5, fallback: ["Review the earlier FAM blocks as if the event can reach backward without warning."]).map { StudyNotesItemOutput(text: $0, children: nil) }
        )
    }

    if normalizedItem == "maneuvers" || normalizedItem == "any maneuver performed in this block" {
        let maneuverTopics = uniqueStrings(
            priorEvents
                .flatMap(\.discussionItems)
                .filter { discussionItemStyle(for: $0, event: event, epCardsByTitle: epCardsByTitle, emergencyProcedureAliases: emergencyProcedureAliases) == .maneuver }
                .map(titleCasedDiscussionItemPrompt)
        )
        return StudyNotesItemOutput(
            text: "\(titleCasedDiscussionItemPrompt(item)):",
            children: pickLines(maneuverTopics, maxCount: 6, fallback: ["Review every maneuver already introduced in the applicable FAM block."]).map { StudyNotesItemOutput(text: $0, children: nil) }
        )
    }

    if normalizedItem == "emergency procedures" {
        let priorEPs = uniqueStrings(
            priorEvents
                .flatMap(\.discussionItems)
                .filter { discussionItemStyle(for: $0, event: event, epCardsByTitle: epCardsByTitle, emergencyProcedureAliases: emergencyProcedureAliases) == .emergencyProcedure }
                .map(titleCasedDiscussionItemPrompt)
        )
        return StudyNotesItemOutput(
            text: "Emergency Procedures:",
            children: pickLines(priorEPs, maxCount: 6, fallback: ["Review the EP set you have already seen in familiarization."]).map { StudyNotesItemOutput(text: $0, children: nil) }
        )
    }

    return nil
}

private func readableKnowledgeLines(
    for item: String,
    categorized: (
        purpose: [String],
        setup: [String],
        execution: [String],
        standards: [String],
        commonErrors: [String],
        recognition: [String],
        application: [String],
        nwc: [String],
        keyKnowledge: [String]
    ),
    maxChildren: Int
) -> [String] {
    pickLines(
        categorized.keyKnowledge + categorized.setup + categorized.standards + categorized.application + categorized.commonErrors.prefix(1),
        maxCount: maxChildren,
        fallback: [genericKeyKnowledgeFallback(for: item)]
    )
}

private func readableChildLines(
    for item: String,
    style: DiscussionItemStyle,
    categorized: (
        purpose: [String],
        setup: [String],
        execution: [String],
        standards: [String],
        commonErrors: [String],
        recognition: [String],
        application: [String],
        nwc: [String],
        keyKnowledge: [String]
    ),
    epTemplate: ReferenceCardTemplate?,
    nwcTemplate: ReferenceCardTemplate?,
    maxChildren: Int
) -> [String] {
    switch style {
    case .knowledge:
        return readableKnowledgeLines(for: item, categorized: categorized, maxChildren: maxChildren)
    case .maneuver:
        return pickLines(
            categorized.setup + categorized.execution + categorized.standards + categorized.commonErrors.prefix(1),
            maxCount: maxChildren,
            fallback: [genericExecution(for: item)]
        )
    case .emergencyProcedure:
        let procedureLines = epTemplate.map(answerLines) ?? categorized.execution
        let decisionLines = Array(categorized.application.prefix(1))
        let nwcLines = nwcTemplate.map(answerLines) ?? Array(categorized.nwc.prefix(1))
        let combined = procedureLines + decisionLines + nwcLines
        return pickLines(
            combined,
            maxCount: maxChildren,
            fallback: [genericProcedureFallback(for: item), genericNWCRequirement(for: item)]
        )
    }
}

private func keywordHintLines(_ hints: [String], in linesByTitle: [String: [String]]) -> [String] {
    guard !hints.isEmpty else { return [] }
    let normalizedHints = hints.map(normalizedText)
    let lines = linesByTitle
        .keys
        .sorted()
        .flatMap { linesByTitle[$0] ?? [] }

    return uniqueStrings(lines.filter { line in
        let normalizedLine = normalizedText(line)
        return normalizedHints.contains { normalizedLine.contains($0) }
    })
}

private func firstUsefulLine(_ candidates: [String], fallback: String) -> String {
    pickLines(candidates, maxCount: 1, fallback: [fallback]).first ?? fallback
}

private func fallbackSectionBullet(for title: String) -> StudyNotesItemOutput {
    StudyNotesItemOutput(
        text: "Use the assigned source document and the required procedures list to brief \(title.lowercased()) cleanly if the harvested lines here are still thin.",
        children: nil
    )
}

private func buildStandardSection(
    for item: String,
    displayTitle: String,
    style: DiscussionItemStyle,
    primaryLines: [String],
    supplementalLines: [String],
    epCardsByTitle: [String: ReferenceCardTemplate],
    nwcCardsByTitle: [String: ReferenceCardTemplate],
    emergencyProcedureAliases: [String: String]
) -> StudyNotesSectionOutput {
    let combinedLines = uniqueStrings(primaryLines + supplementalLines)
    let epTemplate = resolvedEmergencyProcedureTemplate(
        for: item,
        epCardsByTitle: epCardsByTitle,
        emergencyProcedureAliases: emergencyProcedureAliases
    )
    let nwcTemplate = epTemplate.flatMap { nwcCardsByTitle[$0.normalizedTitle] }

    let categorized = categorize(lines: combinedLines)

    switch style {
    case .knowledge:
        let whyItMatters = categorized.purpose.isEmpty
            ? [genericWhyItMatters(for: item)]
            : categorized.purpose
        let keyKnowledge = pickLines(categorized.keyKnowledge + categorized.setup + categorized.standards, maxCount: 10, fallback: [genericKeyKnowledgeFallback(for: item)])
        let application = pickLines(categorized.application + supplementalLines.filter { normalizedText($0).contains("use") || normalizedText($0).contains("when") }, maxCount: 6, fallback: [genericApplication(for: item)])
        let commonErrors = pickLines(categorized.commonErrors + categorized.nwc, maxCount: 6, fallback: [genericKnowledgeTrap(for: item)])

        return StudyNotesSectionOutput(
            title: displayTitle,
            items: [
                labeledItem("Why it matters", whyItMatters),
                labeledItem("Key knowledge", keyKnowledge),
                labeledItem("Application", application),
                labeledItem("Common errors / grading traps", commonErrors)
            ]
        )

    case .maneuver:
        let purpose = categorized.purpose.isEmpty ? [genericPurpose(for: item)] : categorized.purpose
        let setup = pickLines(categorized.setup, maxCount: 8, fallback: [genericSetup(for: item)])
        let execution = pickLines(categorized.execution + categorized.keyKnowledge, maxCount: 12, fallback: [genericExecution(for: item)])
        let standards = pickLines(categorized.standards + categorized.nwc.filter { containsNumbers($0) }, maxCount: 10, fallback: [genericStandards(for: item)])
        let commonErrors = pickLines(categorized.commonErrors + categorized.nwc.filter { !containsNumbers($0) }, maxCount: 6, fallback: [genericManeuverTrap(for: item)])

        return StudyNotesSectionOutput(
            title: displayTitle,
            items: [
                labeledItem("Purpose", purpose),
                labeledItem("Setup / entry", setup),
                labeledItem("Execution", execution),
                labeledItem("Standards / numbers", standards),
                labeledItem("Common errors / grading traps", commonErrors)
            ]
        )

    case .emergencyProcedure:
        let recognition = pickLines(categorized.recognition + categorized.purpose, maxCount: 8, fallback: [genericRecognition(for: item)])
        let procedureLines = epTemplate.map(answerLines) ?? pickLines(categorized.execution + categorized.keyKnowledge, maxCount: 12, fallback: [genericProcedureFallback(for: item)])
        let decisionLogic = pickLines(categorized.application + categorized.setup + categorized.standards, maxCount: 8, fallback: [genericDecisionLogic(for: item)])
        let nwcLines = nwcTemplate.map(answerLines) ?? pickLines(categorized.nwc, maxCount: 8, fallback: [genericNWCRequirement(for: item)])

        return StudyNotesSectionOutput(
            title: displayTitle,
            items: [
                labeledItem("Recognition / indications", recognition),
                labeledItem("Immediate actions / procedure", procedureLines),
                labeledItem("Decision logic", decisionLogic),
                labeledItem("N/W/Cs", nwcLines)
            ]
        )
    }
}

private func buildSpecialReviewSection(
    for item: String,
    event: SyllabusEventReferenceEventRecord,
    priorEvents: [SyllabusEventReferenceEventRecord],
    style: DiscussionItemStyle,
    displayTitle: String,
    epCardsByTitle: [String: ReferenceCardTemplate],
    nwcCardsByTitle: [String: ReferenceCardTemplate],
    emergencyProcedureAliases: [String: String],
    primaryLines: [String],
    supplementalLines: [String]
) -> StudyNotesSectionOutput? {
    let normalizedItem = normalizeReferenceTitle(item)

    if normalizedItem == "any previously discussed items" || normalizedItem == "any previously discussed maneuver or procedure" {
        let priorTopics = priorEvents
            .flatMap(\.discussionItems)
            .filter { normalizeReferenceTitle($0) != normalizedItem }
        let maneuverTopics = priorTopics.filter { discussionItemStyle(for: $0, event: event, epCardsByTitle: epCardsByTitle, emergencyProcedureAliases: emergencyProcedureAliases) == .maneuver }
        let knowledgeTopics = priorTopics.filter { discussionItemStyle(for: $0, event: event, epCardsByTitle: epCardsByTitle, emergencyProcedureAliases: emergencyProcedureAliases) == .knowledge }

        return StudyNotesSectionOutput(
            title: displayTitle,
            items: [
                labeledItem("Why it matters", [
                    "This is a cumulative review item. Treat it like a check-event probe: you can be asked to explain prior FAM procedures, systems, maneuvers, and emergency logic without a warm-up."
                ]),
                labeledItem("Key knowledge", pickLines(maneuverTopics + knowledgeTopics, maxCount: 14, fallback: ["Rehearse every previously introduced FAM topic that is still fair game for this event."])),
                labeledItem("Application", [
                    "Build your prep around the assigned profile first, then backfill the earlier blocks that feed into it.",
                    "Be ready to move from verbal explanation to a cockpit decision or maneuver setup without changing gears."
                ]),
                labeledItem("Common errors / grading traps", [
                    "Do not study only the newest block. Review questions on older FAM material are often used to check whether the fundamentals are still automatic."
                ])
            ]
        )
    }

    if normalizedItem == "any maneuver performed in this block" {
        let blockPrefix = String(normalizeCode(event.blockCode).prefix(5))
        let blockTopics = priorEvents
            .filter { normalizeCode($0.blockCode).hasPrefix(blockPrefix) }
            .flatMap(\.discussionItems)
            .filter { discussionItemStyle(for: $0, event: event, epCardsByTitle: epCardsByTitle, emergencyProcedureAliases: emergencyProcedureAliases) == .maneuver }

        return StudyNotesSectionOutput(
            title: displayTitle,
            items: [
                labeledItem("Purpose", [
                    "This is a block-level maneuver review. The goal is to prove you can set up, brief, and fly anything already introduced in this block without getting behind the aircraft."
                ]),
                labeledItem("Setup / entry", [
                    "Know the entry picture, starting altitude, airspeed, configuration, and required radio/CRM setup for each maneuver you may be assigned."
                ]),
                labeledItem("Execution", pickLines(blockTopics, maxCount: 12, fallback: ["Review every maneuver already introduced in this block and be ready to brief its key steps cleanly."])),
                labeledItem("Standards / numbers", [
                    "For each maneuver, memorize the setup numbers first. Missing the entry picture usually creates the rest of the errors."
                ]),
                labeledItem("Common errors / grading traps", [
                    "The usual trap is assuming you only need the maneuver you flew most recently. Treat the whole block as available for review."
                ])
            ]
        )
    }

    if normalizedItem == "any ep" ||
        normalizedItem == "any emergency procedure" ||
        normalizedItem == "emergency procedures" ||
        normalizedItem == "any critical action emergency procedure" ||
        normalizedItem == "any critical action emergency procedures" {
        let priorEPs = uniqueStrings(
            priorEvents
                .flatMap(\.discussionItems)
                .filter { discussionItemStyle(for: $0, event: event, epCardsByTitle: epCardsByTitle, emergencyProcedureAliases: emergencyProcedureAliases) == .emergencyProcedure }
                .map { titleCasedDiscussionItemPrompt($0) }
        )

        let recognitionLines = primaryLines.isEmpty
            ? ["Treat this as a cumulative emergency-procedure review. You may be assigned any previously introduced FAM EP and must know the recognition cues cold."]
            : pickLines(primaryLines, maxCount: 8, fallback: [])

        return StudyNotesSectionOutput(
            title: displayTitle,
            items: [
                labeledItem("Recognition / indications", recognitionLines),
                labeledItem("Immediate actions / procedure", pickLines(priorEPs, maxCount: 14, fallback: ["Review the full set of previously introduced FAM emergency procedures and be ready to recite the critical actions verbatim."])),
                labeledItem("Decision logic", [
                    "Know when the problem can be managed with a PEL, when it requires a forced landing, and when it is time to stop troubleshooting and eject.",
                    "If the assigned EP includes branches, know what cue drives each branch before you brief the next step."
                ]),
                labeledItem("N/W/Cs", [
                    "Be ready to state the associated WARNINGs, CAUTIONs, and NOTEs for the assigned EP, not just the memory items.",
                    "Review the verbatim N/W/C card for every EP title listed above before the event."
                ])
            ]
        )
    }

    if normalizedItem == "maneuvers" {
        let maneuverTopics = uniqueStrings(
            priorEvents
                .flatMap(\.discussionItems)
                .filter { discussionItemStyle(for: $0, event: event, epCardsByTitle: epCardsByTitle, emergencyProcedureAliases: emergencyProcedureAliases) == .maneuver }
                .map { titleCasedDiscussionItemPrompt($0) }
        )

        return StudyNotesSectionOutput(
            title: displayTitle,
            items: [
                labeledItem("Purpose", [
                    "This is the cumulative maneuver bucket for the check flight. You should be able to brief, set up, and fly any previously introduced FAM maneuver without needing a rescue cue."
                ]),
                labeledItem("Setup / entry", [
                    "Know the entry altitude, airspeed, configuration, and pre-maneuver checks for each maneuver that is still fair game."
                ]),
                labeledItem("Execution", pickLines(maneuverTopics, maxCount: 14, fallback: ["Review all previously introduced FAM maneuvers."])),
                labeledItem("Standards / numbers", [
                    "Memorize the setup numbers and the recovery numbers. In cumulative events, those are usually what separates a clean brief from a shaky one."
                ]),
                labeledItem("Common errors / grading traps", [
                    "Do not narrow your study to the last flight. Check-flight maneuver questions often jump across earlier blocks."
                ])
            ]
        )
    }

    if normalizedItem == "per the odo fdo solo brief" {
        let soloLines = uniqueStrings(primaryLines + supplementalLines)
        let categorized = categorize(lines: soloLines)
        return StudyNotesSectionOutput(
            title: displayTitle,
            items: [
                labeledItem("Why it matters", [
                    "The solo brief is the final risk-control gate. Treat it as a go/no-go event, not just an admin requirement.",
                    "This note is a conservative prep aid. The day-of ODO/FDO solo brief still remains mandatory."
                ]),
                labeledItem("Key knowledge", pickLines(categorized.keyKnowledge + categorized.standards + categorized.setup, maxCount: 12, fallback: ["Review solo weather, runway, crosswind, BASH, landing, and cockpit-secure requirements before showing up for the brief."])),
                labeledItem("Application", [
                    "Be ready to verbalize solo weather minimums, runway and field-use limits, emergency expectations, and what support agency you will call if the sortie does not go normally.",
                    "Use the brief to close every open question before you start the airplane."
                ]),
                labeledItem("Common errors / grading traps", [
                    "Do not assume a previous instructor brief covers the same details. The day-of solo brief is its own gate and must be treated that way."
                ])
            ]
        )
    }

    return nil
}

private func discussionItemStyle(
    for item: String,
    event: SyllabusEventReferenceEventRecord,
    epCardsByTitle: [String: ReferenceCardTemplate],
    emergencyProcedureAliases: [String: String]
) -> DiscussionItemStyle {
    if resolvedEmergencyProcedureTemplate(for: item, epCardsByTitle: epCardsByTitle, emergencyProcedureAliases: emergencyProcedureAliases) != nil {
        return .emergencyProcedure
    }

    if looksLikeEmergencyProcedureDiscussionItem(item) {
        return .emergencyProcedure
    }

    let normalized = normalizedText(item)
    if normalized.contains("unauthorized") {
        return .knowledge
    }

    let maneuverSignals = [
        "takeoff", "landing", "landings", "pattern", "arrival", "departure", "approach",
        "stall", "spin", "roll", "loop", "cuban", "immelmann", "split", "wingover",
        "wave off", "waveoff", "scatsafe", "slow flight", "slip", "recovery", "entry",
        "orbit", "extension", "maneuver", "touch and go", "touch and go", "full stop",
        "crosswind", "trim", "scan", "level speed change", "turn pattern", "straight in"
    ]

    if maneuverSignals.contains(where: { normalized.contains($0) }) {
        return .maneuver
    }

    return .knowledge
}

private func relevantLines(
    for item: String,
    in linesByTitle: [String: [String]],
    fallback existingOverride: ExistingOverride?
) -> [String] {
    var collected: [String] = []
    for (_, lines) in linesByTitle {
        collected.append(contentsOf: matchingSlices(for: item, in: lines).flatMap { $0 })
    }

    let matched = uniqueStrings(collected)
    if !matched.isEmpty {
        return matched
    }

    return existingLines(for: item, from: existingOverride)
}

private func matchingSlices(for item: String, in lines: [String]) -> [[String]] {
    let aliases = discussionItemAliasesFor(item)
    let startIndices = matchingStartIndices(for: item, aliases: aliases, in: lines)
    guard !startIndices.isEmpty else { return [] }

    var slices: [[String]] = []
    for startIndex in startIndices {
        if let slice = slice(from: startIndex, for: item, in: lines) {
            slices.append(slice)
        }
    }

    return slices
}

private func slice(from startIndex: Int, for item: String, in lines: [String]) -> [String]? {
    var nextMatchIndex = lines.count
    for probe in (startIndex + 1)..<lines.count {
        let line = lines[probe]
        if looksLikeTopLevelDiscussionItem(line, for: item) {
            nextMatchIndex = probe
            break
        }
    }

    let slice = Array(lines[(startIndex + 1)..<nextMatchIndex])
    let cleaned = slice
        .map(cleanLine)
        .filter { !$0.isEmpty }
        .filter { !isAdministrativeLine($0) }
        .filter { !isScaffoldLabelLine($0) }

    return cleaned.isEmpty ? nil : uniqueStrings(cleaned)
}

private func matchingStartIndices(
    for item: String,
    aliases: [String],
    in lines: [String]
) -> [Int] {
    let candidates = uniqueStrings([item] + aliases)
    var indices: [Int] = []

    for (index, rawLine) in lines.enumerated() {
        let line = cleanLine(rawLine)
        guard !line.isEmpty else { continue }

        let score = candidates.map { scoreMatch(candidate: $0, line: line) }.max() ?? 0
        let isStrongMatch = score >= 0.6
        let isHeadingLikeAliasMatch = score >= 0.45 && looksLikeTopLevelDiscussionItem(line, for: item)
        guard isStrongMatch || isHeadingLikeAliasMatch else { continue }

        if let prior = indices.last, index - prior <= 2 {
            continue
        }
        indices.append(index)
    }

    return indices
}

private func fullContentLines(from linesByTitle: [String: [String]]) -> [String] {
    uniqueStrings(
        linesByTitle
            .keys
            .sorted()
            .flatMap { title in
                (linesByTitle[title] ?? []).filter { line in
                    normalizedText(line) != normalizedText(title)
                }
            }
    )
}

private func looksLikeTopLevelDiscussionItem(_ line: String, for currentItem: String) -> Bool {
    let cleaned = cleanLine(line)
    guard !cleaned.isEmpty else { return false }

    let normalized = normalizedText(cleaned)
    if normalized == normalizedText(currentItem) {
        return false
    }

    let subheadingPrefixes = [
        "description", "overview", "purpose", "setup", "configuration", "procedure",
        "procedures", "execution", "operation", "operations", "common errors",
        "warning", "warnings", "caution", "note", "n/w/c", "n/w/cs",
        "touchdown", "rotation", "initial climb", "final", "downwind",
        "entry", "entries", "recovery", "effects", "indications", "radio calls",
        "checklist", "steps", "transition", "transitions", "decision logic",
        "pattern adjustments", "runway departures", "arrival procedures",
        "departure procedures", "communication requirements",
        "weather and runway determination", "weather runway determination",
        "4 nm initial report", "discontinued entry", "break call", "priority",
        "successive touch and go", "crosswind interval", "pel/p entry",
        "goliad arrival", "northern arrival", "takeoff precautions",
        "approach precautions", "landing considerations", "important numbers",
        "abort start criteria", "pcl position specific actions", "motoring run",
        "pmu autostart system", "common pmu abort triggers", "other notes",
        "brake reservoir indicators", "immediate actions", "post ejection procedures",
        "ejection altitudes", "ejection sequence separation", "spin types", "general"
    ]
    if subheadingPrefixes.contains(where: { normalized.hasPrefix($0) }) {
        return false
    }

    let tokens = significantTokens(in: cleaned)
    guard !tokens.isEmpty else { return false }
    let headingSignals = [
        "takeoff", "landing", "pattern", "departure", "arrival", "engine", "emergency",
        "system", "systems", "trim", "spin", "stall", "aoa", "night", "local", "olf",
        "course", "unusual", "maneuver", "hud", "fuel", "electrical", "hydraulic", "obogs",
        "eject", "airstart", "abort", "fire", "propeller", "solo", "cloud", "crm", "imsafe"
    ]
    return tokens.count <= 8 && !headingSignals.filter({ tokens.contains($0) }).isEmpty
}

private func scoreMatch(candidate: String, line: String) -> Double {
    let normalizedCandidate = normalizedText(candidate)
    let normalizedLine = normalizedText(line)
    if normalizedLine == normalizedCandidate {
        return 1.0
    }
    if normalizedLine.contains(normalizedCandidate) || normalizedCandidate.contains(normalizedLine) {
        return 0.9
    }

    let candidateTokens = significantTokens(in: candidate)
    let lineTokens = significantTokens(in: line)
    guard !candidateTokens.isEmpty, !lineTokens.isEmpty else { return 0 }
    let overlap = candidateTokens.intersection(lineTokens).count
    guard overlap > 0 else { return 0 }
    return Double(overlap) / Double(candidateTokens.count)
}

private func categorize(lines: [String]) -> (
    purpose: [String],
    setup: [String],
    execution: [String],
    standards: [String],
    commonErrors: [String],
    recognition: [String],
    application: [String],
    nwc: [String],
    keyKnowledge: [String]
) {
    var purpose: [String] = []
    var setup: [String] = []
    var execution: [String] = []
    var standards: [String] = []
    var commonErrors: [String] = []
    var recognition: [String] = []
    var application: [String] = []
    var nwc: [String] = []
    var keyKnowledge: [String] = []

    for rawLine in lines {
        let line = cleanLine(rawLine)
        let normalized = normalizedText(line)
        guard !line.isEmpty else { continue }

        if normalized.hasPrefix("description") || normalized.hasPrefix("overview") || normalized.hasPrefix("purpose") || normalized == "general" {
            purpose.append(stripLabel(from: line))
        } else if normalized.hasPrefix("setup") || normalized.hasPrefix("entry") || normalized.hasPrefix("configuration") || normalized.hasPrefix("transition") || normalized.hasPrefix("initial entry") || normalized.hasPrefix("prior to arrival") {
            setup.append(stripLabel(from: line))
        } else if normalized.hasPrefix("procedure") || normalized.hasPrefix("execution") || normalized.hasPrefix("operation") || normalized.hasPrefix("steps") || normalized.hasPrefix("immediate actions") || normalized.hasPrefix("recovery") {
            execution.append(stripLabel(from: line))
        } else if normalized.hasPrefix("common errors") || normalized.hasPrefix("grading") || normalized.contains("trap") {
            commonErrors.append(stripLabel(from: line))
        } else if normalized.hasPrefix("recognition") || normalized.hasPrefix("indications") || normalized.contains("indication") || normalized.contains("signs include") {
            recognition.append(stripLabel(from: line))
        } else if normalized.hasPrefix("nwc") || normalized.hasPrefix("warning") || normalized.hasPrefix("caution") || normalized.hasPrefix("note") || normalized.hasPrefix("w ") || normalized.hasPrefix("c ") || normalized.hasPrefix("n ") {
            nwc.append(stripLabel(from: line))
        } else if containsNumbers(line) || normalized.contains("limit") || normalized.contains("minimum") || normalized.contains("maximum") || normalized.contains("kias") || normalized.contains("msl") || normalized.contains("agl") || normalized.contains("psi") || normalized.contains("units") {
            standards.append(stripLabel(from: line))
        } else if normalized.hasPrefix("if ") || normalized.contains(" if ") || normalized.contains(" when ") || normalized.contains("unless") || normalized.contains("as required") || normalized.contains("consider") {
            application.append(stripLabel(from: line))
        } else {
            keyKnowledge.append(stripLabel(from: line))
        }
    }

    return (
        uniqueStrings(purpose),
        uniqueStrings(setup),
        uniqueStrings(execution),
        uniqueStrings(standards),
        uniqueStrings(commonErrors),
        uniqueStrings(recognition),
        uniqueStrings(application),
        uniqueStrings(nwc),
        uniqueStrings(keyKnowledge)
    )
}

private func buildEventSummary(
    for event: SyllabusEventReferenceEventRecord,
    sections: [FAMResolvedSectionDefinition]
) -> String {
    let sectionTitles = sections.map(\.title).filter { normalizedText($0) != normalizedText("Required Procedures") }
    let preview = Array(sectionTitles.prefix(3))
    guard !preview.isEmpty else {
        return "\(event.shortTitle.lowercased()) briefing priorities and required procedures."
    }
    if preview.count == 1 {
        return summaryPhrase(from: preview[0]) + "."
    }
    return joinedPhrases(preview.map(summaryPhrase(from:))) + "."
}

private func buildEventOverview(
    for event: SyllabusEventReferenceEventRecord,
    authoringProfile: FAMAuthoringProfile,
    sections: [FAMResolvedSectionDefinition]
) -> String {
    let sectionTitles = sections.map(\.title).filter { normalizedText($0) != normalizedText("Required Procedures") }
    let overviewSource = sectionTitles.count == 1 ? [event.shortTitle] : Array(sectionTitles.prefix(3))
    let lead = overviewSource.isEmpty
        ? event.shortTitle.lowercased()
        : joinedPhrases(overviewSource.map(overviewPhrase(from:)))

    switch authoringProfile {
    case .reviewSim:
        if overviewSource.count == 1 {
            return "Use this event as a cumulative review of \(lead). You should be ready to move between sections without a reset and explain the setup cues, decision points, and common misses that usually trigger follow-up questions."
        }
        return "This event pulls together \(lead) into a cumulative review brief. You should be ready to move between sections without a reset and explain the setup cues, decision points, and common misses that usually trigger follow-up questions."
    case .checkFlight:
        return "This event is a cumulative familiarization check. You should be ready to brief \(lead) cleanly, then pivot between systems, procedures, maneuvers, and emergency logic without losing the big picture."
    case .solo:
        return "This event is about showing up for the solo brief with the major risk, weather, and execution items already organized. Use these notes to walk in ahead of the day-of ODO/FDO brief instead of trying to build the whole picture on the spot."
    case .flight:
        return "This event ties together \(lead) in a way that should already make sense before you step. You should be ready to brief what changes the plan, what numbers matter, and where the usual errors start once the workload climbs."
    case .sim:
        return "This event ties together \(lead) into a cleaner familiarization brief. You should be ready to explain the setup picture, the decision chain, and the mistakes that usually appear when the pace picks up."
    }
}

private func buildStudyNotesSummary(
    for event: SyllabusEventReferenceEventRecord,
    authoringProfile: FAMAuthoringProfile,
    sections: [FAMResolvedSectionDefinition]
) -> String {
    let sectionTitles = sections.map(\.title).filter { normalizedText($0) != normalizedText("Required Procedures") }
    let anchorSource = sectionTitles.count == 1 ? [event.shortTitle] : Array(sectionTitles.prefix(2))
    let anchor = anchorSource.map(summaryPhrase(from:))

    if event.discussionItems.contains(where: looksLikeEmergencyProcedureDiscussionItem) {
        let lead = anchor.isEmpty ? "the event priorities" : joinedPhrases(anchor)
        return "Keep \(lead) organized early, then know the immediate actions, branch logic, and N/W/C details before you start improvising."
    }

    switch authoringProfile {
    case .reviewSim:
        let lead = anchor.isEmpty ? "the cumulative brief" : joinedPhrases(anchor)
        return "Treat \(lead) like a spot check on the whole block: brief it cleanly, know the usual traps, and be ready to move to the next item without a reset."
    case .checkFlight:
        return "Prepare this like a cumulative check event: have the fundamentals organized early so the instructor cannot knock you off balance by jumping between topics."
    case .solo:
        return "Show up with the solo items already sorted, then use the day-of brief to confirm the go/no-go details instead of learning them from scratch."
    case .flight:
        let lead = anchor.isEmpty ? "the event flow" : joinedPhrases(anchor)
        return "Have \(lead) organized before step so the cockpit workload never outruns the brief."
    case .sim:
        let lead = anchor.isEmpty ? "the setup picture" : joinedPhrases(anchor)
        return "Focus on \(lead) first; the rest of the event gets much easier once the setup and the common misses are already clear."
    }
}

private func existingLines(for item: String, from override: ExistingOverride?) -> [String] {
    guard let override, let notes = override.studyNotes else { return [] }
    let target = normalizedText(item)

    for section in notes.sections {
        let title = normalizedText(section.title ?? "")
        if title == target || scoreMatch(candidate: item, line: section.title ?? "") >= 0.6 {
            return flatten(section.items)
        }
    }

    return []
}

private func flatten(_ items: [ExistingStudyNotesItem]) -> [String] {
    var results: [String] = []
    func walk(_ item: ExistingStudyNotesItem) {
        if !isScaffoldLabelLine(item.text) {
            results.append(item.text)
        }
        item.children?.forEach(walk)
    }
    items.forEach(walk)
    return filteredReadableLines(results.map(cleanLine).filter { !$0.isEmpty })
}

private func labeledItem(_ label: String, _ lines: [String]) -> StudyNotesItemOutput {
    StudyNotesItemOutput(
        text: label,
        children: uniqueStrings(lines).map { StudyNotesItemOutput(text: $0, children: nil) }
    )
}

private func pickLines(_ lines: [String], maxCount: Int, fallback: [String]) -> [String] {
    let picked = Array(uniqueStrings(lines).prefix(maxCount))
    return picked.isEmpty ? fallback : picked
}

private func answerLines(_ template: ReferenceCardTemplate) -> [String] {
    template.answer
        .components(separatedBy: .newlines)
        .map(cleanLine)
        .filter { !$0.isEmpty }
}

private func resolvedEmergencyProcedureTemplate(
    for item: String,
    epCardsByTitle: [String: ReferenceCardTemplate],
    emergencyProcedureAliases: [String: String]
) -> ReferenceCardTemplate? {
    let normalizedItem = normalizeReferenceTitle(item)
    if let direct = epCardsByTitle[normalizedItem] {
        return direct
    }

    if let aliasTitle = emergencyProcedureAliases[normalizedText(item)] {
        return epCardsByTitle[aliasTitle]
    }

    return nil
}

private func parseReferenceCards(from url: URL) throws -> [ReferenceCardTemplate] {
    let text = try String(contentsOf: url, encoding: .utf8)
    let cardBlocks = regexMatches(for: #"<card>(.*?)</card>"#, in: text)

    return cardBlocks.compactMap { block in
        guard let frontRaw = firstRegexMatch(for: #"<rich-text name='Front'>(.*?)</rich-text>"#, in: block),
              let backRaw = firstRegexMatch(for: #"<rich-text name='Back'>(.*?)</rich-text>"#, in: block) else {
            return nil
        }

        let prompt = normalizedRichText(from: frontRaw)
        let answer = normalizedRichText(from: backRaw)
        guard !prompt.isEmpty, !answer.isEmpty else { return nil }

        return ReferenceCardTemplate(
            prompt: prompt,
            answer: answer,
            normalizedTitle: normalizeReferenceTitle(prompt)
        )
    }
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
        .map(cleanLine)
        .filter { !$0.isEmpty }

    return lines.joined(separator: "\n")
}

private func writeOverride(_ output: EventContentOverrideOutput, to url: URL) throws {
    let encoder = JSONEncoder()
    encoder.outputFormatting = [.prettyPrinted, .sortedKeys]
    let data = try encoder.encode(output)
    try data.write(to: url)
}

private func loadExistingOverrides(at url: URL) -> [String: ExistingOverride] {
    guard let files = try? FileManager.default.contentsOfDirectory(at: url, includingPropertiesForKeys: nil) else {
        return [:]
    }

    let decoder = JSONDecoder()
    let overrides = files
        .filter { $0.pathExtension.lowercased() == "json" }
        .compactMap { fileURL -> ExistingOverride? in
            guard let data = try? Data(contentsOf: fileURL) else { return nil }
            return try? decoder.decode(ExistingOverride.self, from: data)
        }

    return dictionaryLastWins(overrides.map { (normalizeCode($0.code), $0) })
}

private func extractedLines(from url: URL, cache: inout [String: [String]]) -> [String] {
    if let cached = cache[url.path] {
        return cached
    }

    let lines = extractText(from: url)
        .components(separatedBy: .newlines)
        .map(cleanLine)
        .filter { !$0.isEmpty }
        .filter { !isAdministrativeLine($0) }

    cache[url.path] = uniqueStrings(lines)
    return cache[url.path] ?? []
}

private func extractText(from url: URL) -> String {
    switch url.pathExtension.lowercased() {
    case "docx":
        return extractDOCXText(from: url) ?? ""
    case "pdf":
        return extractPDFText(from: url) ?? ""
    default:
        return (try? String(contentsOf: url, encoding: .utf8)) ?? ""
    }
}

private func extractDOCXText(from url: URL) -> String? {
    let process = Process()
    process.executableURL = URL(fileURLWithPath: "/usr/bin/textutil")
    process.arguments = ["-convert", "txt", "-stdout", url.path]

    let pipe = Pipe()
    process.standardOutput = pipe
    process.standardError = Pipe()

    do {
        try process.run()
        process.waitUntilExit()
        guard process.terminationStatus == 0 else { return nil }
        let data = pipe.fileHandleForReading.readDataToEndOfFile()
        return String(data: data, encoding: .utf8)
    } catch {
        return nil
    }
}

private func extractPDFText(from url: URL) -> String? {
    guard let document = PDFDocument(url: url) else { return nil }
    var pages: [String] = []
    for pageIndex in 0..<document.pageCount {
        guard let page = document.page(at: pageIndex),
              let pageText = page.string,
              !pageText.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty else {
            continue
        }
        pages.append(pageText)
    }
    return pages.joined(separator: "\n")
}

private func sourceFileSort(lhs: URL, rhs: URL) -> Bool {
    let priority: (URL) -> Int = {
        switch $0.pathExtension.lowercased() {
        case "docx": return 0
        case "pdf": return 1
        default: return 2
        }
    }

    let lhsPriority = priority(lhs)
    let rhsPriority = priority(rhs)
    if lhsPriority != rhsPriority {
        return lhsPriority < rhsPriority
    }
    return lhs.lastPathComponent < rhs.lastPathComponent
}

private func allFiles(under root: URL) -> [URL] {
    let enumerator = FileManager.default.enumerator(at: root, includingPropertiesForKeys: nil)
    var results: [URL] = []
    while let item = enumerator?.nextObject() as? URL {
        var isDirectory: ObjCBool = false
        guard FileManager.default.fileExists(atPath: item.path, isDirectory: &isDirectory), !isDirectory.boolValue else {
            continue
        }
        results.append(item)
    }
    return results
}

private func inferredEventCode(from filename: String) -> String? {
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

private func normalizeCode(_ value: String) -> String {
    value.replacingOccurrences(of: " ", with: "")
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

private func normalizedText(_ value: String) -> String {
    value
        .trimmingCharacters(in: .whitespacesAndNewlines)
        .folding(options: [.diacriticInsensitive, .caseInsensitive], locale: .current)
        .lowercased()
        .replacingOccurrences(of: #"[“”]"#, with: "\"", options: .regularExpression)
        .replacingOccurrences(of: #"\s+"#, with: " ", options: .regularExpression)
}

private func titleCasedDiscussionItemPrompt(_ value: String) -> String {
    let trimmed = value.trimmingCharacters(in: .whitespacesAndNewlines)
    guard !trimmed.isEmpty else { return trimmed }

    var result = trimmed.lowercased().localizedCapitalized
    result = result.replacingOccurrences(of: #"\bAnd\b"#, with: "and", options: [.regularExpression])
    result = result.replacingOccurrences(of: #"\bOr\b"#, with: "or", options: [.regularExpression])
    result = result.replacingOccurrences(of: #"\bOf\b"#, with: "of", options: [.regularExpression])
    result = result.replacingOccurrences(of: #"\bIn\b"#, with: "in", options: [.regularExpression])
    result = result.replacingOccurrences(of: #"\bOn\b"#, with: "on", options: [.regularExpression])
    result = result.replacingOccurrences(of: #"\bTo\b"#, with: "to", options: [.regularExpression])
    result = result.replacingOccurrences(of: #"\bThe\b"#, with: "the", options: [.regularExpression])
    result = result.replacingOccurrences(of: #"\bA\b"#, with: "a", options: [.regularExpression])
    result = result.replacingOccurrences(of: #"\bAn\b"#, with: "an", options: [.regularExpression])

    let tokenReplacements: [(pattern: String, replacement: String)] = [
        (#"\bEp\b"#, "EP"),
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
        (#"\bIls\b"#, "ILS"),
        (#"\bVfr\b"#, "VFR"),
        (#"\bIfr\b"#, "IFR"),
        (#"\bAim\b"#, "AIM"),
        (#"\bCfs\b"#, "CFS"),
        (#"\bObogs\b"#, "OBOGS"),
        (#"\bPmu\b"#, "PMU"),
        (#"\bBfi\b"#, "BFI"),
        (#"\bHud\b"#, "HUD"),
        (#"\bUfcp\b"#, "UFCP"),
        (#"\bLop\b"#, "LOP"),
        (#"\bAoa\b"#, "AOA"),
        (#"\bOcf\b"#, "OCF"),
        (#"\bOdo/Fdo\b"#, "ODO/FDO")
    ]

    for replacement in tokenReplacements {
        result = result.replacingOccurrences(of: replacement.pattern, with: replacement.replacement, options: [.regularExpression])
    }

    return result
}

private func summaryPhrase(from title: String) -> String {
    title
        .replacingOccurrences(of: " / ", with: " and ")
        .replacingOccurrences(of: "/", with: " and ")
        .trimmingCharacters(in: .whitespacesAndNewlines)
}

private func overviewPhrase(from title: String) -> String {
    summaryPhrase(from: title).lowercased()
}

private func joinedPhrases<S: Sequence>(_ phrases: S) -> String where S.Element == String {
    let values = Array(phrases).filter { !$0.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty }
    switch values.count {
    case 0:
        return ""
    case 1:
        return values[0]
    case 2:
        if values[0].lowercased().contains(" and ") || values[1].lowercased().contains(" and ") {
            return "\(values[0]), plus \(values[1])"
        }
        return "\(values[0]) and \(values[1])"
    default:
        return values.dropLast().joined(separator: ", ") + ", and " + (values.last ?? "")
    }
}

private func isBoilerplateOverview(_ value: String?) -> Bool {
    guard let value else { return true }
    let normalized = normalizedText(value)
    return normalized.contains("is a sim event focused on") ||
        normalized.contains("is a flight event focused on")
}

private func isBoilerplateNotesSummary(_ value: String?) -> Bool {
    guard let value else { return true }
    let normalized = normalizedText(value)
    return normalized.contains("use these notes to cover every required discussion item in syllabus order")
}

private func cleanLine(_ value: String) -> String {
    value
        .replacingOccurrences(of: "\u{00A0}", with: " ")
        .replacingOccurrences(of: "\t", with: " ")
        .replacingOccurrences(of: #"^[\s•\-\*]+"#, with: "", options: .regularExpression)
        .replacingOccurrences(of: #"\s+"#, with: " ", options: .regularExpression)
        .trimmingCharacters(in: .whitespacesAndNewlines)
}

private func filteredReadableLines(_ values: [String], excluding item: String? = nil) -> [String] {
    let excluded = item.map(normalizedText)
    return uniqueStrings(values).filter { value in
        let normalized = normalizedText(value)
        guard !normalized.isEmpty else { return false }
        if let excluded, normalized == excluded {
            return false
        }
        return !isLowSignalSourceLine(value)
    }
}

private func isLowSignalSourceLine(_ value: String) -> Bool {
    let cleaned = cleanLine(value)
    let normalized = normalizedText(cleaned)
    let referenceNormalized = normalizeReferenceTitle(cleaned)
    if cleaned.isEmpty {
        return true
    }

    let exactLabels: Set<String> = [
        "description",
        "overview",
        "purpose",
        "setup",
        "setup / entry",
        "entry",
        "configuration",
        "procedure",
        "procedures",
        "execution",
        "operation",
        "operations",
        "response",
        "common errors",
        "key points",
        "types of failure",
        "types of abnormal starts",
        "types of abnormal start",
        "types of failure include",
        "recognition",
        "indications",
        "immediate actions",
        "decision logic",
        "n/w/cs",
        "n/w/c",
        "notes",
        "touchdown",
        "rotation",
        "final and flare",
        "message",
        "cause",
        "entry procedures",
        "transition procedures to nas corpus christi",
        "weather restrictions",
        "field elevation",
        "takeoff precautions",
        "approach precautions",
        "landing considerations",
        "important numbers",
        "prevention / detection",
        "windshear recovery",
        "procedures:",
        "configuration:"
    ]
    let labelCandidate = normalized.replacingOccurrences(of: ":", with: "")
    if exactLabels.contains(normalized) || exactLabels.contains(labelCandidate) {
        return true
    }

    if referenceNormalized.contains("changes the brief setup and in cockpit decision making") ||
        referenceNormalized.contains("why the instructor cares about it in this event") ||
        referenceNormalized.contains("build a clean plain language explanation") ||
        referenceNormalized.contains("student will use abbreviated simulator checklist") ||
        referenceNormalized.contains("special syllabus requirement") ||
        referenceNormalized.contains("naval air training command") ||
        referenceNormalized.contains("flight training instruction") ||
        referenceNormalized.contains("jppt 1542") ||
        referenceNormalized.contains("know them") ||
        referenceNormalized.contains("make the lines thicker") {
        return true
    }

    if cleaned.hasSuffix(":") && significantTokens(in: cleaned).count <= 4 {
        return true
    }

    if cleaned.hasSuffix("?") {
        return true
    }

    if cleaned == cleaned.uppercased() && significantTokens(in: cleaned).count >= 2 {
        return true
    }

    if cleaned == "(W)" || cleaned == "(C)" || cleaned == "(N)" || cleaned == "(W):" || cleaned == "(C):" || cleaned == "(N):" {
        return true
    }

    return false
}

private func stripLabel(from value: String) -> String {
    let cleaned = cleanLine(value)
    if let range = cleaned.range(of: ":") {
        let after = cleaned[range.upperBound...].trimmingCharacters(in: .whitespacesAndNewlines)
        return after.isEmpty ? cleaned : after
    }
    return cleaned
}

private func isAdministrativeLine(_ value: String) -> Bool {
    let normalized = normalizedText(value)
    return normalized == "discuss items" ||
        normalized == "ssrs" ||
        normalized == "n a" ||
        normalized.hasPrefix("fam") && normalized.count <= 8
}

private func isScaffoldLabelLine(_ value: String) -> Bool {
    let normalized = normalizeReferenceTitle(value)
    let labels: Set<String> = [
        "why it matters",
        "key knowledge",
        "application",
        "common errors grading traps",
        "purpose",
        "setup entry",
        "execution",
        "standards numbers",
        "recognition indications",
        "immediate actions procedure",
        "decision logic",
        "n w cs"
    ]
    return labels.contains(normalized)
}

private func significantTokens(in value: String) -> Set<String> {
    let ignoredWords: Set<String> = [
        "a", "an", "and", "the", "to", "of", "or", "for", "in", "on", "prior",
        "with", "all", "any", "be", "is", "per"
    ]

    return Set(
        normalizeReferenceTitle(value)
            .split(separator: " ")
            .map(String.init)
            .filter { $0.count > 1 && !ignoredWords.contains($0) }
    )
}

private func uniqueStrings(_ values: [String]) -> [String] {
    var seen = Set<String>()
    var result: [String] = []

    for value in values {
        let cleaned = value.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !cleaned.isEmpty else { continue }
        let key = normalizedText(cleaned)
        guard seen.insert(key).inserted else { continue }
        result.append(cleaned)
    }

    return result
}

private func uniqueURLs(_ values: [URL]) -> [URL] {
    var seen = Set<String>()
    var result: [URL] = []

    for value in values {
        guard seen.insert(value.path).inserted else { continue }
        result.append(value)
    }

    return result
}

private func dictionaryLastWins<Key: Hashable, Value>(_ pairs: [(Key, Value)]) -> [Key: Value] {
    var result: [Key: Value] = [:]
    for (key, value) in pairs {
        result[key] = value
    }
    return result
}

private func containsNumbers(_ value: String) -> Bool {
    value.rangeOfCharacter(from: .decimalDigits) != nil
}

private func looksLikeEmergencyProcedureDiscussionItem(_ value: String) -> Bool {
    let normalized = normalizedText(value)
    let signals = [
        "abort",
        "engine failure",
        "pel",
        "elp",
        "emergency",
        "air-start",
        "airstart",
        "eject",
        "forced landing",
        "chip detector",
        "fire",
        "oil",
        "power changes",
        "prop feather",
        "airstart",
        "obogs",
        "fuel pressure",
        "compressor stall",
        "high fuel flow",
        "precautionary",
        "ground egress",
        "cfs",
        "smoke and fume",
        "prepared surface"
    ]
    return signals.contains { normalized.contains($0) }
}

private func needsCourseRulesSupplement(_ value: String) -> Bool {
    let normalized = normalizedText(value)
    return normalized.contains("course rules") ||
        normalized.contains("olf") ||
        normalized.contains("sectional") ||
        normalized.contains("home field") ||
        normalized.contains("homefield") ||
        normalized.contains("local area flight procedures")
}

private func needsManeuverSupplement(_ value: String) -> Bool {
    let normalized = normalizedText(value)
    return normalized.contains("maneuver") ||
        normalized.contains("stall") ||
        normalized.contains("spin") ||
        normalized.contains("roll") ||
        normalized.contains("loop") ||
        normalized.contains("aoa") ||
        normalized.contains("scatsafe") ||
        normalized.contains("slow flight") ||
        normalized.contains("slip")
}

private func genericWhyItMatters(for item: String) -> String {
    "\(titleCasedDiscussionItemPrompt(item)) matters because it changes what you brief, what you look for in the cockpit, or what the next safe decision needs to be."
}

private func genericKeyKnowledgeFallback(for item: String) -> String {
    "Know the operational purpose, the pilot-visible cues, and the follow-on actions or limits tied to \(titleCasedDiscussionItemPrompt(item))."
}

private func genericApplication(for item: String) -> String {
    "Be ready to explain how \(titleCasedDiscussionItemPrompt(item)) changes the brief, the setup, or the next cockpit decision once the pace picks up."
}

private func genericKnowledgeTrap(for item: String) -> String {
    "The common trap is memorizing isolated facts about \(titleCasedDiscussionItemPrompt(item)) without being able to explain the operational consequence."
}

private func genericPurpose(for item: String) -> String {
    "\(titleCasedDiscussionItemPrompt(item)) is judged by how well you enter it, stay ahead of the aircraft, and recover without needing cleanup coaching."
}

private func genericSetup(for item: String) -> String {
    "Know the entry airspeed, altitude, configuration, and cockpit setup before you start the maneuver."
}

private func genericExecution(for item: String) -> String {
    "Brief the maneuver in order from setup through recovery, using the same language you will use in the cockpit."
}

private func genericStandards(for item: String) -> String {
    "Memorize the setup numbers and the recovery numbers for \(titleCasedDiscussionItemPrompt(item)); that is usually where the grading starts."
}

private func genericManeuverTrap(for item: String) -> String {
    "The usual trap is missing the setup picture, then trying to salvage \(titleCasedDiscussionItemPrompt(item)) late."
}

private func genericRecognition(for item: String) -> String {
    "Be able to state the cue that tells you \(titleCasedDiscussionItemPrompt(item)) is happening before you start reciting the steps."
}

private func genericProcedureFallback(for item: String) -> String {
    "Know the immediate actions for \(titleCasedDiscussionItemPrompt(item)) in order and be ready to explain what triggers each branch."
}

private func genericDecisionLogic(for item: String) -> String {
    "Know what makes this a continue, discontinue, PEL, forced-landing, or eject problem before the cockpit gets busy."
}

private func genericNWCRequirement(for item: String) -> String {
    "Review the associated WARNINGs, CAUTIONs, and NOTEs for \(titleCasedDiscussionItemPrompt(item)) before the event."
}

private func firstRegexMatch(for pattern: String, in text: String) -> String? {
    guard let regex = try? NSRegularExpression(pattern: pattern, options: [.dotMatchesLineSeparators]) else {
        return nil
    }
    let range = NSRange(text.startIndex..., in: text)
    guard let match = regex.firstMatch(in: text, range: range),
          match.numberOfRanges > 1,
          let swiftRange = Range(match.range(at: 1), in: text) else {
        return nil
    }
    return String(text[swiftRange])
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

private func discussionItemAliasesFor(_ item: String) -> [String] {
    let normalizedItem = normalizedText(item)
    var aliases: [String]
    switch normalizedItem {
    case normalizedText("Checklist challenge-action response format"):
        aliases = ["Checklist challenge-action-response format"]
    case normalizedText("dual concurrence/response CRM"):
        aliases = ["Dual concurrence response CRM", "Dual concurrence"]
    case normalizedText("battery bus light during start"):
        aliases = ["Battery bus warning during start", "BATT BUS warning during start"]
    case normalizedText("fire on ground"):
        aliases = ["Fire warning on the ground", "Fire on the ground"]
    case normalizedText("CFS and ejection CRM"):
        aliases = ["CFS", "Ejection seat and CFS"]
    case normalizedText("PMU NORM air-start"):
        aliases = ["PMU NORM air start", "PMU NORM airstart"]
    case normalizedText("PMU OFF air-start"):
        aliases = ["PMU OFF air start", "PMU OFF airstart"]
    case normalizedText("uncommanded power changes/LOP"):
        aliases = ["Uncommanded power changes", "Loss of power", "Uncommanded power changes loss of power uncommanded propeller feather"]
    case normalizedText("landing pattern (approach turn and landing attitude) stalls"):
        aliases = ["Landing pattern stalls", "Approach turn and landing attitude stalls"]
    case normalizedText("precautionary emergency landing (PEL) and BFI"):
        aliases = ["Precautionary emergency landing", "PEL and BFI"]
    case normalizedText("crosswind takeoff/touch-and-go/full-stop landings"):
        aliases = ["Crosswind takeoff", "Pattern Adjustments for Crosswinds", "Crosswind landings", "Crosswind landings, T&Gs, Full Stops", "Crosswind full-stops"]
    case normalizedText("Up Front Control Panel (UFCP) failure"):
        aliases = ["UFCP failure"]
    case normalizedText("OCF recovery and airborne damaged aircraft"):
        aliases = ["OCF recovery procedures", "Airborne damaged aircraft"]
    case normalizedText("T-6B VN diagram"):
        aliases = ["VN diagram", "T6B VN diagram"]
    case normalizedText("“IMSAFE” checklist"):
        aliases = ["IMSAFE checklist", "IMSAFE"]
    case normalizedText("Three Cs"):
        aliases = ["Three C's", "3 C's", "3 Cs"]
    case normalizedText("landing gear emergency extension"):
        aliases = ["Landing gear extension", "Emergency gear extension"]
    case normalizedText("local area flight procedures/SOP"):
        aliases = ["Local area flight procedures", "Local SOP"]
    case normalizedText("crosswind takeoff/approach/landing"):
        aliases = ["Crosswind takeoff", "Pattern Adjustments for Crosswinds", "Crosswind approach", "Crosswind landing", "Crosswind Landings, T&Gs, Full Stops"]
    case normalizedText("OLF Course rules for field of use"):
        aliases = ["OLF Course Rules for RUSTY, Goliad", "Rusty Departure", "Goliad", "Goliad Arrival", "Beachline Departure", "Aransas County", "PT SHAMROCK Procedures", "Northern Arrival"]
    case normalizedText("Per the ODO/FDO solo brief"):
        aliases = ["Securing Rear Cockpit for Solo", "Additional Solo Information/SOP", "Solo Briefing & Weather", "Landing Limitations", "Runway Requirements", "BASH Conditions", "NOLF Utilization"]
    default:
        aliases = []
    }

    let automaticAliases = splitAliases(for: item)
    return uniqueStrings(aliases + automaticAliases)
}

private func splitAliases(for item: String) -> [String] {
    var results: [String] = []
    let sanitized = item
        .replacingOccurrences(of: "(", with: "")
        .replacingOccurrences(of: ")", with: "")

    if sanitized.contains(" and ") {
        results.append(contentsOf: sanitized.components(separatedBy: " and ").map { $0.trimmingCharacters(in: .whitespacesAndNewlines) })
    }

    if sanitized.contains("/") {
        results.append(contentsOf: sanitized.components(separatedBy: "/").map { $0.trimmingCharacters(in: .whitespacesAndNewlines) })
    }

    return results.filter { !$0.isEmpty && normalizedText($0) != normalizedText(item) }
}
