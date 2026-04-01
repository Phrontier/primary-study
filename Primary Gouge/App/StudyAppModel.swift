import Foundation
import Combine
import SwiftUI

enum FlashcardPerformanceBand: String, CaseIterable, Hashable {
    case notStudied
    case gradeD
    case gradeC
    case gradeB
    case gradeA

    var label: String {
        switch self {
        case .notStudied: "New"
        case .gradeD: "D"
        case .gradeC: "C"
        case .gradeB: "B"
        case .gradeA: "A"
        }
    }

    var colorToken: String {
        switch self {
        case .notStudied: "muted"
        case .gradeD: "danger"
        case .gradeC: "warning"
        case .gradeB: "accent"
        case .gradeA: "success"
        }
    }

    var isAutomaticSmartReview: Bool {
        switch self {
        case .gradeC, .gradeD:
            return true
        case .notStudied, .gradeB, .gradeA:
            return false
        }
    }
}

struct DeckPerformanceSegment: Hashable {
    let band: FlashcardPerformanceBand
    let count: Int
}

struct DeckPerformanceSnapshot {
    let detail: String
    let smartReviewCount: Int
    let totalCount: Int
    let segments: [DeckPerformanceSegment]
}

struct FlashcardListItemSnapshot: Hashable {
    let card: FlashcardDefinition
    let band: FlashcardPerformanceBand
    let answerPreview: String
    let isPriority: Bool
}

struct SharedResourceGroupSnapshot: Identifiable, Hashable {
    let section: SharedResourceSection
    let resources: [SharedResource]

    var id: String { section.rawValue }
}

enum SearchScope: Hashable {
    case home
    case events(title: String, phaseID: String?, categoryID: String?)
    case instructors

    var prompt: String {
        switch self {
        case .home:
            return "Search events, instructors, and more"
        case .events:
            return "Search events"
        case .instructors:
            return "Search instructor or squadron"
        }
    }

    var emptyStateTitle: String {
        switch self {
        case .home:
            return "Search the whole app"
        case .events:
            return "Search events"
        case .instructors:
            return "Search instructors"
        }
    }

    var emptyStateMessage: String {
        switch self {
        case .home:
            return "Find the right event, instructor gouge, video, deck, or reference without digging through tabs."
        case let .events(title, _, _):
            return "Look up specific events quickly\(title.isEmpty ? "" : " within \(title)")."
        case .instructors:
            return "Search by instructor name or squadron to get to the right gouge faster."
        }
    }
}

enum SearchSectionKind: String, CaseIterable, Hashable {
    case events
    case instructors
    case generalLibrary
    case videos
    case phasesAndCategories
    case flashcardDecks

    var title: String {
        switch self {
        case .events: "Events"
        case .instructors: "Instructors"
        case .generalLibrary: "General Library"
        case .videos: "Videos"
        case .phasesAndCategories: "Phases & Categories"
        case .flashcardDecks: "Flashcard Decks"
        }
    }

    var iconName: String {
        switch self {
        case .events: "airplane.departure"
        case .instructors: "person.2.fill"
        case .generalLibrary: "books.vertical.fill"
        case .videos: "play.rectangle.fill"
        case .phasesAndCategories: "square.grid.2x2.fill"
        case .flashcardDecks: "rectangle.stack.fill"
        }
    }

    var accentColor: Color {
        switch self {
        case .events: AppTheme.accent
        case .instructors: AppTheme.success
        case .generalLibrary: AppTheme.warning
        case .videos: AppTheme.success
        case .phasesAndCategories: AppTheme.accent
        case .flashcardDecks: AppTheme.warning
        }
    }
}

enum SearchDestination: Hashable {
    case event(phaseID: String, eventID: String)
    case instructor(id: String)
    case sharedResource(id: String)
    case video(id: String)
    case phase(id: String)
    case category(phaseID: String, categoryID: String)
    case eventDeck(phaseID: String, eventID: String, deckID: String)
    case libraryDeck(id: String)
}

struct SearchResultItem: Identifiable, Hashable {
    let id: String
    let section: SearchSectionKind
    let title: String
    let subtitle: String
    let score: Int
    let destination: SearchDestination
}

struct SearchResultSectionSnapshot: Identifiable, Hashable {
    let section: SearchSectionKind
    let items: [SearchResultItem]

    var id: String { section.rawValue }
}

@MainActor
final class StudyAppModel: ObservableObject {
    @Published private(set) var studyManifest: StudyManifest
    @Published private(set) var quizBank: QuizBank
    @Published private(set) var dashboardSnapshot: DashboardSnapshot
    @Published private(set) var homeScreenSnapshot: HomeScreenSnapshot

    private let repository: ContentRepository
    var progressStore: ProgressStore?
    var quizStore: QuizStore?

    init(repository: ContentRepository, progressStore: ProgressStore? = nil) {
        self.repository = repository
        self.progressStore = progressStore
        self.studyManifest = repository.loadManifest()
        self.quizBank = repository.loadQuizBank()
        self.dashboardSnapshot = DashboardSnapshot.empty
        self.homeScreenSnapshot = HomeScreenSnapshot.empty
        if progressStore != nil {
            refreshSnapshot()
        }
    }

    convenience init() {
        self.init(repository: ContentRepository())
    }

