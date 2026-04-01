import Foundation

struct CardProgressRecord: Identifiable, Codable, Hashable {
    let id: String
    var cardID: String
    var mastery: Double
    var stability: Double
    var nextReviewAt: Date?
    var lastReviewedAt: Date?
    var reviewCount: Int
    var missedCount: Int
    var hardCount: Int
    var goodCount: Int
    var easyCount: Int
    var lastRating: FlashcardRating?

    init(
        cardID: String,
        mastery: Double = 0,
        stability: Double = 0,
        nextReviewAt: Date? = nil,
        lastReviewedAt: Date? = nil,
        reviewCount: Int = 0,
        missedCount: Int = 0,
        hardCount: Int = 0,
        goodCount: Int = 0,
        easyCount: Int = 0,
        lastRating: FlashcardRating? = nil
    ) {
        self.id = cardID
        self.cardID = cardID
        self.mastery = mastery
        self.stability = stability
        self.nextReviewAt = nextReviewAt
        self.lastReviewedAt = lastReviewedAt
        self.reviewCount = reviewCount
        self.missedCount = missedCount
        self.hardCount = hardCount
        self.goodCount = goodCount
        self.easyCount = easyCount
        self.lastRating = lastRating
    }
}

struct TestAttemptRecord: Identifiable, Codable, Hashable {
    let id: String
    var bankID: String
    var takenAt: Date
    var score: Int
    var total: Int
    var missedQuestionIDs: [String]
    var topicIDs: [String]
    var elapsedSeconds: Double?

    init(
        id: String = UUID().uuidString,
        bankID: String,
        takenAt: Date = .now,
        score: Int,
        total: Int,
        missedQuestionIDs: [String],
        topicIDs: [String] = [],
        elapsedSeconds: Double? = nil
    ) {
        self.id = id
        self.bankID = bankID
        self.takenAt = takenAt
        self.score = score
        self.total = total
        self.missedQuestionIDs = missedQuestionIDs
        self.topicIDs = topicIDs
        self.elapsedSeconds = elapsedSeconds
    }
}

struct EventProgressRecord: Identifiable, Codable, Hashable {
    let id: String
    var eventID: String
    var firstViewedAt: Date?
    var lastStudiedAt: Date?
    var completedAt: Date?

    init(eventID: String, firstViewedAt: Date? = nil, lastStudiedAt: Date? = nil, completedAt: Date? = nil) {
        self.id = eventID
        self.eventID = eventID
        self.firstViewedAt = firstViewedAt
        self.lastStudiedAt = lastStudiedAt
        self.completedAt = completedAt
    }
}

enum StudyTopicHomeRole: String, Codable, Hashable, CaseIterable {
    case focus
    case review
    case weakArea
    case dailyQuestion
}

struct StudyTopicDefinition: Identifiable, Codable, Hashable {
    let id: String
    let title: String
    let shortTitle: String
    let iconName: String
    let homeRoles: [StudyTopicHomeRole]
    let linkedTagValues: [String]
    let linkedResourceIDs: [String]
    let linkedLibraryHubIDs: [String]
    let preferredDestinationPhaseID: String?

    var isUserFocusable: Bool { homeRoles.contains(.focus) }
    var isReviewTopic: Bool { homeRoles.contains(.review) }
    var isWeakAreaTopic: Bool { homeRoles.contains(.weakArea) }
    var isDailyQuestionTopic: Bool { homeRoles.contains(.dailyQuestion) }

