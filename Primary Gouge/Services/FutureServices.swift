import Foundation

protocol DailyTaskService {
    func taskSummary() async -> String
}

protocol InstructorReviewService {
    func moderationStatus() async -> String
}

struct PlaceholderDailyTaskService: DailyTaskService {
    func taskSummary() async -> String {
        "Future daily task engine."
    }
}

struct PlaceholderInstructorReviewService: InstructorReviewService {
    func moderationStatus() async -> String {
        "Future instructor review moderation."
    }
}