    func configure(quizStore: QuizStore? = nil) {
        if progressStore == nil {
            progressStore = ProgressStore()
        }
        if let quizStore {
            self.quizStore = quizStore
        }
        refreshSnapshot()
    }

    func progress(for cardID: String) -> CardProgressSnapshot {
        progressStore?.progress(for: cardID) ?? .unseen
    }

    func markEventViewed(_ event: Event) {
        progressStore?.markEventViewed(eventID: event.id)
        if let phase = phase(containingEventID: event.id) {
            progressStore?.recordActivity(
                StudyActivityRecord(
                    kind: .event,
                    destination: .event(phaseID: phase.id, eventID: event.id),
                    title: event.code,
                    subtitle: event.displayTitle,
                    topicIDs: topicIDs(for: event),
                    progressContext: "Opened"
                )
            )
        }
        refreshSnapshot()
    }

    func markEventStudied(_ event: Event) {
        progressStore?.markEventStudied(eventID: event.id)
        if let phase = phase(containingEventID: event.id) {
            progressStore?.recordActivity(
                StudyActivityRecord(
                    kind: .event,
                    destination: .event(phaseID: phase.id, eventID: event.id),
                    title: event.code,
                    subtitle: event.displayTitle,
                    topicIDs: topicIDs(for: event),
                    completedAt: .now,
                    progressContext: "Studied"
                )
            )
        }
        refreshSnapshot()
    }

    func recordCardReview(card: FlashcardDefinition, rating: FlashcardRating) {
        progressStore?.recordReview(for: card.id, rating: rating)
        refreshSnapshot()
    }

    func cards(in deck: FlashcardDeck, filters: Set<FlashcardFilterToken> = []) -> [FlashcardDefinition] {
        let lookup = Dictionary(uniqueKeysWithValues: studyManifest.flashcards.map { ($0.id, $0) })
        let resolved = deck.cardIDs.compactMap { lookup[$0] }
        guard !filters.isEmpty else { return resolved }
        return resolved.filter { card in
            !Set(card.tags).isDisjoint(with: Set(filters.map(\.tagValue)))
        }
    }

    func smartReviewCards(in deck: FlashcardDeck, filters: Set<FlashcardFilterToken> = []) -> [FlashcardDefinition] {
        cards(in: deck, filters: filters)
            .filter { card in
                let snapshot = progress(for: card.id)
                return isSmartReviewCandidate(snapshot: snapshot, band: performanceBand(for: snapshot))
            }
            .sorted { lhs, rhs in
                spacedRepetitionPriority(for: lhs) > spacedRepetitionPriority(for: rhs)
            }
    }

    func focusedReviewCards(in deck: FlashcardDeck, startingWith cardID: String, filters: Set<FlashcardFilterToken> = []) -> [FlashcardDefinition] {
        let resolvedCards = cards(in: deck, filters: filters)
        guard let selectedIndex = resolvedCards.firstIndex(where: { $0.id == cardID }) else { return resolvedCards }

        let selected = resolvedCards[selectedIndex]
        let remaining = resolvedCards.enumerated()
            .filter { $0.offset != selectedIndex }
            .map(\.element)
            .sorted { lhs, rhs in
                spacedRepetitionPriority(for: lhs) > spacedRepetitionPriority(for: rhs)
            }

        return [selected] + remaining
    }

    func dueCardCount(for phase: Phase) -> Int {
        let cardIDs = phase.categories
            .flatMap(\.events)
            .flatMap(\.flashcardDecks)
            .flatMap(\.cardIDs)

        return cardIDs.filter { progress(for: $0).isDue }.count
    }

    func eventCount(for phase: Phase) -> Int {
        phase.categories.reduce(into: 0) { partialResult, category in
            partialResult += category.events.count
        }
    }

    func eventProgress(for eventID: String) -> EventProgressSnapshot {
        progressStore?.eventProgress(for: eventID) ?? .empty
    }

    func recordTestAttempt(bank: QuestionBank, topicIDs: [String], score: Int, total: Int, missedQuestionIDs: [String], elapsedSeconds: TimeInterval?) {
        progressStore?.recordTestAttempt(
            bankID: bank.id,
            score: score,
            total: total,
            missedQuestionIDs: missedQuestionIDs,
            topicIDs: topicIDs,
            elapsedSeconds: elapsedSeconds
        )
        refreshSnapshot()
    }

    func testHistory(for bankID: String) -> [TestAttemptRecord] {
        progressStore?.testHistory(for: bankID) ?? []
    }

    func briefingGuide(for event: Event) -> SourceDocument? {
        event.sourceDocuments.first { document in
            document.kind == .briefingGuide && event.primaryDocumentIDs.contains(document.id)
        }
    }

    func supplementalDocuments(for event: Event) -> [SourceDocument] {
        let primary = Set(event.primaryDocumentIDs)
        return event.sourceDocuments.filter { !primary.contains($0.id) && !$0.isWordDocument }
    }

    func sharedResources(for event: Event, placement: AssetPlacement? = nil) -> [SharedResource] {
        let links = event.resourceLinks.filter { placement == nil || $0.placement == placement }
        let ids = links.map(\.resourceID)
        return studyManifest.sharedResources
            .filter { ids.contains($0.id) }
            .sorted { lhs, rhs in
                (ids.firstIndex(of: lhs.id) ?? .max) < (ids.firstIndex(of: rhs.id) ?? .max)
            }
    }

