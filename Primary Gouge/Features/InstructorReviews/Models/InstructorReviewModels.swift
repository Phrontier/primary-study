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

struct Squadron: Identifiable, Hashable, Codable {
    let id: String
    let displayName: String
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
