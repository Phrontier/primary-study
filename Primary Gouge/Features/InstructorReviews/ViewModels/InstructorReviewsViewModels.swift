import Combine
import Foundation
import SwiftUI

@MainActor
final class InstructorReviewsRootViewModel: ObservableObject {
    @Published var searchText = "" {
        didSet { refreshSearch() }
    }
    @Published var selectedFilter: InstructorCapabilityFilter = .all {
        didSet { applyFilters() }
    }
    @Published private(set) var instructors: [Instructor] = []
    @Published private(set) var totalPublishedReviews = 0
    @Published private(set) var hasPublishedReviews = false
    private weak var repository: (any InstructorReviewRepository)?
    private var searchedInstructors: [Instructor] = []

    func load(using repository: InstructorReviewRepository) {
        self.repository = repository
        let allInstructors = repository.fetchInstructorSummaries(searchText: "")
        totalPublishedReviews = allInstructors.reduce(0) { $0 + $1.publishedReviewCount }
        hasPublishedReviews = !allInstructors.isEmpty
        refreshSearch()
    }

    private func refreshSearch() {
        guard let repository else {
            searchedInstructors = []
            instructors = []
            return
        }

        searchedInstructors = repository.fetchInstructorSummaries(searchText: searchText)
        applyFilters()
    }

    private func applyFilters() {
        instructors = searchedInstructors.filter(selectedFilter.includes)
    }
}

@MainActor
final class InstructorReviewDetailViewModel: ObservableObject {
    @Published var selectedSort: InstructorReviewSortOption = .mostRecent {
        didSet { applySort() }
    }
    @Published private(set) var instructor: Instructor
    @Published private(set) var reviews: [InstructorReview] = []
    private var allReviews: [InstructorReview] = []

    init(instructor: Instructor) {
        self.instructor = instructor
    }

    func load(using repository: InstructorReviewRepository) {
        if let refreshedInstructor = repository.fetchInstructor(id: instructor.id) {
            instructor = refreshedInstructor
        }

        allReviews = repository.fetchPublishedReviews(for: instructor.id)
        applySort()
    }

    private func applySort() {
        reviews = selectedSort.sorted(allReviews)
    }
}

@MainActor
final class ReviewSubmissionViewModel: ObservableObject {
    @Published var instructorName = ""
    @Published var submissionMode: InstructorSubmissionMode = .both {
        didSet { handleSubmissionModeChange() }
    }
    @Published var selectedSquadron: Squadron? {
        didSet { handleSquadronChange() }
    }
    @Published var eventName = "" {
        didSet { syncSelectedEventWithTypedEvent() }
    }
    @Published var selectedEvent: InstructorReviewEvent?
    @Published var chillScore: Int?
    @Published var gradingScore: Int?
    @Published var reviewText = ""
    @Published private(set) var squadrons: [Squadron] = []
    @Published private(set) var events: [InstructorReviewEvent] = []
    @Published private(set) var suggestions: [InstructorNameSuggestion] = []
    @Published private(set) var errorMessage: String?
    @Published private(set) var didSubmit = false
    @Published private(set) var hasAttemptedSubmit = false
    private weak var repository: (any InstructorReviewRepository)?

    let minimumCharacterCount = 50

    var trimmedReviewText: String {
        reviewText.trimmingCharacters(in: .whitespacesAndNewlines)
    }

    var remainingCharacters: Int {
        max(0, minimumCharacterCount - trimmedReviewText.count)
    }

    var isValid: Bool {
        validationMessage == nil
    }

    var visibleSquadrons: [Squadron] {
        squadrons.filter(submissionMode.includes).submissionSorted()
    }

    var visibleEvents: [InstructorReviewEvent] {
        let lane = selectedSquadron?.reviewEventKind
        let filtered = events.filter { event in
            if let lane {
                return event.kind == lane
            }
            return submissionMode.includes(event)
        }
        return filtered.sorted { $0.displayName < $1.displayName }
    }

    var trimmedInstructorName: String {
        instructorName.trimmingCharacters(in: .whitespacesAndNewlines)
    }

    var trimmedEventName: String {
        eventName.trimmingCharacters(in: .whitespacesAndNewlines)
    }

    var eventSuggestions: [InstructorReviewEvent] {
        let query = trimmedEventName
        guard !query.isEmpty else { return [] }

        if let matchedCategory = InstructorReviewSeedData.category(forAlias: query) {
            return visibleEvents.filter { $0.syllabusCategory == matchedCategory }
        }

        let normalizedQuery = normalizedEventText(query)
        let prefixMatches = visibleEvents.filter { event in
            InstructorReviewSeedData.searchTerms(for: event).contains {
                normalizedEventText($0).hasPrefix(normalizedQuery)
            }
        }
        let containsMatches = visibleEvents.filter { event in
            !prefixMatches.contains(event) &&
            InstructorReviewSeedData.searchTerms(for: event).contains {
                normalizedEventText($0).contains(normalizedQuery)
            }
        }
        return prefixMatches + containsMatches
    }