    func videos(for event: Event, placement: AssetPlacement? = nil) -> [VideoAsset] {
        let links = event.videoLinks.filter { placement == nil || $0.placement == placement }
        let ids = links.map(\.videoID)
        return studyManifest.videos
            .filter { ids.contains($0.id) }
            .sorted { lhs, rhs in
                (ids.firstIndex(of: lhs.id) ?? .max) < (ids.firstIndex(of: rhs.id) ?? .max)
            }
    }

    func assembledScript(for event: Event) -> EventScript? {
        ScriptAssembler().assembleScript(for: event, using: studyManifest)
    }

    func resources(for hub: LibraryStudyHub) -> [SharedResource] {
        studyManifest.sharedResources
            .filter { hub.resourceIDs.contains($0.id) }
            .sorted { lhs, rhs in
                (hub.resourceIDs.firstIndex(of: lhs.id) ?? .max) < (hub.resourceIDs.firstIndex(of: rhs.id) ?? .max)
            }
    }

    func cardSnapshot(for card: FlashcardDefinition) -> FlashcardListItemSnapshot {
        let snapshot = progress(for: card.id)
        let band = performanceBand(for: snapshot)

        return FlashcardListItemSnapshot(
            card: card,
            band: band,
            answerPreview: answerPreview(for: card.answer),
            isPriority: isSmartReviewCandidate(snapshot: snapshot, band: band)
        )
    }

    func cardSnapshots(in deck: FlashcardDeck, filters: Set<FlashcardFilterToken> = []) -> [FlashcardListItemSnapshot] {
        cards(in: deck, filters: filters)
            .map(cardSnapshot(for:))
            .sorted { lhs, rhs in
                if lhs.band == rhs.band {
                    return lhs.card.prompt.localizedCaseInsensitiveCompare(rhs.card.prompt) == .orderedAscending
                }

                return bandRank(lhs.band) < bandRank(rhs.band)
            }
    }

    func deckPerformance(for deck: FlashcardDeck, filters: Set<FlashcardFilterToken> = []) -> DeckPerformanceSnapshot {
        let cards = cards(in: deck, filters: filters)
        let items = cards.map(cardSnapshot(for:))
        let segments = FlashcardPerformanceBand.allCases.map { band in
            DeckPerformanceSegment(band: band, count: items.filter { $0.band == band }.count)
        }
        let smartReviewCount = items.filter(\.isPriority).count

        guard !cards.isEmpty else {
            return DeckPerformanceSnapshot(
                detail: "This deck does not have any flashcards yet.",
                smartReviewCount: 0,
                totalCount: 0,
                segments: segments
            )
        }

        let detail: String
        if smartReviewCount > 0 {
            detail = smartReviewSummary(for: smartReviewCount)
        } else if items.contains(where: { $0.band == .notStudied }) {
            detail = "Start a few cards to establish your grade baseline."
        } else {
            detail = "Smart Review is clear. Study the full deck to stay sharp."
        }

        return DeckPerformanceSnapshot(
            detail: detail,
            smartReviewCount: smartReviewCount,
            totalCount: cards.count,
            segments: segments
        )
    }

    var generalLibraryStudyHubs: [LibraryStudyHub] {
        studyManifest.libraryStudyHubs
    }

    var generalLibraryResources: [SharedResource] {
        let hubResourceIDs = Set(studyManifest.libraryStudyHubs.flatMap(\.resourceIDs))
        return studyManifest.sharedResources
            .filter { $0.placement == .generalLibrary && !hubResourceIDs.contains($0.id) }
            .sorted { lhs, rhs in
                if lhs.librarySection == rhs.librarySection {
                    return lhs.title.localizedCaseInsensitiveCompare(rhs.title) == .orderedAscending
                }

                return sectionRank(lhs.librarySection) < sectionRank(rhs.librarySection)
            }
    }

    var generalLibraryGroupedResources: [SharedResourceGroupSnapshot] {
        SharedResourceSection.allCases
            .filter { $0 != .videos }
            .compactMap { section in
                let resources = generalLibraryResources.filter { $0.librarySection == section }
                guard !resources.isEmpty else { return nil }
                return SharedResourceGroupSnapshot(section: section, resources: resources)
            }
    }

    var generalLibraryVideos: [VideoAsset] {
        let ids = Set(
            studyManifest.phases
                .flatMap(\.categories)
                .flatMap(\.events)
                .flatMap(\.videoLinks)
                .filter { $0.placement == .generalLibrary }
                .map(\.videoID)
        )
        return studyManifest.videos.filter { ids.contains($0.id) }
    }

    var homeTabSnapshot: HomeTabSnapshot {
        HomeTabSnapshot.build(from: dashboardSnapshot)
    }

    var studyTopics: [StudyTopicDefinition] {
        StudyTopicDefinition.homeTopics
    }

    func setPinnedTopicIDs(_ topicIDs: [String]) {
        progressStore?.updateHomePreferences { preferences in
            preferences.pinnedTopicIDs = topicIDs
        }
        refreshSnapshot()
    }

