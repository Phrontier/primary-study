import Foundation
import SwiftUI

enum InstructorReviewEventKind: String, Codable, CaseIterable, Hashable {
    case sim
    case flight

    var displayName: String {
        switch self {
        case .sim:
            return "Sim"
        case .flight:
            return "Flight"
        }
    }

    var pluralDisplayName: String {
        switch self {
        case .sim:
            return "Sims"
        case .flight:
            return "Flights"
        }
    }

    var domainColor: Color {
        switch self {
        case .sim:
            return AppTheme.domainColor(.sims)
        case .flight:
            return AppTheme.domainColor(.flights)
        }
    }
}

enum InstructorSubmissionMode: String, CaseIterable, Hashable, Identifiable {
    case sims
    case flights
    case both

    var id: String { rawValue }

    var title: String {
        switch self {
        case .sims:
            return "Sims"
        case .flights:
            return "Flights"
        case .both:
            return "Both"
        }
    }

    var color: Color {
        switch self {
        case .sims:
            return AppTheme.domainColor(.sims)
        case .flights:
            return AppTheme.domainColor(.flights)
        case .both:
            return AppTheme.domainColor(.instructors)
        }
    }

    var defaultEventKind: InstructorReviewEventKind {
        switch self {
        case .sims:
            return .sim
        case .flights, .both:
            return .flight
        }
    }

    func includes(_ squadron: Squadron) -> Bool {
        switch self {
        case .both:
            return true
        case .sims:
            return squadron.reviewEventKind == .sim
        case .flights:
            return squadron.reviewEventKind == .flight
        }
    }

    func includes(_ event: InstructorReviewEvent) -> Bool {
        switch self {
        case .both:
            return true
        case .sims:
            return event.kind == .sim
        case .flights:
            return event.kind == .flight
        }
    }
}

enum InstructorCapabilityFilter: String, CaseIterable, Hashable, Identifiable {
    case all
    case sims
    case flights

    var id: String { rawValue }

    var title: String {
        switch self {
        case .all:
            return "All"
        case .sims:
            return "Sims"
        case .flights:
            return "Flights"
        }
    }

    var color: Color {
        switch self {
        case .all:
            return AppTheme.domainColor(.instructors)
        case .sims:
            return AppTheme.domainColor(.sims)
        case .flights:
            return AppTheme.domainColor(.flights)
        }
    }

    func includes(_ instructor: Instructor) -> Bool {
        switch self {
        case .all:
            return true
        case .sims:
            return instructor.capabilities.contains(.sim)
        case .flights:
            return instructor.capabilities.contains(.flight)
        }
    }
}

enum InstructorReviewSortOption: String, CaseIterable, Hashable, Identifiable {
    case mostRecent
    case oldest
    case best
    case worst

    var id: String { rawValue }

    var title: String {
        switch self {
        case .mostRecent:
            return "Most Recent"
        case .oldest:
            return "Oldest"
        case .best:
            return "Best"
        case .worst:
            return "Worst"
        }
    }

    func sorted(_ reviews: [InstructorReview]) -> [InstructorReview] {
        reviews.sorted { lhs, rhs in
            switch self {
            case .mostRecent:
                return lhs.submittedAt > rhs.submittedAt
            case .oldest:
                return lhs.submittedAt < rhs.submittedAt
            case .best:
                if lhs.overallScore == rhs.overallScore {
                    return lhs.submittedAt > rhs.submittedAt
                }
                return lhs.overallScore > rhs.overallScore
            case .worst:
                if lhs.overallScore == rhs.overallScore {
                    return lhs.submittedAt > rhs.submittedAt
                }
                return lhs.overallScore < rhs.overallScore
            }
        }
    }
}

enum ReviewStatus: String, Codable, CaseIterable, Hashable {
    case pending
    case approved
    case rejected

    var displayName: String {
        switch self {
        case .pending:
            return "Pending"
        case .approved:
            return "Approved"
        case .rejected:
            return "Rejected"
        }
    }