    static let homeTopics: [StudyTopicDefinition] = [
        StudyTopicDefinition(
            id: "eps",
            title: "Emergency Procedures",
            shortTitle: "EPs",
            iconName: "exclamationmark.shield.fill",
            homeRoles: [.focus, .review, .weakArea, .dailyQuestion],
            linkedTagValues: ["eps", "ep", "emergency", "abort", "airstart", "pel"],
            linkedResourceIDs: ["ep-limits-key", "ep-nwcs-admin", "contact-ep-nwcs"],
            linkedLibraryHubIDs: ["emergency-reference-hub"],
            preferredDestinationPhaseID: nil
        ),
        StudyTopicDefinition(
            id: "limits",
            title: "Operating Limits",
            shortTitle: "Limits",
            iconName: "gauge.with.dots.needle.bottom.50percent",
            homeRoles: [.focus, .review, .weakArea, .dailyQuestion],
            linkedTagValues: ["limits", "limit", "vmo", "vle", "g-limits"],
            linkedResourceIDs: ["ep-limits-key"],
            linkedLibraryHubIDs: ["emergency-reference-hub"],
            preferredDestinationPhaseID: nil
        ),
        StudyTopicDefinition(
            id: "nwc",
            title: "Notes, Warnings, Cautions",
            shortTitle: "N/W/C",
            iconName: "triangle.fill",
            homeRoles: [.focus, .review, .weakArea, .dailyQuestion],
            linkedTagValues: ["nwc", "warning", "warnings", "caution", "cautions", "notes"],
            linkedResourceIDs: ["ep-nwcs-admin", "contact-ep-nwcs"],
            linkedLibraryHubIDs: ["emergency-reference-hub"],
            preferredDestinationPhaseID: nil
        ),
        StudyTopicDefinition(
            id: "landing-pattern",
            title: "Landing Pattern",
            shortTitle: "Pattern",
            iconName: "airplane.arrival",
            homeRoles: [.focus, .review, .weakArea, .dailyQuestion],
            linkedTagValues: ["pattern", "landing", "final", "break", "touchdown"],
            linkedResourceIDs: ["contact-pattern-driver", "contact-pattern-guide", "contact-pattern-slideshow"],
            linkedLibraryHubIDs: [],
            preferredDestinationPhaseID: "contacts"
        ),
        StudyTopicDefinition(
            id: "instrument-comms",
            title: "Instrument Comms",
            shortTitle: "Inst Comms",
            iconName: "dot.radiowaves.left.and.right",
            homeRoles: [.focus, .weakArea, .dailyQuestion],
            linkedTagValues: ["instrument", "ifr", "radio", "comms", "approach", "holding"],
            linkedResourceIDs: ["instrument-ifg"],
            linkedLibraryHubIDs: [],
            preferredDestinationPhaseID: "instruments"
        ),
        StudyTopicDefinition(
            id: "lost-sight",
            title: "Lost Sight Procedures",
            shortTitle: "Lost Sight",
            iconName: "eye.trianglebadge.exclamationmark",
            homeRoles: [.focus, .weakArea, .dailyQuestion],
            linkedTagValues: ["lost sight", "visual", "imc", "lead", "wing", "formation"],
            linkedResourceIDs: ["formation-supp"],
            linkedLibraryHubIDs: [],
            preferredDestinationPhaseID: "formation"
        ),
        StudyTopicDefinition(
            id: "maneuvers",
            title: "Maneuvers",
            shortTitle: "Maneuvers",
            iconName: "arrow.trianglehead.2.clockwise.rotate.90",
            homeRoles: [.focus, .weakArea, .dailyQuestion],
            linkedTagValues: ["maneuver", "maneuvers", "stall", "spin", "loop", "immelmann"],
            linkedResourceIDs: [],
            linkedLibraryHubIDs: [],
            preferredDestinationPhaseID: "contacts"
        ),
        StudyTopicDefinition(
            id: "systems",
            title: "Aircraft Systems",
            shortTitle: "Systems",
            iconName: "gearshape.2.fill",
            homeRoles: [.focus, .weakArea, .dailyQuestion],
            linkedTagValues: ["system", "systems", "electrical", "fuel", "hydraulic", "obogs", "oil"],
            linkedResourceIDs: ["expanded-checklist"],
            linkedLibraryHubIDs: [],
            preferredDestinationPhaseID: "contacts"
        ),
        StudyTopicDefinition(
            id: "radio-calls",
            title: "Radio Calls",
            shortTitle: "Radio Calls",
            iconName: "radio.fill",
            homeRoles: [.focus, .weakArea, .dailyQuestion],
            linkedTagValues: ["radio", "calls", "uhf", "vhf", "nordo"],
            linkedResourceIDs: ["instrument-ifg"],
            linkedLibraryHubIDs: [],
            preferredDestinationPhaseID: "vnav"
        ),
        StudyTopicDefinition(
            id: "course-rules",
            title: "Course Rules",
            shortTitle: "Course Rules",
            iconName: "map.fill",
            homeRoles: [.focus, .review, .weakArea, .dailyQuestion],
            linkedTagValues: ["course rules", "woodsboro", "shamrock", "waldron", "aransas"],
            linkedResourceIDs: ["vnav-routes", "instrument-ifg"],
            linkedLibraryHubIDs: [],
            preferredDestinationPhaseID: "vnav"
        ),
        StudyTopicDefinition(
            id: "formation-admin",
            title: "Formation Admin",
            shortTitle: "Form Admin",
            iconName: "person.2.fill",
            homeRoles: [.focus, .weakArea, .dailyQuestion],
            linkedTagValues: ["formation", "admin", "contracts", "crossunder", "lead change"],
            linkedResourceIDs: ["formation-supp"],
            linkedLibraryHubIDs: [],
            preferredDestinationPhaseID: "formation"
        )
    ]
}