    func answerQuestionOfDay(_ question: HomeQuestionDefinition, choiceID: String) {
        guard progressStore?.dailyQuestionProgress(for: question.id)?.answeredAt == nil else { return }

        let answeredAt = Date.now
        let wasCorrect = question.isCorrect(choiceID: choiceID)

        progressStore?.updateDailyQuestionProgress(for: question.id) { progress in
            progress.lastPresentedOn = answeredAt
            progress.revealedAt = answeredAt
            progress.selectedChoiceID = choiceID
            progress.answeredAt = answeredAt
            progress.wasCorrect = wasCorrect
            progress.lastRating = nil
            progress.savedForLaterAt = nil
        }

        if let sourceQuestion = quizBank.question(id: question.sourceQuestionID) {
            quizStore?.recordQuestionOutcome(
                question: sourceQuestion,
                selectedChoiceID: choiceID,
                answeredAt: answeredAt
            )
        }

        progressStore?.recordActivity(
            StudyActivityRecord(
                kind: .questionOfDay,
                destination: .questionOfDay(questionID: question.id),
                title: "Question of the Day",
                subtitle: question.prompt,
                topicIDs: question.topicIDs,
                startedAt: answeredAt,
                lastInteractedAt: answeredAt,
                completedAt: answeredAt,
                progressContext: wasCorrect ? "Answered Correct" : "Answered Incorrect"
            )
        )
        progressStore?.updateHomePreferences { preferences in
            preferences.lastQuestionOfDayDate = answeredAt
        }
        refreshSnapshot()
    }

    func recordDeckOpened(event: Event?, deck: FlashcardDeck, contextLabel: String) {
        let destination: StudyActivityDestination
        if let event, let phase = phase(containingEventID: event.id) {
            destination = .eventDeck(phaseID: phase.id, eventID: event.id, deckID: deck.id)
        } else if let hub = libraryHub(containingDeckID: deck.id) {
            destination = .libraryDeck(id: hub.id)
        } else {
            return
        }

        progressStore?.recordActivity(
            StudyActivityRecord(
                kind: .flashcardDeck,
                destination: destination,
                title: deck.title,
                subtitle: contextLabel,
                topicIDs: topicIDs(for: deck, event: event),
                progressContext: "Opened"
            )
        )
        refreshSnapshot()
    }

    func recordSharedResourceOpened(_ resource: SharedResource) {
        progressStore?.recordActivity(
            StudyActivityRecord(
                kind: .sharedResource,
                destination: .sharedResource(id: resource.id),
                title: resource.title,
                subtitle: resource.summary,
                topicIDs: topicIDs(for: resource),
                progressContext: "Opened"
            )
        )
        refreshSnapshot()
    }

    func recordVideoOpened(_ video: VideoAsset) {
        progressStore?.recordActivity(
            StudyActivityRecord(
                kind: .video,
                destination: .video(id: video.id),
                title: video.title,
                subtitle: video.summary,
                topicIDs: topicIDs(for: video),
                progressContext: "Opened"
            )
        )
        refreshSnapshot()
    }

    func recordStudySession(
        kind: StudySessionKind,
        topicIDs: [String],
        startedAt: Date,
        endedAt: Date,
        completedItems: Int,
        totalItems: Int,
        outcome: StudySessionOutcome,
        activity: StudyActivityRecord?
    ) {
        progressStore?.recordSession(
            StudySessionRecord(
                activityKind: kind,
                topicIDs: topicIDs,
                startedAt: startedAt,
                endedAt: endedAt,
                completedItems: completedItems,
                totalItems: totalItems,
                outcome: outcome
            )
        )

        if let activity {
            progressStore?.recordActivity(activity)
        }

        refreshSnapshot()
    }

    func phaseKnowledgeResources(for phase: Phase) -> [SharedResource] {
        studyManifest.sharedResources
            .filter { $0.placement == .phaseKnowledge && $0.phaseIDs.contains(phase.id) }
            .sorted { lhs, rhs in
                if lhs.librarySection == rhs.librarySection {
                    return lhs.title.localizedCaseInsensitiveCompare(rhs.title) == .orderedAscending
                }

                return sectionRank(lhs.librarySection) < sectionRank(rhs.librarySection)
            }
    }

    func homeSearchSections(query: String, instructors: [Instructor]) -> [SearchResultSectionSnapshot] {
        let normalizedQuery = normalizedSearchQuery(query)
        guard !normalizedQuery.isEmpty else { return [] }

        let sectionOrder: [SearchSectionKind] = [
            .events,
            .instructors,
            .generalLibrary,
            .videos,
            .phasesAndCategories,
            .flashcardDecks
        ]

        let sections: [SearchSectionKind: [SearchResultItem]] = [
            .events: globalEventSearchItems(query: normalizedQuery, phaseID: nil, categoryID: nil),
            .instructors: instructorSearchItems(query: normalizedQuery, instructors: instructors),
            .generalLibrary: sharedResourceSearchItems(query: normalizedQuery),
            .videos: videoSearchItems(query: normalizedQuery),
            .phasesAndCategories: phaseAndCategorySearchItems(query: normalizedQuery),
            .flashcardDecks: deckSearchItems(query: normalizedQuery)
        ]

        return sectionOrder.compactMap { section in
            guard let items = sections[section], !items.isEmpty else { return nil }
            return SearchResultSectionSnapshot(section: section, items: items)
        }
    }