    var eventHasExactSuggestionMatch: Bool {
        !trimmedEventName.isEmpty && visibleEvents.contains {
            $0.displayName.caseInsensitiveCompare(trimmedEventName) == .orderedSame
        }
    }

    var canChooseRatings: Bool {
        resolvedEvent() != nil
    }

    var validationMessage: String? {
        if trimmedInstructorName.isEmpty {
            return "Instructor name is required."
        }
        if selectedSquadron == nil {
            return "Choose a squadron."
        }
        if let selectedSquadron, !visibleSquadrons.contains(selectedSquadron) {
            return "Choose a squadron that matches the selected review type."
        }
        if trimmedEventName.isEmpty {
            return "Choose an event."
        }
        if let selectedEvent, !visibleEvents.contains(selectedEvent) {
            return "Choose an event that matches the selected review type."
        }
        if chillScore == nil {
            return "Select a chill factor rating."
        }
        if gradingScore == nil {
            return "Select a grading style rating."
        }
        if trimmedReviewText.count < minimumCharacterCount {
            return "Written review must be at least \(minimumCharacterCount) characters."
        }
        return nil
    }

    func load(using repository: InstructorReviewRepository) {
        self.repository = repository
        squadrons = repository.fetchSquadrons()
        events = repository.fetchEvents()
        refreshSuggestions(using: repository)
    }

    var chillOptions: [InstructorReviewRatingOption] {
        Array(InstructorRatingScale.validScores).reversed().map {
            InstructorReviewRatingOption(
                id: "chill-\($0)",
                score: $0,
                category: .chillFactor
            )
        }
    }

    var gradingOptions: [InstructorReviewRatingOption] {
        Array(InstructorRatingScale.validScores).reversed().map {
            InstructorReviewRatingOption(
                id: "grading-\($0)",
                score: $0,
                category: .gradingStyle
            )
        }
    }

    func refreshSuggestions(using repository: InstructorReviewRepository) {
        suggestions = repository.fetchInstructorSuggestions(matching: instructorName)
            .filter { submissionMode.includes($0.squadron) }
    }

    func applySuggestion(_ suggestion: InstructorNameSuggestion) {
        instructorName = suggestion.name
        if let preferredMode = suggestion.squadron.preferredSubmissionMode {
            submissionMode = preferredMode
        }
        selectedSquadron = suggestion.squadron
    }

    func applyEventSuggestion(_ event: InstructorReviewEvent) {
        eventName = event.displayName
        selectedEvent = event
    }

    func submit(using repository: InstructorReviewRepository) {
        hasAttemptedSubmit = true

        guard let selectedSquadron, let chillScore, let gradingScore, let event = resolvedEvent() else {
            errorMessage = validationMessage
            return
        }

        guard validationMessage == nil else {
            errorMessage = validationMessage
            return
        }

        do {
            try repository.submitReview(
                InstructorReviewSubmission(
                    instructorName: canonicalInstructorName(using: repository),
                    squadron: selectedSquadron,
                    event: event,
                    chillScore: chillScore,
                    gradingScore: gradingScore,
                    reviewText: trimmedReviewText
                )
            )
            didSubmit = true
            errorMessage = nil
        } catch {
            errorMessage = error.localizedDescription
        }
    }

    func acknowledgeSubmission() {
        didSubmit = false
    }

    private func handleSubmissionModeChange() {
        if let selectedSquadron, !submissionMode.includes(selectedSquadron) {
            self.selectedSquadron = nil
        }
        if let selectedEvent, !submissionMode.includes(selectedEvent) {
            self.selectedEvent = nil
            if selectedEvent.displayName.caseInsensitiveCompare(trimmedEventName) == .orderedSame {
                eventName = ""
            }
        }
        if let repository {
            refreshSuggestions(using: repository)
        } else {
            suggestions = []
        }
    }

    private func handleSquadronChange() {
        if let selectedEvent, !visibleEvents.contains(selectedEvent) {
            self.selectedEvent = nil
            if selectedEvent.displayName.caseInsensitiveCompare(trimmedEventName) == .orderedSame {
                eventName = ""
            }
        }
    }

