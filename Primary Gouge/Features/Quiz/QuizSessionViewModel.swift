import Foundation
import Combine

@MainActor
final class QuizSessionViewModel: ObservableObject {
    enum Mode: Hashable {
        case quiz
        case missedReview(sourceSessionID: String)

        var tracksPerformance: Bool {
            switch self {
            case .quiz:
                return true
            case .missedReview:
                return false
            }
        }
    }

    let mode: Mode
    let categoryID: String
    let categoryTitle: String
    let questions: [QuizQuestion]

    @Published private(set) var currentIndex: Int = 0
    @Published var selectedChoiceID: String?
    @Published private(set) var submittedResult: QuizQuestionResult?

    private(set) var selectedAnswerIDs: [String: String] = [:]
    private(set) var results: [QuizQuestionResult] = []

    init(mode: Mode = .quiz, categoryID: String, categoryTitle: String, questions: [QuizQuestion]) {
        self.mode = mode
        self.categoryID = categoryID
        self.categoryTitle = categoryTitle
        self.questions = questions
    }

    var currentQuestion: QuizQuestion {
        questions[currentIndex]
    }

    var progressText: String {
        "Question \(currentIndex + 1) of \(questions.count)"
    }

    var progressValue: Double {
        guard !questions.isEmpty else { return 0 }
        return Double(currentIndex + 1) / Double(questions.count)
    }

    var isSubmitted: Bool {
        submittedResult != nil
    }

    var canAdvance: Bool {
        isSubmitted
    }

    var isLastQuestion: Bool {
        currentIndex == questions.count - 1
    }

    var primaryActionTitle: String {
        if isLastQuestion {
            return mode.tracksPerformance ? "See Results" : "Finish Review"
        }
        return "Continue"
    }

    var resultBannerTitle: String? {
        guard let submittedResult else { return nil }
        return submittedResult.wasCorrect ? "Correct" : "Incorrect"
    }

    @discardableResult
    func selectChoice(_ choiceID: String) -> QuizQuestionResult? {
        guard !isSubmitted else { return nil }
        let question = currentQuestion
        selectedChoiceID = choiceID
        let result = QuizQuestionResult(
            questionID: question.id,
            selectedChoiceID: choiceID,
            correctChoiceID: question.correctChoiceID,
            wasCorrect: question.isCorrect(choiceID: choiceID),
            categoryID: question.categoryID,
            tags: question.tags
        )

        selectedAnswerIDs[question.id] = choiceID
        results.append(result)
        submittedResult = result
        return result
    }

    func choiceState(for choiceID: String) -> QuizAnswerVisualState {
        guard let submittedResult else { return .idle }

        if choiceID == submittedResult.correctChoiceID {
            return submittedResult.wasCorrect ? .correct : .correctReveal
        }

        if choiceID == submittedResult.selectedChoiceID {
            return .incorrect
        }

        return .subdued
    }

    func advance() -> QuizSessionRecord? {
        guard isSubmitted else { return nil }

        if isLastQuestion {
            return buildSessionRecord()
        }

        currentIndex += 1
        selectedChoiceID = nil
        submittedResult = nil
        return nil
    }

    func restart() {
        currentIndex = 0
        selectedChoiceID = nil
        submittedResult = nil
        selectedAnswerIDs = [:]
        results = []
    }

    private func buildSessionRecord() -> QuizSessionRecord {
        let correctAnswerIDs = Dictionary(uniqueKeysWithValues: questions.map { ($0.id, $0.correctChoiceID) })

        return QuizSessionRecord(
            categoryID: categoryID,
            questionCount: questions.count,
            questionIDs: questions.map(\.id),
            selectedAnswerIDs: selectedAnswerIDs,
            correctAnswerIDs: correctAnswerIDs,
            results: results,
            finalScore: results.filter(\.wasCorrect).count,
            completionDate: .now
        )
    }
}