    func eventSearchSections(query: String, phaseID: String?, categoryID: String?) -> [SearchResultSectionSnapshot] {
        let normalizedQuery = normalizedSearchQuery(query)
        guard !normalizedQuery.isEmpty else { return [] }

        let items = globalEventSearchItems(query: normalizedQuery, phaseID: phaseID, categoryID: categoryID)
        guard !items.isEmpty else { return [] }
        return [SearchResultSectionSnapshot(section: .events, items: items)]
    }

    func instructorSearchSections(query: String, instructors: [Instructor]) -> [SearchResultSectionSnapshot] {
        let normalizedQuery = normalizedSearchQuery(query)
        guard !normalizedQuery.isEmpty else { return [] }

        let items = instructorSearchItems(query: normalizedQuery, instructors: instructors)
        guard !items.isEmpty else { return [] }
        return [SearchResultSectionSnapshot(section: .instructors, items: items)]
    }

    func phase(id: String) -> Phase? {
        studyManifest.phases.first { $0.id == id }
    }

    func category(phaseID: String, categoryID: String) -> StudyCategory? {
        phase(id: phaseID)?.categories.first { $0.id == categoryID }
    }

    func event(phaseID: String, eventID: String) -> Event? {
        phase(id: phaseID)?.categories.flatMap(\.events).first { $0.id == eventID }
    }

    func eventContext(for eventID: String) -> (phase: Phase, event: Event)? {
        for phase in studyManifest.phases {
            if let event = phase.categories.flatMap(\.events).first(where: { $0.id == eventID }) {
                return (phase, event)
            }
        }
        return nil
    }

    func eventDeckContext(phaseID: String, eventID: String, deckID: String) -> (Event, FlashcardDeck)? {
        guard let event = event(phaseID: phaseID, eventID: eventID),
              let deck = event.flashcardDecks.first(where: { $0.id == deckID }) else {
            return nil
        }
        return (event, deck)
    }

    func sharedResource(id: String) -> SharedResource? {
        studyManifest.sharedResources.first { $0.id == id }
    }

    func video(id: String) -> VideoAsset? {
        studyManifest.videos.first { $0.id == id }
    }

    func libraryHub(id: String) -> LibraryStudyHub? {
        studyManifest.libraryStudyHubs.first { $0.id == id }
    }

    private func spacedRepetitionPriority(for card: FlashcardDefinition) -> Double {
        let snapshot = progress(for: card.id)
        var score = 1.0 - snapshot.mastery
        if snapshot.isDue { score += 1.0 }
        if let nextReview = snapshot.nextReviewAt {
            score += max(0, Date().timeIntervalSince(nextReview) / 86_400.0) * 0.15
        }
        return score
    }

    private func bandRank(_ band: FlashcardPerformanceBand) -> Int {
        switch band {
        case .notStudied: 0
        case .gradeD: 1
        case .gradeC: 2
        case .gradeB: 3
        case .gradeA: 4
        }
    }

    private func sectionRank(_ section: SharedResourceSection) -> Int {
        switch section {
        case .videos: 0
        case .eps: 1
        case .limits: 2
        case .nwc: 3
        case .supplements: 4
        }
    }

    private func answerPreview(for answer: String) -> String {
        let collapsed = answer
            .replacingOccurrences(of: "\n", with: " ")
            .replacingOccurrences(of: "\t", with: " ")
            .replacingOccurrences(of: "  ", with: " ")
            .trimmingCharacters(in: .whitespacesAndNewlines)

        guard collapsed.count > 140 else { return collapsed }
        let index = collapsed.index(collapsed.startIndex, offsetBy: 137)
        return String(collapsed[..<index]) + "..."
    }

    private func performanceBand(for snapshot: CardProgressSnapshot) -> FlashcardPerformanceBand {
        if snapshot.lastReviewedAt == nil {
            return .notStudied
        }

        switch snapshot.mastery {
        case ..<0.3:
            return .gradeD
        case ..<0.6:
            return .gradeC
        case ..<0.8:
            return .gradeB
        default:
            return .gradeA
        }
    }

    private func isSmartReviewCandidate(snapshot: CardProgressSnapshot, band: FlashcardPerformanceBand) -> Bool {
        snapshot.isDue || band.isAutomaticSmartReview || band == .notStudied
    }

    private func smartReviewSummary(for count: Int) -> String {
        count == 1
            ? "1 card is ready for Smart Review."
            : "\(count) cards are ready for Smart Review."
    }

    private func globalEventSearchItems(query: String, phaseID: String?, categoryID: String?) -> [SearchResultItem] {
        var results: [SearchResultItem] = []

        for phase in studyManifest.phases {
            guard phaseID == nil || phase.id == phaseID else { continue }

            for category in phase.categories {
                guard categoryID == nil || category.id == categoryID else { continue }

                for event in category.events {
                    let score = eventSearchScore(query: query, event: event)
                    guard score > 0 else { continue }

                    results.append(
                        SearchResultItem(
                            id: "event-\(event.id)",
                            section: .events,
                            title: event.code,
                            subtitle: event.displayTitle == event.code
                                ? "\(phase.title) • \(category.displayName)"
                                : "\(event.displayTitle) • \(phase.title) • \(category.displayName)",
                            score: score,
                            destination: .event(phaseID: phase.id, eventID: event.id)
                        )
                    )
                }
            }
        }

        return results
            .sorted(by: searchSort)
            .prefix(8)
            .map { $0 }
    }