    var statusColor: Color {
        switch self {
        case .pending:
            return AppTheme.statusColor(.pending)
        case .approved:
            return AppTheme.statusColor(.approved)
        case .rejected:
            return AppTheme.statusColor(.rejected)
        }
    }
}

enum InstructorReviewActionType: String, Codable, CaseIterable, Hashable {
    case create
    case edit
    case delete

    var title: String {
        switch self {
        case .create:
            return "New Review"
        case .edit:
            return "Edit Request"
        case .delete:
            return "Delete Request"
        }
    }
}

enum InstructorReviewVisibilityState: String, Codable, CaseIterable, Hashable {
    case `public`
    case hiddenPendingDelete = "hidden_pending_delete"
    case deleted
}

enum OwnedInstructorReviewStatus: String, Codable, CaseIterable, Hashable {
    case pendingCreate = "pending_create"
    case approved
    case pendingEdit = "pending_edit"
    case pendingDelete = "pending_delete"
    case rejectedCreate = "rejected_create"
    case rejectedEdit = "rejected_edit"
    case rejectedDelete = "rejected_delete"
    case removed

    var title: String {
        switch self {
        case .pendingCreate:
            return "Pending"
        case .approved:
            return "Live"
        case .pendingEdit:
            return "Edit Pending"
        case .pendingDelete:
            return "Delete Pending"
        case .rejectedCreate:
            return "Not Approved"
        case .rejectedEdit:
            return "Edit Rejected"
        case .rejectedDelete:
            return "Delete Rejected"
        case .removed:
            return "Removed"
        }
    }

    var color: Color {
        switch self {
        case .approved:
            return AppTheme.success
        case .removed:
            return AppTheme.textMuted
        case .rejectedCreate, .rejectedEdit, .rejectedDelete:
            return AppTheme.danger
        case .pendingCreate, .pendingEdit, .pendingDelete:
            return AppTheme.warning
        }
    }

    var allowsEdit: Bool {
        switch self {
        case .approved, .rejectedCreate, .rejectedEdit, .rejectedDelete:
            return true
        case .pendingCreate, .pendingEdit, .pendingDelete, .removed:
            return false
        }
    }

    var allowsDelete: Bool {
        switch self {
        case .approved, .rejectedCreate, .rejectedEdit, .rejectedDelete:
            return true
        case .pendingCreate, .pendingEdit, .pendingDelete, .removed:
            return false
        }
    }

    var helperText: String {
        switch self {
        case .pendingCreate:
            return "Waiting for moderation before it goes live."
        case .approved:
            return "Visible to students now."
        case .pendingEdit:
            return "Your live review stays up until the edit is approved."
        case .pendingDelete:
            return "Removed from the public list while deletion is reviewed."
        case .rejectedCreate:
            return "This review was not approved."
        case .rejectedEdit:
            return "Your last edit was not approved."
        case .rejectedDelete:
            return "Your delete request was not approved."
        case .removed:
            return "This review has been removed from the public list."
        }
    }
}

enum InstructorReviewOrigin: String, Codable, CaseIterable, Hashable {
    case seed
    case localSubmission
    case remote
}

enum InstructorReviewSyncState: String, Codable, CaseIterable, Hashable {
    case localOnly
    case queuedUpload
    case uploadedPending
    case synced
    case failed
}

enum InstructorGougeReportStatus: String, Codable, CaseIterable, Hashable {
    case open
    case dismissed
    case resolved
}

enum InstructorReviewSyncPhase: Hashable {
    case idle
    case syncing
    case offline
    case failed
}

enum InstructorReviewBackendSource: Hashable {
    case bundled
    case productionDefault
    case userDefaultsOverride
    case unavailable
}

struct InstructorReviewSyncStatus: Hashable {
    var phase: InstructorReviewSyncPhase
    var lastSyncedAt: Date?
    var errorMessage: String?
    var backendSource: InstructorReviewBackendSource = .unavailable
    var configurationDetail: String?

