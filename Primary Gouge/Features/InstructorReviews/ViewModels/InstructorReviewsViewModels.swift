import Combine
import Foundation

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
    @Published var selectedSquadron: Squadron?
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

    var validationMessage: String? {
        if instructorName.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty {
            return "Instructor name is required."
        }
        if selectedSquadron == nil {
            return "Choose a squadron."
        }
        if selectedEvent == nil {
            return "Choose an event."
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
    }

    func applySuggestion(_ suggestion: InstructorNameSuggestion) {
        instructorName = suggestion.name
        selectedSquadron = suggestion.squadron
    }

    func submit(using repository: InstructorReviewRepository) {
        hasAttemptedSubmit = true

        guard let selectedSquadron, let selectedEvent, let chillScore, let gradingScore else {
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
                    instructorName: instructorName,
                    squadron: selectedSquadron,
                    event: selectedEvent,
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
}

struct InstructorReviewRatingOption: Identifiable, Hashable {
    let id: String
    let score: Int
    let category: InstructorRatingCategory

    var title: String {
        InstructorRatingScale.label(for: score, category: category)
    }

    var subtitle: String {
        "Score \(score) / 7"
    }
}

@MainActor
final class ModerationQueueViewModel: ObservableObject {
    @Published private(set) var pendingReviews: [InstructorReview] = []
    @Published private(set) var processingIDs: Set<String> = []
    @Published private(set) var errorMessage: String?

    func load(using repository: InstructorReviewRepository) {
        pendingReviews = repository.fetchPendingReviews()
    }

    func approve(reviewID: String, using repository: InstructorReviewRepository) {
        process(reviewID: reviewID, using: repository) {
            try repository.approveReview(id: reviewID)
        }
    }

    func reject(reviewID: String, using repository: InstructorReviewRepository) {
        process(reviewID: reviewID, using: repository) {
            try repository.rejectReview(id: reviewID)
        }
    }

    private func process(
        reviewID: String,
        using repository: InstructorReviewRepository,
        action: () throws -> Void
    ) {
        processingIDs.insert(reviewID)
        defer { processingIDs.remove(reviewID) }

        do {
            try action()
            pendingReviews = repository.fetchPendingReviews()
            errorMessage = nil
        } catch {
            errorMessage = error.localizedDescription
        }
    }
}