    private func syncSelectedEventWithTypedEvent() {
        guard !trimmedEventName.isEmpty else {
            if selectedEvent != nil {
                selectedEvent = nil
            }
            return
        }

        let kind = selectedSquadron?.reviewEventKind ?? submissionMode.defaultEventKind
        if let canonicalEvent = InstructorReviewSeedData.canonicalEvent(named: trimmedEventName, kind: kind),
           let exactEvent = visibleEvents.first(where: {
               $0.kind == canonicalEvent.kind && $0.displayName.caseInsensitiveCompare(canonicalEvent.displayName) == .orderedSame
           }) {
            if selectedEvent != exactEvent {
                selectedEvent = exactEvent
            }
        } else if let selectedEvent, selectedEvent.displayName.caseInsensitiveCompare(trimmedEventName) != .orderedSame {
            self.selectedEvent = nil
        }
    }

    private func resolvedEvent() -> InstructorReviewEvent? {
        guard !trimmedEventName.isEmpty else { return nil }

        if let selectedEvent, visibleEvents.contains(selectedEvent) {
            return selectedEvent
        }

        let kind = selectedSquadron?.reviewEventKind ?? submissionMode.defaultEventKind
        if let canonicalEvent = InstructorReviewSeedData.canonicalEvent(named: trimmedEventName, kind: kind),
           let visibleCanonicalEvent = visibleEvents.first(where: {
               $0.kind == canonicalEvent.kind && $0.displayName.caseInsensitiveCompare(canonicalEvent.displayName) == .orderedSame
           }) {
            return visibleCanonicalEvent
        }

        return InstructorReviewSeedData.event(for: trimmedEventName, kind: kind)
    }

    private func canonicalInstructorName(using repository: InstructorReviewRepository) -> String {
        let typedName = trimmedInstructorName
        guard !typedName.isEmpty else { return typedName }

        let matchingSuggestions = repository.fetchInstructorSuggestions(matching: typedName)
            .filter { suggestion in
                if let selectedSquadron {
                    return suggestion.squadron == selectedSquadron
                }
                return true
            }

        if let exactMatch = matchingSuggestions.first(where: { namesAreCanonicalMatch(typedName, $0.name) }) {
            return exactMatch.name
        }

        return typedName
    }

    private func namesAreCanonicalMatch(_ lhs: String, _ rhs: String) -> Bool {
        normalizedNameTokens(lhs) == normalizedNameTokens(rhs)
    }

    private func normalizedNameTokens(_ value: String) -> [String] {
        value
            .folding(options: [.diacriticInsensitive, .caseInsensitive], locale: .current)
            .components(separatedBy: CharacterSet.alphanumerics.inverted)
            .filter { !$0.isEmpty }
            .map { $0.lowercased() }
            .sorted()
    }

    private func normalizedEventText(_ value: String) -> String {
        value
            .folding(options: [.diacriticInsensitive, .caseInsensitive], locale: .current)
            .replacingOccurrences(of: " ", with: "")
            .lowercased()
    }
}

struct InstructorReviewRatingOption: Identifiable, Hashable {
    let id: String
    let score: Int
    let category: InstructorRatingCategory

    var title: String {
        InstructorRatingScale.label(for: score, category: category)
    }

    var subtitle: String {
        "Score \(InstructorRatingScale.format(average: InstructorRatingScale.tenScaleValue(for: Double(score)))) / 10"
    }

    var accent: Color {
        InstructorRatingScale.color(for: score)
    }
}

@MainActor
final class ModerationQueueViewModel: ObservableObject {
    @Published private(set) var pendingReviews: [InstructorReview] = []
    @Published private(set) var openReports: [InstructorGougeReport] = []
    @Published private(set) var processingIDs: Set<String> = []
    @Published private(set) var errorMessage: String?

    func load(using repository: InstructorReviewRepository) {
        pendingReviews = repository.fetchPendingReviews()
        openReports = repository.fetchOpenReports()
    }

    func approve(reviewID: String, using repository: InstructorReviewRepository) {
        process(reviewID: reviewID, using: repository) {
            try await repository.approveReview(id: reviewID)
        }
    }

    func reject(reviewID: String, using repository: InstructorReviewRepository) {
        process(reviewID: reviewID, using: repository) {
            try await repository.rejectReview(id: reviewID)
        }
    }

    func dismissReport(reportID: String, using repository: InstructorReviewRepository) {
        process(reviewID: reportID, using: repository) {
            try await repository.dismissReport(id: reportID)
        }
    }

    private func process(
        reviewID: String,
        using repository: InstructorReviewRepository,
        action: @escaping () async throws -> Void
    ) {
        processingIDs.insert(reviewID)

        Task { @MainActor in
            defer { processingIDs.remove(reviewID) }

            do {
                try await action()
                pendingReviews = repository.fetchPendingReviews()
                openReports = repository.fetchOpenReports()
                errorMessage = nil
            } catch {
                errorMessage = error.localizedDescription
            }
        }
    }
}