    static let idle = InstructorReviewSyncStatus(
        phase: .idle,
        lastSyncedAt: nil,
        errorMessage: nil,
        backendSource: .unavailable,
        configurationDetail: nil
    )
}

struct ModeratorSession: Codable, Hashable {
    let email: String
    let accessToken: String
    let refreshToken: String
    let expiresAt: Date

    var isExpired: Bool {
        expiresAt <= Date()
    }
}

enum ModeratorSessionState: Hashable {
    case signedOut
    case signingIn
    case signedIn(email: String)
    case failed(message: String)
}

enum InstructorGougeReportTargetKind: String, Codable, CaseIterable, Hashable {
    case instructor
    case review

    var displayName: String {
        switch self {
        case .instructor:
            return "Instructor Info"
        case .review:
            return "Review"
        }
    }
}

enum InstructorInfoReportReason: String, CaseIterable, Codable, Hashable, Identifiable {
    case incorrectName
    case incorrectSquadron
    case duplicateInstructor
    case mixedInstructorInfo
    case other

    var id: String { rawValue }

    var title: String {
        switch self {
        case .incorrectName:
            return "Incorrect Name"
        case .incorrectSquadron:
            return "Incorrect Squadron"
        case .duplicateInstructor:
            return "Duplicate Instructor"
        case .mixedInstructorInfo:
            return "Mixed Instructor Info"
        case .other:
            return "Other"
        }
    }
}

struct Squadron: Identifiable, Hashable, Codable {
    let id: String
    let displayName: String

    var trainingWingID: TrainingWingID? {
        TrainingWingID(rawValue: id)
    }

    var parentTrainingWingID: TrainingWingID? {
        TrainingWingID.parentWingID(forSquadronID: id)
    }

    var isTrainingWing: Bool {
        trainingWingID != nil
    }

    var isTrainingSquadron: Bool {
        parentTrainingWingID != nil
    }

    var reviewEventKind: InstructorReviewEventKind? {
        if isTrainingWing {
            return .sim
        }
        if isTrainingSquadron {
            return .flight
        }
        return nil
    }

    var preferredSubmissionMode: InstructorSubmissionMode? {
        switch reviewEventKind {
        case .sim:
            return .sims
        case .flight:
            return .flights
        case nil:
            return nil
        }
    }

    private var numericPortion: Int {
        Int(id.split(separator: "-").last ?? "") ?? .max
    }

    var submissionSortRank: (Int, Int, String) {
        let laneRank: Int
        switch reviewEventKind {
        case .flight:
            laneRank = 0
        case .sim:
            laneRank = 1
        case nil:
            laneRank = 2
        }

        return (laneRank, numericPortion, displayName)
    }

    var profileSelectionSortRank: (Int, Int, String) {
        let wingRank: Int
        switch parentTrainingWingID {
        case .tw4:
            wingRank = 0
        case .tw5:
            wingRank = 1
        case nil:
            wingRank = 2
        }

        return (wingRank, numericPortion, displayName)
    }
}

enum TrainingWingID: String, CaseIterable, Codable, Hashable, Identifiable {
    case tw4 = "tw-4"
    case tw5 = "tw-5"

    var id: String { rawValue }

    var displayName: String {
        switch self {
        case .tw4:
            return "TW-4"
        case .tw5:
            return "TW-5"
        }
    }

    static func parentWingID(forSquadronID squadronID: String) -> TrainingWingID? {
        switch squadronID {
        case "vt-27", "vt-28":
            return .tw4
        case "vt-2", "vt-3", "vt-6":
            return .tw5
        default:
            return nil
        }
    }
}

extension Sequence where Element == Squadron {
    func submissionSorted() -> [Squadron] {
        sorted { lhs, rhs in
            lhs.submissionSortRank < rhs.submissionSortRank
        }
    }

    func profileSelectableSorted() -> [Squadron] {
        filter(\.isTrainingSquadron)
            .sorted { lhs, rhs in
                lhs.profileSelectionSortRank < rhs.profileSelectionSortRank
            }
    }
}