    private func instructorSearchItems(query: String, instructors: [Instructor]) -> [SearchResultItem] {
        instructors
            .compactMap { instructor -> SearchResultItem? in
                let score = max(
                    scoreMatch(query: query, text: instructor.name, exact: 130, prefix: 110, contains: 85),
                    scoreMatch(query: query, text: instructor.squadron.displayName, exact: 95, prefix: 80, contains: 60)
                )

                guard score > 0 else { return nil }

                return SearchResultItem(
                    id: "instructor-\(instructor.id)",
                    section: .instructors,
                    title: instructor.name,
                    subtitle: "\(instructor.squadron.displayName) • \(instructor.publishedReviewCount) reviews",
                    score: score,
                    destination: .instructor(id: instructor.id)
                )
            }
            .sorted(by: searchSort)
            .prefix(8)
            .map { $0 }
    }

    private func sharedResourceSearchItems(query: String) -> [SearchResultItem] {
        studyManifest.sharedResources
            .filter { $0.placement != .eventOnly }
            .compactMap { resource -> SearchResultItem? in
                let score = max(
                    scoreMatch(query: query, text: resource.title, exact: 115, prefix: 95, contains: 72),
                    scoreMatch(query: query, text: resource.summary, exact: 0, prefix: 0, contains: 46),
                    bestTagScore(query: query, tags: resource.tags, matchScore: 58)
                )

                guard score > 0 else { return nil }

                let contextLabel = resource.placement == .generalLibrary ? "General Library" : "Shared reference"

                return SearchResultItem(
                    id: "resource-\(resource.id)",
                    section: .generalLibrary,
                    title: resource.title,
                    subtitle: "\(contextLabel) • \(resource.summary)",
                    score: score,
                    destination: .sharedResource(id: resource.id)
                )
            }
            .sorted(by: searchSort)
            .prefix(8)
            .map { $0 }
    }

    private func videoSearchItems(query: String) -> [SearchResultItem] {
        studyManifest.videos
            .compactMap { video -> SearchResultItem? in
                let score = max(
                    scoreMatch(query: query, text: video.title, exact: 110, prefix: 90, contains: 70),
                    scoreMatch(query: query, text: video.summary, exact: 0, prefix: 0, contains: 45),
                    bestTagScore(query: query, tags: video.tags, matchScore: 58)
                )

                guard score > 0 else { return nil }

                return SearchResultItem(
                    id: "video-\(video.id)",
                    section: .videos,
                    title: video.title,
                    subtitle: video.summary,
                    score: score,
                    destination: .video(id: video.id)
                )
            }
            .sorted(by: searchSort)
            .prefix(8)
            .map { $0 }
    }

    private func phaseAndCategorySearchItems(query: String) -> [SearchResultItem] {
        var items: [SearchResultItem] = []

        for phase in studyManifest.phases {
            let phaseScore = max(
                scoreMatch(query: query, text: phase.title, exact: 95, prefix: 78, contains: 62),
                scoreMatch(query: query, text: phase.summary, exact: 0, prefix: 0, contains: 36)
            )

            if phaseScore > 0 {
                items.append(
                    SearchResultItem(
                        id: "phase-\(phase.id)",
                        section: .phasesAndCategories,
                        title: phase.title,
                        subtitle: "Phase",
                        score: phaseScore,
                        destination: .phase(id: phase.id)
                    )
                )
            }

            for category in phase.categories {
                let categoryScore = max(
                    scoreMatch(query: query, text: category.displayName, exact: 92, prefix: 74, contains: 58),
                    scoreMatch(query: query, text: category.summary, exact: 0, prefix: 0, contains: 35)
                )

                guard categoryScore > 0 else { continue }

                items.append(
                    SearchResultItem(
                        id: "category-\(phase.id)-\(category.id)",
                        section: .phasesAndCategories,
                        title: category.displayName,
                        subtitle: phase.title,
                        score: categoryScore,
                        destination: .category(phaseID: phase.id, categoryID: category.id)
                    )
                )
            }
        }

        return items
            .sorted(by: searchSort)
            .prefix(8)
            .map { $0 }
    }

    private func deckSearchItems(query: String) -> [SearchResultItem] {
        var items: [SearchResultItem] = []

        for phase in studyManifest.phases {
            for category in phase.categories {
                for event in category.events {
                    for deck in event.flashcardDecks {
                        let score = max(
                            scoreMatch(query: query, text: deck.title, exact: 100, prefix: 80, contains: 62),
                            scoreMatch(query: query, text: deck.summary, exact: 0, prefix: 0, contains: 42),
                            scoreMatch(query: query, text: event.code, exact: 80, prefix: 65, contains: 50)
                        )

                        guard score > 0 else { continue }

                        items.append(
                            SearchResultItem(
                                id: "event-deck-\(deck.id)",
                                section: .flashcardDecks,
                                title: deck.title,
                                subtitle: "\(event.code) • \(event.displayTitle)",
                                score: score,
                                destination: .eventDeck(phaseID: phase.id, eventID: event.id, deckID: deck.id)
                            )
                        )
                    }
                }
            }
        }

        for hub in studyManifest.libraryStudyHubs {
            let score = max(
                scoreMatch(query: query, text: hub.deck.title, exact: 100, prefix: 80, contains: 62),
                scoreMatch(query: query, text: hub.deck.summary, exact: 0, prefix: 0, contains: 42)
            )

            guard score > 0 else { continue }

            items.append(
                SearchResultItem(
                    id: "library-deck-\(hub.id)",
                    section: .flashcardDecks,
                    title: hub.deck.title,
                    subtitle: "General Library",
                    score: score,
                    destination: .libraryDeck(id: hub.id)
                )
            )
        }

        return items
            .sorted(by: searchSort)
            .prefix(8)
            .map { $0 }
    }

