import Foundation

struct QuizBank: Codable, Hashable {
    var categories: [QuizCategory]
    var questions: [QuizQuestion]

    static let empty = QuizBank(categories: [], questions: [])

    func questions(for categoryID: String?) -> [QuizQuestion] {
        guard let categoryID else {
            return questions
        }
        return questions.filter { $0.categoryID == categoryID }
    }

    func questionCount(for categoryID: String?) -> Int {
        questions(for: categoryID).count
    }

    func category(id: String) -> QuizCategory? {
        categories.first { $0.id == id }
    }

    func question(id: String) -> QuizQuestion? {
        questions.first { $0.id == id }
    }
}

struct QuizCategory: Codable, Identifiable, Hashable {
    let id: String
    let title: String
    let summary: String
    let iconName: String
    let tags: [String]
}

enum QuizQuestionFormat: String, Codable, Hashable, CaseIterable {
    case multipleChoice
    case trueFalse
}

struct QuizChoice: Codable, Identifiable, Hashable {
    let id: String
    let text: String
}

struct QuizQuestion: Codable, Identifiable, Hashable {
    let id: String
    let categoryID: String
    let prompt: String
    let format: QuizQuestionFormat
    let choices: [QuizChoice]
    let correctChoiceID: String
    let explanation: String
    let reference: String?
    let tags: [String]

    var correctChoice: QuizChoice? {
        choices.first { $0.id == correctChoiceID }
    }

    func choice(id: String) -> QuizChoice? {
        choices.first { $0.id == id }
    }

    func isCorrect(choiceID: String?) -> Bool {
        choiceID == correctChoiceID
    }

    var isValid: Bool {
        guard correctChoice != nil else { return false }

        switch format {
        case .multipleChoice:
            return choices.count == 4
        case .trueFalse:
            return choices.count == 2
        }
    }
}

struct QuizQuestionPerformanceRecord: Identifiable, Codable, Hashable {
    let id: String
    var questionID: String
    var categoryID: String
    var tags: [String]
    var attempts: Int
    var correctAttempts: Int
    var incorrectAttempts: Int
    var lastAnsweredAt: Date?
    var lastAnswerWasCorrect: Bool?
    var performanceScore: Double

    init(
        questionID: String,
        categoryID: String,
        tags: [String],
        attempts: Int = 0,
        correctAttempts: Int = 0,
        incorrectAttempts: Int = 0,
        lastAnsweredAt: Date? = nil,
        lastAnswerWasCorrect: Bool? = nil,
        performanceScore: Double = 0.5
    ) {
        self.id = questionID
        self.questionID = questionID
        self.categoryID = categoryID
        self.tags = tags
        self.attempts = attempts
        self.correctAttempts = correctAttempts
        self.incorrectAttempts = incorrectAttempts
        self.lastAnsweredAt = lastAnsweredAt
        self.lastAnswerWasCorrect = lastAnswerWasCorrect
        self.performanceScore = performanceScore
    }

    mutating func recordAnswer(wasCorrect: Bool, answeredAt: Date) {
        attempts += 1
        if wasCorrect {
            correctAttempts += 1
        } else {
            incorrectAttempts += 1
        }
        lastAnsweredAt = answeredAt
        lastAnswerWasCorrect = wasCorrect

        let smoothedCorrect = Double(correctAttempts) + 1.0
        let smoothedAttempts = Double(attempts) + 2.0
        performanceScore = smoothedCorrect / smoothedAttempts
    }
}

struct QuizQuestionResult: Identifiable, Codable, Hashable {
    let id: String
    let questionID: String
    let selectedChoiceID: String?
    let correctChoiceID: String
    let wasCorrect: Bool
    let categoryID: String
    let tags: [String]

    init(
        questionID: String,
        selectedChoiceID: String?,
        correctChoiceID: String,
        wasCorrect: Bool,
        categoryID: String,
        tags: [String]
    ) {
        self.id = questionID
        self.questionID = questionID
        self.selectedChoiceID = selectedChoiceID
        self.correctChoiceID = correctChoiceID
        self.wasCorrect = wasCorrect
        self.categoryID = categoryID
        self.tags = tags
    }
}

struct QuizSessionRecord: Identifiable, Codable, Hashable {
    let id: String
    var categoryID: String
    var questionCount: Int
    var questionIDs: [String]
    var selectedAnswerIDs: [String: String]
    var correctAnswerIDs: [String: String]
    var results: [QuizQuestionResult]
    var finalScore: Int
    var completionDate: Date

    init(
        id: String = UUID().uuidString,
        categoryID: String,
        questionCount: Int,
        questionIDs: [String],
        selectedAnswerIDs: [String: String],
        correctAnswerIDs: [String: String],
        results: [QuizQuestionResult],
        finalScore: Int,
        completionDate: Date = .now
    ) {
        self.id = id
        self.categoryID = categoryID
        self.questionCount = questionCount
        self.questionIDs = questionIDs
        self.selectedAnswerIDs = selectedAnswerIDs
        self.correctAnswerIDs = correctAnswerIDs
        self.results = results
        self.finalScore = finalScore
        self.completionDate = completionDate
    }

    var percentageScore: Int {
        guard questionCount > 0 else { return 0 }
        return Int((Double(finalScore) / Double(questionCount) * 100).rounded())
    }

    var missedQuestionIDs: [String] {
        results.filter { !$0.wasCorrect }.map(\.questionID)
    }
}

struct QuizWeakAreaSignal: Identifiable, Hashable {
    enum Kind: Hashable {
        case category(id: String)
        case tag(String)
    }

    let id: String
    let kind: Kind
    let title: String
    let detail: String
    let score: Double
}

struct QuizMissedQueue: Hashable {
    let questionIDs: [String]
    let sourceSessionID: String?

    var isEmpty: Bool { questionIDs.isEmpty }
}

struct QuizCategoryOption: Identifiable, Hashable {
    let id: String
    let categoryID: String?
    let title: String
    let summary: String
    let iconName: String
    let availableCount: Int
    let tags: [String]

    static let allID = "all-categories"

    var isAllCategories: Bool {
        categoryID == nil
    }
}

struct QuizCategoryMissSnapshot: Identifiable, Hashable {
    let id: String
    let title: String
    let missedCount: Int
}

struct QuizFeatureSpec {
    let title: String
    let subtitle: String
    let iconName: String

    static let toolsEntry = QuizFeatureSpec(
        title: "Quiz",
        subtitle: "Timed later, adaptive later. For now: clean, objective testing with history, missed-question review, and performance tracking.",
        iconName: "checkmark.circle.badge.questionmark.fill"
    )
}