struct InstructorReviewEvent: Identifiable, Hashable, Codable {
    let id: String
    let displayName: String
    let kind: InstructorReviewEventKind
    let syllabusCategory: SyllabusEventCategory?

    init(id: String, displayName: String, kind: InstructorReviewEventKind, syllabusCategory: SyllabusEventCategory? = nil) {
        self.id = id
        self.displayName = displayName
        self.kind = kind
        self.syllabusCategory = syllabusCategory
    }
}

struct Instructor: Identifiable, Hashable {
    let id: String
    let name: String
    let squadron: Squadron
    let capabilities: Set<InstructorReviewEventKind>
    let publishedReviewCount: Int
    let averageChillScore: Double
    let averageGradingScore: Double

    static func makeID(name: String, squadronID: String) -> String {
        let normalizedName = name
            .trimmingCharacters(in: .whitespacesAndNewlines)
            .folding(options: [.diacriticInsensitive, .caseInsensitive], locale: .current)
            .lowercased()
        return "\(normalizedName)|\(squadronID)"
    }

    var reviewCountLabel: String {
        publishedReviewCount == 1 ? "review" : "reviews"
    }

    var reviewCountText: String {
        "\(publishedReviewCount) \(reviewCountLabel)"
    }

    var publishedReviewCountText: String {
        "\(publishedReviewCount) published \(reviewCountLabel)"
    }
}

struct InstructorReview: Identifiable, Hashable {
    let id: String
    let instructorID: String
    let instructorName: String
    let squadron: Squadron
    let eventName: String?
    let eventKind: InstructorReviewEventKind
    let chillScore: Int
    let gradingScore: Int
    let reviewText: String
    let submittedAt: Date
    let status: ReviewStatus
    let origin: InstructorReviewOrigin
    let syncState: InstructorReviewSyncState
    let submitterClientID: String?
    let actionType: InstructorReviewActionType
    let targetReviewID: String?

    var overallScore: Double {
        Double(chillScore + gradingScore) / 2.0
    }

    var hasEventName: Bool {
        eventName?.isEmpty == false
    }
}

struct OwnedInstructorReview: Identifiable, Hashable {
    let id: String
    let publicReviewID: String?
    let submissionID: String?
    let instructorName: String
    let squadron: Squadron
    let eventName: String?
    let eventKind: InstructorReviewEventKind
    let chillScore: Int
    let gradingScore: Int
    let reviewText: String
    let submittedAt: Date
    let updatedAt: Date
    let status: OwnedInstructorReviewStatus

    var title: String {
        instructorName
    }
}

struct InstructorNameSuggestion: Identifiable, Hashable {
    let id: String
    let name: String
    let squadron: Squadron
}

struct InstructorReviewSubmission: Hashable {
    let instructorName: String
    let squadron: Squadron
    let event: InstructorReviewEvent
    let chillScore: Int
    let gradingScore: Int
    let reviewText: String
}

struct InstructorGougeReportSubmission: Hashable {
    let targetKind: InstructorGougeReportTargetKind
    let instructorID: String
    let reviewID: String?
    let instructorName: String
    let squadron: Squadron
    let eventName: String?
    let eventKind: InstructorReviewEventKind?
    let reviewText: String?
    let reasonTitle: String
    let note: String?
}

struct InstructorGougeReport: Identifiable, Hashable {
    let id: String
    let targetKind: InstructorGougeReportTargetKind
    let instructorID: String
    let reviewID: String?
    let instructorName: String
    let squadron: Squadron
    let eventName: String?
    let eventKind: InstructorReviewEventKind?
    let reviewText: String?
    let reasonTitle: String
    let note: String?
    let submittedAt: Date
    let status: InstructorGougeReportStatus
    let origin: InstructorReviewOrigin
    let syncState: InstructorReviewSyncState
    let submitterClientID: String?

    var isReviewTarget: Bool {
        targetKind == .review
    }
}

