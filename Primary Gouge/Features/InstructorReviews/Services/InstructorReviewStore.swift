import Foundation
import Combine

@MainActor
final class InstructorReviewStore: ObservableObject, InstructorReviewRepository {
    @Published private(set) var revision = 0

    private var repository: InstructorReviewRepository?

    func configure() {
        guard repository == nil else { return }

        let repository = SwiftDataInstructorReviewRepository()
        try? repository.seedIfNeeded()
        self.repository = repository
        revision &+= 1
    }

    func seedIfNeeded() throws {
        try currentRepository.seedIfNeeded()
        revision &+= 1
    }

    func fetchInstructorSummaries(searchText: String) -> [Instructor] {
        currentRepository.fetchInstructorSummaries(searchText: searchText)
    }

    func fetchInstructor(id: String) -> Instructor? {
        currentRepository.fetchInstructor(id: id)
    }

    func fetchPublishedReviews(for instructorID: String) -> [InstructorReview] {
        currentRepository.fetchPublishedReviews(for: instructorID)
    }

    func fetchPendingReviews() -> [InstructorReview] {
        currentRepository.fetchPendingReviews()
    }

    func fetchOpenReports() -> [InstructorGougeReport] {
        currentRepository.fetchOpenReports()
    }

    func fetchInstructorSuggestions(matching query: String) -> [InstructorNameSuggestion] {
        currentRepository.fetchInstructorSuggestions(matching: query)
    }

    func fetchSquadrons() -> [Squadron] {
        currentRepository.fetchSquadrons()
    }

    func fetchEvents() -> [InstructorReviewEvent] {
        currentRepository.fetchEvents()
    }

    func submitReview(_ submission: InstructorReviewSubmission) throws {
        try currentRepository.submitReview(submission)
        revision &+= 1
    }

    func submitReport(_ submission: InstructorGougeReportSubmission) throws {
        try currentRepository.submitReport(submission)
        revision &+= 1
    }

    func dismissReport(id: String) throws {
        try currentRepository.dismissReport(id: id)
        revision &+= 1
    }

    func approveReview(id: String) throws {
        try currentRepository.approveReview(id: id)
        revision &+= 1
    }

    func rejectReview(id: String) throws {
        try currentRepository.rejectReview(id: id)
        revision &+= 1
    }

    private var currentRepository: InstructorReviewRepository {
        guard let repository else {
            return UnavailableInstructorReviewRepository()
        }
        return repository
    }
}

@MainActor
private final class UnavailableInstructorReviewRepository: InstructorReviewRepository {
    func seedIfNeeded() throws {
        throw InstructorReviewRepositoryError.unavailable
    }

    func fetchInstructorSummaries(searchText: String) -> [Instructor] {
        []
    }

    func fetchInstructor(id: String) -> Instructor? {
        nil
    }

    func fetchPublishedReviews(for instructorID: String) -> [InstructorReview] {
        []
    }

    func fetchPendingReviews() -> [InstructorReview] {
        []
    }

    func fetchOpenReports() -> [InstructorGougeReport] {
        []
    }

    func fetchInstructorSuggestions(matching query: String) -> [InstructorNameSuggestion] {
        []
    }

    func fetchSquadrons() -> [Squadron] {
        []
    }

    func fetchEvents() -> [InstructorReviewEvent] {
        []
    }

    func submitReview(_ submission: InstructorReviewSubmission) throws {
        throw InstructorReviewRepositoryError.unavailable
    }

    func submitReport(_ submission: InstructorGougeReportSubmission) throws {
        throw InstructorReviewRepositoryError.unavailable
    }

    func dismissReport(id: String) throws {
        throw InstructorReviewRepositoryError.unavailable
    }

    func approveReview(id: String) throws {
        throw InstructorReviewRepositoryError.unavailable
    }

    func rejectReview(id: String) throws {
        throw InstructorReviewRepositoryError.unavailable
    }
}