    private func eventSearchScore(query: String, event: Event) -> Int {
        let categoryText = event.categoryKind.displayName
        let deckTitles = event.flashcardDecks.map(\.title).joined(separator: " ")
        let bankTitles = event.questionBanks.map(\.title).joined(separator: " ")

        return max(
            scoreMatch(query: query, text: event.code, exact: 150, prefix: 125, contains: 110),
            scoreMatch(query: query, text: event.displayTitle, exact: 110, prefix: 90, contains: 78),
            scoreMatch(query: query, text: event.summary, exact: 0, prefix: 0, contains: 42),
            scoreMatch(query: query, text: event.overview, exact: 0, prefix: 0, contains: 36),
            scoreMatch(query: query, text: categoryText, exact: 80, prefix: 60, contains: 44),
            scoreMatch(query: query, text: deckTitles, exact: 0, prefix: 0, contains: 34),
            scoreMatch(query: query, text: bankTitles, exact: 0, prefix: 0, contains: 34),
            bestTagScore(query: query, tags: event.tags, matchScore: 55)
        )
    }

    private func normalizedSearchQuery(_ query: String) -> String {
        normalizedSearchText(query)
    }

    private func normalizedSearchText(_ value: String) -> String {
        value
            .trimmingCharacters(in: .whitespacesAndNewlines)
            .folding(options: [.diacriticInsensitive, .caseInsensitive], locale: .current)
            .lowercased()
    }

    private func scoreMatch(query: String, text: String, exact: Int, prefix: Int, contains: Int) -> Int {
        let normalizedText = normalizedSearchText(text)
        guard !query.isEmpty, !normalizedText.isEmpty else { return 0 }

        if normalizedText == query { return exact }
        if normalizedText.hasPrefix(query) { return prefix }
        if normalizedText.contains(query) { return contains }
        return 0
    }

    private func bestTagScore(query: String, tags: [String], matchScore: Int) -> Int {
        tags.contains(where: { normalizedSearchText($0).contains(query) }) ? matchScore : 0
    }

    private func searchSort(lhs: SearchResultItem, rhs: SearchResultItem) -> Bool {
        if lhs.score == rhs.score {
            return lhs.title.localizedCaseInsensitiveCompare(rhs.title) == .orderedAscending
        }
        return lhs.score > rhs.score
    }

    private func refreshSnapshot() {
        dashboardSnapshot = DashboardSnapshot(
            phases: studyManifest.phases.count,
            events: studyManifest.phases.flatMap(\.categories).flatMap(\.events).count,
            dueCards: studyManifest.phases.reduce(into: 0) { $0 += dueCardCount(for: $1) },
            completedEvents: studyManifest.phases
                .flatMap(\.categories)
                .flatMap(\.events)
                .filter { eventProgress(for: $0.id).completedAt != nil }
                .count
        )
        homeScreenSnapshot = buildHomeScreenSnapshot()
    }

    static var preview: StudyAppModel {
        StudyAppModel(repository: .preview)
    }
}

struct HomeScreenSnapshot: Equatable {
    let greeting: String
    let statusLine: String
    let continueStudying: HomeContinueStudyingSnapshot
    let currentFocus: HomeCurrentFocusSnapshot
    let reviewDue: [HomeTopicActionSnapshot]
    let weakAreas: [HomeTopicActionSnapshot]
    let questionOfDay: HomeQuestionOfDaySnapshot
    let studyStreak: Int

    static let empty = HomeScreenSnapshot(
        greeting: "Welcome back",
        statusLine: "Ready to study",
        continueStudying: .empty,
        currentFocus: .empty,
        reviewDue: [],
        weakAreas: [],
        questionOfDay: .empty,
        studyStreak: 0
    )
}

struct HomeContinueStudyingSnapshot: Equatable {
    let title: String
    let subtitle: String
    let detail: String
    let actionTitle: String
    let destination: SearchDestination?
    let isFallback: Bool

    static let empty = HomeContinueStudyingSnapshot(
        title: "Start with emergency references",
        subtitle: "EPs, limits, and recurring memory items",
        detail: "Use the General Library to get into the highest-value material without digging through phases.",
        actionTitle: "Open EPs / Limits / N/W/C",
        destination: .libraryDeck(id: "emergency-reference-hub"),
        isFallback: true
    )
}

struct HomeCurrentFocusSnapshot: Equatable {
    let pinnedTopics: [HomeFocusTopicSnapshot]
    let suggestedTopics: [HomeFocusTopicSnapshot]

    static let empty = HomeCurrentFocusSnapshot(pinnedTopics: [], suggestedTopics: [])
}

struct HomeFocusTopicSnapshot: Identifiable, Equatable {
    let id: String
    let title: String
    let iconName: String
    let destination: SearchDestination?
}