struct InstructorGougeReportRecord: Identifiable, Codable, Hashable {
    let id: String
    var remoteID: String?
    var targetKind: InstructorGougeReportTargetKind
    var instructorID: String
    var reviewID: String?
    var instructorName: String
    var squadronID: String
    var eventName: String?
    var eventKind: InstructorReviewEventKind?
    var reviewText: String?
    var reasonTitle: String
    var note: String?
    var submittedAt: Date
    var status: InstructorGougeReportStatus
    var origin: InstructorReviewOrigin
    var syncState: InstructorReviewSyncState
    var lastModifiedAt: Date
    var lastSyncedAt: Date?
    var submitterClientID: String?

    init(
        id: String = UUID().uuidString,
        remoteID: String? = nil,
        targetKind: InstructorGougeReportTargetKind,
        instructorID: String,
        reviewID: String? = nil,
        instructorName: String,
        squadronID: String,
        eventName: String? = nil,
        eventKind: InstructorReviewEventKind? = nil,
        reviewText: String? = nil,
        reasonTitle: String,
        note: String? = nil,
        submittedAt: Date = .now,
        status: InstructorGougeReportStatus = .open,
        origin: InstructorReviewOrigin = .localSubmission,
        syncState: InstructorReviewSyncState = .localOnly,
        lastModifiedAt: Date = .now,
        lastSyncedAt: Date? = nil,
        submitterClientID: String? = nil
    ) {
        self.id = id
        self.remoteID = remoteID
        self.targetKind = targetKind
        self.instructorID = instructorID
        self.reviewID = reviewID
        self.instructorName = instructorName
        self.squadronID = squadronID
        self.eventName = eventName
        self.eventKind = eventKind
        self.reviewText = reviewText
        self.reasonTitle = reasonTitle
        self.note = note
        self.submittedAt = submittedAt
        self.status = status
        self.origin = origin
        self.syncState = syncState
        self.lastModifiedAt = lastModifiedAt
        self.lastSyncedAt = lastSyncedAt
        self.submitterClientID = submitterClientID
    }
}

struct InstructorReviewRecord: Identifiable, Codable, Hashable {
    private enum CodingKeys: String, CodingKey {
        case id
        case remoteID
        case instructorName
        case squadronID
        case eventName
        case eventKind
        case eventID
        case chillScore
        case gradingScore
        case reviewText
        case submittedAt
        case status
        case origin
        case syncState
        case lastModifiedAt
        case lastSyncedAt
        case submitterClientID
        case actionType
        case targetReviewID
        case visibilityState
    }

    let id: String
    var remoteID: String?
    var instructorName: String
    var squadronID: String
    var eventName: String?
    var eventKind: InstructorReviewEventKind
    var chillScore: Int
    var gradingScore: Int
    var reviewText: String
    var submittedAt: Date
    var status: ReviewStatus
    var origin: InstructorReviewOrigin
    var syncState: InstructorReviewSyncState
    var lastModifiedAt: Date
    var lastSyncedAt: Date?
    var submitterClientID: String?
    var actionType: InstructorReviewActionType
    var targetReviewID: String?
    var visibilityState: InstructorReviewVisibilityState

    init(
        id: String = UUID().uuidString,
        remoteID: String? = nil,
        instructorName: String,
        squadronID: String,
        eventName: String?,
        eventKind: InstructorReviewEventKind,
        chillScore: Int,
        gradingScore: Int,
        reviewText: String,
        submittedAt: Date = .now,
        status: ReviewStatus,
        origin: InstructorReviewOrigin = .localSubmission,
        syncState: InstructorReviewSyncState = .localOnly,
        lastModifiedAt: Date = .now,
        lastSyncedAt: Date? = nil,
        submitterClientID: String? = nil,
        actionType: InstructorReviewActionType = .create,
        targetReviewID: String? = nil,
        visibilityState: InstructorReviewVisibilityState = .public
    ) {
        self.id = id
        self.remoteID = remoteID
        self.instructorName = instructorName
        self.squadronID = squadronID
        self.eventName = eventName
        self.eventKind = eventKind
        self.chillScore = chillScore
        self.gradingScore = gradingScore
        self.reviewText = reviewText
        self.submittedAt = submittedAt
        self.status = status
        self.origin = origin
        self.syncState = syncState
        self.lastModifiedAt = lastModifiedAt
        self.lastSyncedAt = lastSyncedAt
        self.submitterClientID = submitterClientID
        self.actionType = actionType
        self.targetReviewID = targetReviewID
        self.visibilityState = visibilityState
    }