enum StudyActivityKind: String, Codable, Hashable {
    case event
    case flashcardDeck
    case flashcardSession
    case practiceTest
    case sharedResource
    case video
    case questionOfDay
}

enum StudyActivityDestination: Codable, Hashable {
    case event(phaseID: String, eventID: String)
    case eventDeck(phaseID: String, eventID: String, deckID: String)
    case libraryDeck(id: String)
    case sharedResource(id: String)
    case video(id: String)
    case questionOfDay(questionID: String)
}

struct StudyActivityRecord: Identifiable, Codable, Hashable {
    let id: String
    var kind: StudyActivityKind
    var destination: StudyActivityDestination
    var title: String
    var subtitle: String
    var topicIDs: [String]
    var startedAt: Date
    var lastInteractedAt: Date
    var completedAt: Date?
    var progressContext: String?

    init(
        id: String = UUID().uuidString,
        kind: StudyActivityKind,
        destination: StudyActivityDestination,
        title: String,
        subtitle: String,
        topicIDs: [String] = [],
        startedAt: Date = .now,
        lastInteractedAt: Date = .now,
        completedAt: Date? = nil,
        progressContext: String? = nil
    ) {
        self.id = id
        self.kind = kind
        self.destination = destination
        self.title = title
        self.subtitle = subtitle
        self.topicIDs = topicIDs
        self.startedAt = startedAt
        self.lastInteractedAt = lastInteractedAt
        self.completedAt = completedAt
        self.progressContext = progressContext
    }
}

enum StudySessionKind: String, Codable, Hashable {
    case flashcards
    case practiceTest
}

enum StudySessionOutcome: String, Codable, Hashable {
    case completed
    case abandoned
}

struct StudySessionRecord: Identifiable, Codable, Hashable {
    let id: String
    var activityKind: StudySessionKind
    var topicIDs: [String]
    var startedAt: Date
    var endedAt: Date
    var completedItems: Int
    var totalItems: Int
    var outcome: StudySessionOutcome

    init(
        id: String = UUID().uuidString,
        activityKind: StudySessionKind,
        topicIDs: [String],
        startedAt: Date,
        endedAt: Date,
        completedItems: Int,
        totalItems: Int,
        outcome: StudySessionOutcome
    ) {
        self.id = id
        self.activityKind = activityKind
        self.topicIDs = topicIDs
        self.startedAt = startedAt
        self.endedAt = endedAt
        self.completedItems = completedItems
        self.totalItems = totalItems
        self.outcome = outcome
    }
}

