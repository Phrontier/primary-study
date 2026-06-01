import Foundation
import SwiftUI

enum CommunitySubmissionCategory: String, Codable, CaseIterable, Hashable, Identifiable {
    case feedback = "feedback"
    case featureRequest = "feature_request"
    case support = "support"
    case incorrectGouge = "incorrect_gouge"

    var id: String { rawValue }

    var title: String {
        switch self {
        case .feedback:
            return "Feedback"
        case .featureRequest:
            return "Request a Feature"
        case .support:
            return "Support"
        case .incorrectGouge:
            return "Report Incorrect Gouge"
        }
    }

    var iconName: String {
        switch self {
        case .feedback:
            return "bubble.left.and.text.bubble.right.fill"
        case .featureRequest:
            return "lightbulb.fill"
        case .support:
            return "lifepreserver.fill"
        case .incorrectGouge:
            return "exclamationmark.bubble.fill"
        }
    }

    var accentColor: Color {
        switch self {
        case .incorrectGouge:
            return AppTheme.danger
        default:
            return MoreSectionColor.support
        }
    }

    var eyebrow: String {
        switch self {
        case .feedback:
            return "Community"
        case .featureRequest:
            return "Product"
        case .support:
            return "Support"
        case .incorrectGouge:
            return "Accuracy"
        }
    }

    var formTitle: String {
        switch self {
        case .feedback:
            return "Share feedback"
        case .featureRequest:
            return "Request a feature"
        case .support:
            return "Get support"
        case .incorrectGouge:
            return "Report incorrect gouge"
        }
    }

    var formSubtitle: String {
        switch self {
        case .feedback:
            return "Tell us what is helping and where the app can feel sharper."
        case .featureRequest:
            return "Describe the workflow gap and how the feature would help you study faster."
        case .support:
            return "Send a bug, issue, or help request and we will review it through the shared support inbox."
        case .incorrectGouge:
            return "Flag something that looks outdated, incorrect, incomplete, or misleading."
        }
    }

    var summaryPrompt: String {
        switch self {
        case .feedback:
            return "Quick headline"
        case .featureRequest:
            return "Feature request headline"
        case .support:
            return "Issue headline"
        case .incorrectGouge:
            return "What looks wrong?"
        }
    }

    var messagePrompt: String {
        switch self {
        case .feedback:
            return "What is working well, and what would make it better?"
        case .featureRequest:
            return "Describe the missing tool or flow, when you need it, and what a good result looks like."
        case .support:
            return "Tell us what happened, what you expected, and anything that would help reproduce it."
        case .incorrectGouge:
            return "Describe the issue and include the correction or the part that needs a closer review."
        }
    }

    var submitButtonTitle: String {
        switch self {
        case .feedback:
            return "Send Feedback"
        case .featureRequest:
            return "Send Request"
        case .support:
            return "Send Support Request"
        case .incorrectGouge:
            return "Send Report"
        }
    }

    var emptyStateTitle: String {
        switch self {
        case .feedback:
            return "No feedback sent yet"
        case .featureRequest:
            return "No feature requests yet"
        case .support:
            return "No support requests yet"
        case .incorrectGouge:
            return "No gouge reports yet"
        }
    }

    var emptyStateMessage: String {
        switch self {
        case .feedback:
            return "Your feedback history will show up here after you send something."
        case .featureRequest:
            return "Feature requests you send from this screen will show up here with their latest status."
        case .support:
            return "Support requests stay visible here so you can confirm they were queued or delivered."
        case .incorrectGouge:
            return "Incorrect gouge reports you send will appear here with their moderation status."
        }
    }

    var successMessage: String {
        switch self {
        case .feedback:
            return "Feedback saved and queued for review."
        case .featureRequest:
            return "Feature request saved and queued for review."
        case .support:
            return "Support request saved and queued for review."
        case .incorrectGouge:
            return "Gouge report saved and queued for review."
        }
    }
}

enum CommunitySubmissionTargetKind: String, Codable, CaseIterable, Hashable, Identifiable {
    case brief
    case flashcardSet
    case event
    case instructorReview
    case generalLibrary
    case other

    var id: String { rawValue }

    var title: String {
        switch self {
        case .brief:
            return "Brief or reference"
        case .flashcardSet:
            return "Flashcard set"
        case .event:
            return "Event"
        case .instructorReview:
            return "Instructor review"
        case .generalLibrary:
            return "General Library"
        case .other:
            return "Other"
        }
    }
}

enum CommunitySubmissionStatus: String, Codable, CaseIterable, Hashable {
    case open
    case resolved
    case dismissed

    var title: String {
        switch self {
        case .open:
            return "Open"
        case .resolved:
            return "Resolved"
        case .dismissed:
            return "Dismissed"
        }
    }

    var color: Color {
        switch self {
        case .open:
            return AppTheme.warning
        case .resolved:
            return AppTheme.success
        case .dismissed:
            return AppTheme.textMuted
        }
    }
}

enum CommunitySubmissionSyncState: String, Codable, CaseIterable, Hashable {
    case queuedUpload
    case uploadedOpen
    case synced
    case failed

    var title: String {
        switch self {
        case .queuedUpload:
            return "Queued"
        case .uploadedOpen:
            return "Sent"
        case .synced:
            return "Updated"
        case .failed:
            return "Retrying"
        }
    }

    var color: Color {
        switch self {
        case .queuedUpload:
            return AppTheme.warning
        case .uploadedOpen:
            return AppTheme.accent
        case .synced:
            return AppTheme.success
        case .failed:
            return AppTheme.danger
        }
    }
}

