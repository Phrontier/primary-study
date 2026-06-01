import Foundation

enum InstructorReviewRepositoryError: LocalizedError {
    case reviewNotFound
    case unavailable
    case unauthorized
    case remoteNotConfigured
    case offline

    var errorDescription: String? {
        switch self {
        case .reviewNotFound:
            return "The selected review could not be found."
        case .unavailable:
            return "Instructor reviews are still loading."
        case .unauthorized:
            return "Moderator sign-in is required for that action."
        case .remoteNotConfigured:
            return "Instructor review sync is not configured yet."
        case .offline:
            return "This action needs a network connection."
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
    func fetchOpenReports() -> [InstructorGougeReport]
    func fetchOpenCommunitySubmissions() -> [CommunitySubmissionModerationItem]
    func fetchInstructorSuggestions(matching query: String) -> [InstructorNameSuggestion]
    func fetchSquadrons() -> [Squadron]
    func fetchEvents() -> [InstructorReviewEvent]
    func submitReview(_ submission: InstructorReviewSubmission) throws
    func submitReport(_ submission: InstructorGougeReportSubmission) throws
    func dismissReport(id: String) async throws
    func resolveCommunitySubmission(id: String) async throws
    func dismissCommunitySubmission(id: String) async throws
    func approveReview(id: String) async throws
    func rejectReview(id: String) async throws
}