enum DailyQuestionRating: String, Codable, Hashable {
    case easy
    case hard
}

struct DailyQuestionProgressRecord: Identifiable, Codable, Hashable {
    let id: String
    var questionID: String
    var lastPresentedOn: Date?
    var revealedAt: Date?
    var lastRating: DailyQuestionRating?
    var savedForLaterAt: Date?
    var selectedChoiceID: String?
    var answeredAt: Date?
    var wasCorrect: Bool?

    init(
        questionID: String,
        lastPresentedOn: Date? = nil,
        revealedAt: Date? = nil,
        lastRating: DailyQuestionRating? = nil,
        savedForLaterAt: Date? = nil,
        selectedChoiceID: String? = nil,
        answeredAt: Date? = nil,
        wasCorrect: Bool? = nil
    ) {
        self.id = questionID
        self.questionID = questionID
        self.lastPresentedOn = lastPresentedOn
        self.revealedAt = revealedAt
        self.lastRating = lastRating
        self.savedForLaterAt = savedForLaterAt
        self.selectedChoiceID = selectedChoiceID
        self.answeredAt = answeredAt
        self.wasCorrect = wasCorrect
    }
}

struct HomePreferencesRecord: Codable, Hashable {
    var pinnedTopicIDs: [String]
    var savedDailyQuestionIDs: [String]
    var lastQuestionOfDayDate: Date?

    init(
        pinnedTopicIDs: [String] = ["eps", "limits", "landing-pattern"],
        savedDailyQuestionIDs: [String] = [],
        lastQuestionOfDayDate: Date? = nil
    ) {
        self.pinnedTopicIDs = pinnedTopicIDs
        self.savedDailyQuestionIDs = savedDailyQuestionIDs
        self.lastQuestionOfDayDate = lastQuestionOfDayDate
    }
}

enum HomeQuestionDifficulty: String, Codable, Hashable {
    case foundational
    case moderate
    case advanced
}

struct HomeQuestionDefinition: Identifiable, Codable, Hashable {
    let id: String
    let sourceQuestionID: String
    let categoryID: String
    let prompt: String
    let choices: [QuizChoice]
    let correctChoiceID: String
    let answer: String
    let topicIDs: [String]
    let difficulty: HomeQuestionDifficulty
    let isUniversal: Bool

    var correctChoice: QuizChoice? {
        choices.first { $0.id == correctChoiceID }
    }

    func choice(id: String) -> QuizChoice? {
        choices.first { $0.id == id }
    }

    func isCorrect(choiceID: String?) -> Bool {
        choiceID == correctChoiceID
    }
}

struct CardProgressSnapshot {
    let mastery: Double
    let stability: Double
    let nextReviewAt: Date?
    let lastReviewedAt: Date?

    var isDue: Bool {
        guard let nextReviewAt else { return true }
        return nextReviewAt <= .now
    }

    static let unseen = CardProgressSnapshot(mastery: 0, stability: 0, nextReviewAt: nil, lastReviewedAt: nil)
}

struct EventProgressSnapshot {
    let firstViewedAt: Date?
    let lastStudiedAt: Date?
    let completedAt: Date?

    static let empty = EventProgressSnapshot(firstViewedAt: nil, lastStudiedAt: nil, completedAt: nil)
}

enum FlashcardRating: String, Codable, CaseIterable, Hashable {
    case missed
    case hard
    case good
    case easy

    var label: String {
        switch self {
        case .missed: "Missed"
        case .hard: "Hard"
        case .good: "Good"
        case .easy: "Easy"
        }
    }

    var accentColorName: String {
        switch self {
        case .missed: "danger"
        case .hard: "warning"
        case .good: "accent"
        case .easy: "success"
        }
    }
}