    init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        id = try container.decodeIfPresent(String.self, forKey: .id) ?? UUID().uuidString
        remoteID = try container.decodeIfPresent(String.self, forKey: .remoteID)
        instructorName = try container.decode(String.self, forKey: .instructorName)
        squadronID = try container.decode(String.self, forKey: .squadronID)
        chillScore = try container.decode(Int.self, forKey: .chillScore)
        gradingScore = try container.decode(Int.self, forKey: .gradingScore)
        reviewText = try container.decode(String.self, forKey: .reviewText)
        submittedAt = try container.decode(Date.self, forKey: .submittedAt)
        status = try container.decode(ReviewStatus.self, forKey: .status)
        origin = try container.decodeIfPresent(InstructorReviewOrigin.self, forKey: .origin) ?? .seed
        syncState = try container.decodeIfPresent(InstructorReviewSyncState.self, forKey: .syncState) ?? .synced
        lastModifiedAt = try container.decodeIfPresent(Date.self, forKey: .lastModifiedAt) ?? submittedAt
        lastSyncedAt = try container.decodeIfPresent(Date.self, forKey: .lastSyncedAt)
        submitterClientID = try container.decodeIfPresent(String.self, forKey: .submitterClientID)
        actionType = try container.decodeIfPresent(InstructorReviewActionType.self, forKey: .actionType) ?? .create
        targetReviewID = try container.decodeIfPresent(String.self, forKey: .targetReviewID)
        visibilityState = try container.decodeIfPresent(InstructorReviewVisibilityState.self, forKey: .visibilityState) ?? .public

        if let eventKind = try container.decodeIfPresent(InstructorReviewEventKind.self, forKey: .eventKind) {
            self.eventName = try container.decodeIfPresent(String.self, forKey: .eventName)
            self.eventKind = eventKind
        } else if let legacyEventID = try container.decodeIfPresent(String.self, forKey: .eventID) {
            let legacyEvent = InstructorReviewSeedData.legacyEvent(forLegacyID: legacyEventID)
            eventName = legacyEvent.displayName
            eventKind = legacyEvent.kind
        } else {
            eventName = nil
            eventKind = .flight
        }
    }

    func encode(to encoder: Encoder) throws {
        var container = encoder.container(keyedBy: CodingKeys.self)
        try container.encode(id, forKey: .id)
        try container.encodeIfPresent(remoteID, forKey: .remoteID)
        try container.encode(instructorName, forKey: .instructorName)
        try container.encode(squadronID, forKey: .squadronID)
        try container.encodeIfPresent(eventName, forKey: .eventName)
        try container.encode(eventKind, forKey: .eventKind)
        try container.encode(chillScore, forKey: .chillScore)
        try container.encode(gradingScore, forKey: .gradingScore)
        try container.encode(reviewText, forKey: .reviewText)
        try container.encode(submittedAt, forKey: .submittedAt)
        try container.encode(status, forKey: .status)
        try container.encode(origin, forKey: .origin)
        try container.encode(syncState, forKey: .syncState)
        try container.encode(lastModifiedAt, forKey: .lastModifiedAt)
        try container.encodeIfPresent(lastSyncedAt, forKey: .lastSyncedAt)
        try container.encodeIfPresent(submitterClientID, forKey: .submitterClientID)
        try container.encode(actionType, forKey: .actionType)
        try container.encodeIfPresent(targetReviewID, forKey: .targetReviewID)
        try container.encode(visibilityState, forKey: .visibilityState)
    }
}

extension Instructor {
    var capabilityBadges: [InstructorReviewEventKind] {
        InstructorReviewEventKind.allCases.filter { capabilities.contains($0) }
    }
}
