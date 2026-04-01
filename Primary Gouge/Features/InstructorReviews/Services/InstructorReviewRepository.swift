import Foundation

enum InstructorReviewRepositoryError: LocalizedError {
    case reviewNotFound
    case unavailable

    var errorDescription: String? {
        switch self {
        case .reviewNotFound:
            return "The selected review could not be found."
        case .unavailable:
            return "Instructor reviews are still loading."
        }
    }
}

@MainActor
protocol InstructorReviewRepository: AnyObject {
    func seedIfNeeded() throws
    func fetchInstructorSummaries(searchText: String) -> [Instructor]
    func fetchInstructor(id: String) -> Instructor?
    func fetchPublishedReviews(for instructorID: String) -> [InstructorReview]
    func fetchPendingReviews() -> [InstructorReview]
    func fetchInstructorSuggestions(matching query: String) -> [InstructorNameSuggestion]
    func fetchSquadrons() -> [Squadron]
    func fetchEvents() -> [InstructorReviewEvent]
    func submitReview(_ submission: InstructorReviewSubmission) throws
    func approveReview(id: String) throws
    func rejectReview(id: String) throws
}