struct HomeTopicActionSnapshot: Identifiable, Equatable {
    let id: String
    let title: String
    let detail: String
    let actionTitle: String
    let iconName: String
    let destination: SearchDestination?
    let urgency: HomeTopicUrgency
}

enum HomeTopicUrgency: Equatable {
    case neutral
    case warning
    case alert
}

struct HomeQuestionOfDaySnapshot: Equatable {
    let question: HomeQuestionDefinition?
    let selectedChoiceID: String?
    let wasCorrect: Bool?

    var isAnswered: Bool {
        selectedChoiceID != nil
    }

    static let empty = HomeQuestionOfDaySnapshot(
        question: nil,
        selectedChoiceID: nil,
        wasCorrect: nil
    )
}

struct DashboardSnapshot: Equatable {
    let phases: Int
    let events: Int
    let dueCards: Int
    let completedEvents: Int

    static let empty = DashboardSnapshot(phases: 0, events: 0, dueCards: 0, completedEvents: 0)
}

struct HomeTaskSnapshot: Identifiable, Equatable {
    let id: String
    let title: String
    let detail: String
    let iconName: String
    let eyebrow: String
}

struct HomeReviewPromptSnapshot: Identifiable, Equatable {
    let id: String
    let title: String
    let detail: String
    let cue: String
    let iconName: String
}

struct HomeTabSnapshot: Equatable {
    let tasks: [HomeTaskSnapshot]
    let progressHeadline: String
    let progressDetail: String
    let reviewPrompts: [HomeReviewPromptSnapshot]
    let questionTitle: String
    let questionPrompt: String
    let questionHint: String
    let dueCards: Int
    let completedEvents: Int
    let totalEvents: Int

    static func build(from dashboard: DashboardSnapshot) -> HomeTabSnapshot {
        let progressHeadline: String
        if dashboard.dueCards > 0 {
            progressHeadline = "\(dashboard.dueCards) review items need attention."
        } else if dashboard.completedEvents > 0 {
            progressHeadline = "You are current on your review queue."
        } else {
            progressHeadline = "Your study dashboard is ready to build momentum."
        }

        let progressDetail: String
        if dashboard.events > 0 {
            progressDetail = "You have completed \(dashboard.completedEvents) of \(dashboard.events) event hubs, and the home screen is now set up to surface daily priorities as those workflows come online."
        } else {
            progressDetail = "As your study catalog grows, this area will summarize event completion, review pressure, and your next best study move."
        }

        let tasks = [
            HomeTaskSnapshot(
                id: "smart-review",
                title: "Smart Review",
                detail: dashboard.dueCards > 0
                    ? "\(dashboard.dueCards) cards are already due, so this will become your fastest path back into EPs, limits, and recurring memory items."
                    : "No cards are due right now, so this slot is ready for short refresher reps once the daily engine is added.",
                iconName: "rectangle.stack.badge.play.fill",
                eyebrow: "Daily task"
            ),
            HomeTaskSnapshot(
                id: "event-progress",
                title: "Event Progress",
                detail: dashboard.events > 0
                    ? "Track momentum across \(dashboard.events) event hubs and quickly see which phase blocks still need work."
                    : "As event content expands, this card will call out the next block that needs focused prep.",
                iconName: "chart.line.uptrend.xyaxis",
                eyebrow: "Progress"
            ),
            HomeTaskSnapshot(
                id: "memory-items",
                title: "Memory Items",
                detail: "Use short recurring prompts to keep EPs, limits, and N/W/C callouts fresh even when you are between briefs or sims.",
                iconName: "brain.head.profile",
                eyebrow: "Retention"
            )
        ]

        let reviewPrompts = [
            HomeReviewPromptSnapshot(
                id: "eps",
                title: "EPs",
                detail: "Surface emergency procedures that have not been touched recently so the app can steer you back into the boldface and immediate-action flow.",
                cue: "High priority",
                iconName: "exclamationmark.shield.fill"
            ),
            HomeReviewPromptSnapshot(
                id: "limits",
                title: "Limits",
                detail: "Flag the hard numbers that drift the fastest and group them into quick-hit review sets before an event or brief.",
                cue: "Numbers",
                iconName: "gauge.with.dots.needle.bottom.50percent"
            ),
            HomeReviewPromptSnapshot(
                id: "nwc",
                title: "N/W/C",
                detail: "Bring back notes, warnings, and cautions that should stay familiar long after the last flashcard session ended.",
                cue: "Memory set",
                iconName: "triangle.fill"
            )
        ]

        let questionPrompt = dashboard.dueCards > 0
            ? "What item could you brief cleanly from memory right now without opening a note or checklist?"
            : "If you had five focused minutes, which phase or event would sharpen your next flight the most?"

        return HomeTabSnapshot(
            tasks: tasks,
            progressHeadline: progressHeadline,
            progressDetail: progressDetail,
            reviewPrompts: reviewPrompts,
            questionTitle: "Question of the day",
            questionPrompt: questionPrompt,
            questionHint: "This area is a polished placeholder for the future QOTD system and will eventually capture quick confidence-building answers inside the app.",
            dueCards: dashboard.dueCards,
            completedEvents: dashboard.completedEvents,
            totalEvents: dashboard.events
        )
    }
}
