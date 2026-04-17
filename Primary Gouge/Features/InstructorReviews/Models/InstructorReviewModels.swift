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

    var reviewEventKind: InstructorReviewEventKind? {
        if id.hasPrefix("tw-") {
            return .sim
        }
        if id.hasPrefix("vt-") {
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
}

extension Sequence where Element == Squadron {
    func submissionSorted() -> [Squadron] {
        sorted { lhs, rhs in
            lhs.submissionSortRank < rhs.submissionSortRank
        }
    }
}

struct InstructorReviewEvent: Identifiable, Hashable, Codable {
    let id: String
    let displayName: String
    let kind: InstructorReviewEventKind
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

    var overallScore: Double {
        Double(chillScore + gradingScore) / 2.0
    }

    var hasEventName: Bool {
        eventName?.isEmpty == false
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

    var isReviewTarget: Bool {
        targetKind == .review
    }
}

struct InstructorGougeReportRecord: Identifiable, Codable, Hashable {
    let id: String
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

    init(
        id: String = UUID().uuidString,
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
        submittedAt: Date = .now
    ) {
        self.id = id
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
    }
}

struct InstructorReviewRecord: Identifiable, Codable, Hashable {
    private enum CodingKeys: String, CodingKey {
        case id
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
    }

    let id: String
    var instructorName: String
    var squadronID: String
    var eventName: String?
    var eventKind: InstructorReviewEventKind
    var chillScore: Int
    var gradingScore: Int
    var reviewText: String
    var submittedAt: Date
    var status: ReviewStatus

    init(
        id: String = UUID().uuidString,
        instructorName: String,
        squadronID: String,
        eventName: String?,
        eventKind: InstructorReviewEventKind,
        chillScore: Int,
        gradingScore: Int,
        reviewText: String,
        submittedAt: Date = .now,
        status: ReviewStatus
    ) {
        self.id = id
        self.instructorName = instructorName
        self.squadronID = squadronID
        self.eventName = eventName
        self.eventKind = eventKind
        self.chillScore = chillScore
        self.gradingScore = gradingScore
        self.reviewText = reviewText
        self.submittedAt = submittedAt
        self.status = status
    }

    init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        id = try container.decodeIfPresent(String.self, forKey: .id) ?? UUID().uuidString
        instructorName = try container.decode(String.self, forKey: .instructorName)
        squadronID = try container.decode(String.self, forKey: .squadronID)
        chillScore = try container.decode(Int.self, forKey: .chillScore)
        gradingScore = try container.decode(Int.self, forKey: .gradingScore)
        reviewText = try container.decode(String.self, forKey: .reviewText)
        submittedAt = try container.decode(Date.self, forKey: .submittedAt)
        status = try container.decode(ReviewStatus.self, forKey: .status)

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
        try container.encode(instructorName, forKey: .instructorName)
        try container.encode(squadronID, forKey: .squadronID)
        try container.encodeIfPresent(eventName, forKey: .eventName)
        try container.encode(eventKind, forKey: .eventKind)
        try container.encode(chillScore, forKey: .chillScore)
        try container.encode(gradingScore, forKey: .gradingScore)
        try container.encode(reviewText, forKey: .reviewText)
        try container.encode(submittedAt, forKey: .submittedAt)
        try container.encode(status, forKey: .status)
    }
}

extension Instructor {
    var capabilityBadges: [InstructorReviewEventKind] {
        InstructorReviewEventKind.allCases.filter { capabilities.contains($0) }
    }
}