struct CommunitySubmissionDraft: Codable, Hashable {
    var summary = ""
    var message = ""
    var contactEmail = ""
    var targetKind: CommunitySubmissionTargetKind?
    var targetID = ""
    var targetTitle = ""
    var targetContext = ""

    var trimmedSummary: String {
        summary.trimmingCharacters(in: .whitespacesAndNewlines)
    }

    var trimmedMessage: String {
        message.trimmingCharacters(in: .whitespacesAndNewlines)
    }

    var trimmedContactEmail: String {
        contactEmail.trimmingCharacters(in: .whitespacesAndNewlines)
    }

    var normalizedTargetID: String? {
        let value = targetID.trimmingCharacters(in: .whitespacesAndNewlines)
        return value.isEmpty ? nil : value
    }

    var normalizedTargetTitle: String? {
        let value = targetTitle.trimmingCharacters(in: .whitespacesAndNewlines)
        return value.isEmpty ? nil : value
    }

    var normalizedTargetContext: String? {
        let value = targetContext.trimmingCharacters(in: .whitespacesAndNewlines)
        return value.isEmpty ? nil : value
    }
}

struct CommunitySubmissionRecord: Identifiable, Codable, Hashable {
    let id: String
    var category: CommunitySubmissionCategory
    var summary: String
    var message: String
    var contactEmail: String?
    var targetKind: CommunitySubmissionTargetKind?
    var targetID: String?
    var targetTitle: String?
    var targetContext: String?
    var appVersion: String
    var buildNumber: String?
    var platform: String
    var submittedAt: Date
    var status: CommunitySubmissionStatus
    var syncState: CommunitySubmissionSyncState
    var lastModifiedAt: Date
    var lastSyncedAt: Date?
    var submitterClientID: String?
    var lastErrorMessage: String?

    init(
        id: String = UUID().uuidString.lowercased(),
        category: CommunitySubmissionCategory,
        summary: String,
        message: String,
        contactEmail: String?,
        targetKind: CommunitySubmissionTargetKind?,
        targetID: String?,
        targetTitle: String?,
        targetContext: String?,
        appVersion: String,
        buildNumber: String?,
        platform: String = "iOS",
        submittedAt: Date = .now,
        status: CommunitySubmissionStatus = .open,
        syncState: CommunitySubmissionSyncState = .queuedUpload,
        lastModifiedAt: Date = .now,
        lastSyncedAt: Date? = nil,
        submitterClientID: String?,
        lastErrorMessage: String? = nil
    ) {
        self.id = id
        self.category = category
        self.summary = summary
        self.message = message
        self.contactEmail = contactEmail
        self.targetKind = targetKind
        self.targetID = targetID
        self.targetTitle = targetTitle
        self.targetContext = targetContext
        self.appVersion = appVersion
        self.buildNumber = buildNumber
        self.platform = platform
        self.submittedAt = submittedAt
        self.status = status
        self.syncState = syncState
        self.lastModifiedAt = lastModifiedAt
        self.lastSyncedAt = lastSyncedAt
        self.submitterClientID = submitterClientID
        self.lastErrorMessage = lastErrorMessage
    }

    var targetSummary: String? {
        var parts: [String] = []
        if let targetKind {
            parts.append(targetKind.title)
        }
        if let targetTitle, !targetTitle.isEmpty {
            parts.append(targetTitle)
        }
        if let targetContext, !targetContext.isEmpty {
            parts.append(targetContext)
        }
        return parts.isEmpty ? nil : parts.joined(separator: " • ")
    }

    var statusDetail: String {
        switch syncState {
        case .queuedUpload:
            return "Saved locally and waiting to upload."
        case .uploadedOpen:
            return "Sent to the Cloudflare inbox."
        case .synced:
            return status == .resolved ? "Reviewed and resolved." : "Reviewed and closed."
        case .failed:
            return "Upload failed. The app will retry automatically."
        }
    }
}

struct CommunitySubmissionStatusSnapshot: Hashable {
    let id: String
    let status: CommunitySubmissionStatus
    let updatedAt: Date
}

struct CommunitySubmissionModerationItem: Identifiable, Codable, Hashable {
    let id: String
    let category: CommunitySubmissionCategory
    let summary: String
    let message: String
    let contactEmail: String?
    let targetKind: CommunitySubmissionTargetKind?
    let targetID: String?
    let targetTitle: String?
    let targetContext: String?
    let appVersion: String
    let buildNumber: String?
    let platform: String
    let submittedAt: Date
    let status: CommunitySubmissionStatus
    let submitterClientID: String?
    let updatedAt: Date

    var targetSummary: String? {
        var parts: [String] = []
        if let targetKind {
            parts.append(targetKind.title)
        }
        if let targetTitle, !targetTitle.isEmpty {
            parts.append(targetTitle)
        }
        if let targetContext, !targetContext.isEmpty {
            parts.append(targetContext)
        }
        return parts.isEmpty ? nil : parts.joined(separator: " • ")
    }
}

struct CommunitySubmissionSyncStatus: Hashable {
    var phase: InstructorReviewSyncPhase
    var lastSyncedAt: Date?
    var errorMessage: String?
    var backendSource: InstructorReviewBackendSource = .unavailable
    var configurationDetail: String?

    static let idle = CommunitySubmissionSyncStatus(
        phase: .idle,
        lastSyncedAt: nil,
        errorMessage: nil,
        backendSource: .unavailable,
        configurationDetail: nil
    )
}
