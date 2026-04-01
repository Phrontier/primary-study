import Foundation
import Combine

@MainActor
final class QuizStore: ObservableObject {
    private struct QuizDatabase: Codable {
        var questionPerformance: [String: QuizQuestionPerformanceRecord] = [:]
        var sessionHistory: [QuizSessionRecord] = []
    }

    @Published private(set) var bank: QuizBank
    @Published private(set) var questionPerformance: [String: QuizQuestionPerformanceRecord]
    @Published private(set) var sessionHistory: [QuizSessionRecord]

    private let repository: ContentRepository
    private let persistenceURL: URL
    private let injectedBank: QuizBank?

    init(
        repository: ContentRepository? = nil,
        persistenceURL: URL? = nil,
        bank: QuizBank? = nil
    ) {
        let resolvedRepository = repository ?? ContentRepository()
        self.repository = resolvedRepository
        self.persistenceURL = persistenceURL ?? Self.defaultPersistenceURL()
        self.injectedBank = bank
        self.bank = bank ?? resolvedRepository.loadQuizBank()

        let database = Self.loadDatabase(from: self.persistenceURL)
        self.questionPerformance = database.questionPerformance
        self.sessionHistory = database.sessionHistory.sorted { $0.completionDate > $1.completionDate }
    }

    func configure() {
        if let injectedBank {
            bank = injectedBank
        } else {
            bank = repository.loadQuizBank()
        }
    }

    func categoryOptions() -> [QuizCategoryOption] {
        let allOption = QuizCategoryOption(
            id: QuizCategoryOption.allID,
            categoryID: nil,
            title: "All Categories",
            summary: "Mix questions across the full quiz bank for a broader check ride through universal primary gouge.",
            iconName: "square.grid.2x2.fill",
            availableCount: questions(for: nil).count,
            tags: bank.categories.flatMap(\.tags)
        )

        let categoryOptions = bank.categories.map { category in
            QuizCategoryOption(
                id: category.id,
                categoryID: category.id,
                title: category.title,
                summary: category.summary,
                iconName: category.iconName,
                availableCount: questions(for: category.id).count,
                tags: category.tags
            )
        }

        return [allOption] + categoryOptions
    }

    func category(id: String) -> QuizCategory? {
        bank.category(id: id)
    }

    func question(id: String) -> QuizQuestion? {
        bank.question(id: id)
    }

    func questions(for categoryID: String?) -> [QuizQuestion] {
        bank.questions(for: categoryID)
            .filter(\.isValid)
            .sorted { lhs, rhs in
                if lhs.categoryID == rhs.categoryID {
                    return lhs.prompt.localizedCaseInsensitiveCompare(rhs.prompt) == .orderedAscending
                }

                return lhs.categoryID.localizedCaseInsensitiveCompare(rhs.categoryID) == .orderedAscending
            }
    }

    func buildQuestionSet(categoryID: String?, count: Int) -> [QuizQuestion] {
        Array(questions(for: categoryID).shuffled().prefix(count))
    }

    func canStartQuiz(categoryID: String?, count: Int) -> Bool {
        questions(for: categoryID).count >= count
    }

    func history(for categoryID: String? = nil) -> [QuizSessionRecord] {
        sessionHistory
            .filter { categoryID == nil || $0.categoryID == categoryID }
            .sorted { $0.completionDate > $1.completionDate }
    }

    func questionPerformanceRecord(for questionID: String) -> QuizQuestionPerformanceRecord? {
        questionPerformance[questionID]
    }

    @discardableResult
    func recordQuestionOutcome(
        question: QuizQuestion,
        selectedChoiceID: String,
        answeredAt: Date = .now
    ) -> QuizQuestionResult {
        let result = QuizQuestionResult(
            questionID: question.id,
            selectedChoiceID: selectedChoiceID,
            correctChoiceID: question.correctChoiceID,
            wasCorrect: question.isCorrect(choiceID: selectedChoiceID),
            categoryID: question.categoryID,
            tags: question.tags
        )

        applyPerformanceUpdates(for: [result], questions: [question], answeredAt: answeredAt)
        persist()
        return result
    }

    func recordCompletedSession(_ session: QuizSessionRecord, questions: [QuizQuestion]) {
        applyPerformanceUpdates(for: session.results, questions: questions, answeredAt: session.completionDate)
        sessionHistory.insert(session, at: 0)
        sessionHistory.sort { $0.completionDate > $1.completionDate }
        sessionHistory = Array(sessionHistory.prefix(150))
        persist()
    }

    func missedQueue(from session: QuizSessionRecord) -> QuizMissedQueue {
        QuizMissedQueue(questionIDs: session.missedQuestionIDs, sourceSessionID: session.id)
    }

    func missedQuestions(from session: QuizSessionRecord) -> [QuizQuestion] {
        session.missedQuestionIDs.compactMap(question(id:))
    }

    func missedCategories(for session: QuizSessionRecord) -> [QuizCategoryMissSnapshot] {
        Dictionary(grouping: session.results.filter { !$0.wasCorrect }, by: \.categoryID)
            .compactMap { categoryID, results in
                let title = category(id: categoryID)?.title ?? prettifiedTag(categoryID)
                return QuizCategoryMissSnapshot(id: categoryID, title: title, missedCount: results.count)
            }
            .sorted { lhs, rhs in
                if lhs.missedCount == rhs.missedCount {
                    return lhs.title.localizedCaseInsensitiveCompare(rhs.title) == .orderedAscending
                }
                return lhs.missedCount > rhs.missedCount
            }
    }

    func weakAreaSignals(considering session: QuizSessionRecord? = nil, limit: Int = 3) -> [QuizWeakAreaSignal] {
        var categoryScores: [String: Double] = [:]
        var categoryMisses: [String: Int] = [:]
        var tagScores: [String: Double] = [:]
        var tagMisses: [String: Int] = [:]

        for record in questionPerformance.values {
            guard record.attempts > 0 else { continue }

            let missRate = Double(record.incorrectAttempts) / Double(record.attempts)
            let repeatPenalty = min(Double(record.incorrectAttempts) * 0.12, 0.75)
            let recentPenalty = record.lastAnswerWasCorrect == false ? 0.45 : 0.0
            let score = missRate + repeatPenalty + recentPenalty + max(0, 0.7 - record.performanceScore)

            categoryScores[record.categoryID, default: 0] += score
            categoryMisses[record.categoryID, default: 0] += record.incorrectAttempts

            let weight = score / Double(max(record.tags.count, 1))
            for tag in record.tags {
                tagScores[tag, default: 0] += weight
                tagMisses[tag, default: 0] += record.incorrectAttempts
            }
        }

        if let session {
            for result in session.results where !result.wasCorrect {
                categoryScores[result.categoryID, default: 0] += 1.4
                categoryMisses[result.categoryID, default: 0] += 1

                let weight = 1.0 / Double(max(result.tags.count, 1))
                for tag in result.tags {
                    tagScores[tag, default: 0] += weight
                    tagMisses[tag, default: 0] += 1
                }
            }
        }

        var signals: [QuizWeakAreaSignal] = categoryScores.compactMap { categoryID, score in
            guard score > 0.55 else { return nil }
            let misses = categoryMisses[categoryID, default: 0]
            let title = category(id: categoryID)?.title ?? prettifiedTag(categoryID)
            let detail = misses == 1 ? "Missed 1 question recently" : "Missed \(misses) questions recently"
            return QuizWeakAreaSignal(
                id: "category-\(categoryID)",
                kind: .category(id: categoryID),
                title: title,
                detail: detail,
                score: score
            )
        }

        signals.append(contentsOf: tagScores.compactMap { tag, score in
            guard score > 0.65 else { return nil }
            let misses = tagMisses[tag, default: 0]
            let detail = misses == 1 ? "Repeated trouble point" : "\(misses) misses tied to this topic"
            return QuizWeakAreaSignal(
                id: "tag-\(tag)",
                kind: .tag(tag),
                title: prettifiedTag(tag),
                detail: detail,
                score: score
            )
        })

        return signals
            .sorted { lhs, rhs in
                if lhs.score == rhs.score {
                    return lhs.title.localizedCaseInsensitiveCompare(rhs.title) == .orderedAscending
                }
                return lhs.score > rhs.score
            }
            .prefix(limit)
            .map { $0 }
    }

    private func persist() {
        let database = QuizDatabase(questionPerformance: questionPerformance, sessionHistory: sessionHistory)

        do {
            let directory = persistenceURL.deletingLastPathComponent()
            try FileManager.default.createDirectory(at: directory, withIntermediateDirectories: true)
            let data = try JSONEncoder.quizEncoder.encode(database)
            try data.write(to: persistenceURL, options: .atomic)
        } catch {
            assertionFailure("Failed to persist quiz store: \(error)")
        }
    }

    private func prettifiedTag(_ tag: String) -> String {
        tag
            .split(separator: "-")
            .map { $0.capitalized }
            .joined(separator: " ")
    }

    private func applyPerformanceUpdates(
        for results: [QuizQuestionResult],
        questions: [QuizQuestion],
        answeredAt: Date
    ) {
        var updatedPerformance = questionPerformance

        for result in results {
            let question = questions.first(where: { $0.id == result.questionID }) ?? bank.question(id: result.questionID)
            var record = updatedPerformance[result.questionID] ?? QuizQuestionPerformanceRecord(
                questionID: result.questionID,
                categoryID: result.categoryID,
                tags: question?.tags ?? result.tags
            )
            record.recordAnswer(wasCorrect: result.wasCorrect, answeredAt: answeredAt)
            updatedPerformance[result.questionID] = record
        }

        questionPerformance = updatedPerformance
    }

    private static func defaultPersistenceURL() -> URL {
        let baseURL = FileManager.default.urls(for: .applicationSupportDirectory, in: .userDomainMask).first
            ?? FileManager.default.temporaryDirectory
        return baseURL
            .appendingPathComponent("PrimaryGouge", isDirectory: true)
            .appendingPathComponent("quiz-store.json")
    }

    private static func loadDatabase(from url: URL) -> QuizDatabase {
        guard let data = try? Data(contentsOf: url),
              let database = try? JSONDecoder.quizDecoder.decode(QuizDatabase.self, from: data) else {
            return QuizDatabase()
        }

        return database
    }
}

private extension JSONEncoder {
    static var quizEncoder: JSONEncoder {
        let encoder = JSONEncoder()
        encoder.dateEncodingStrategy = .iso8601
        encoder.outputFormatting = [.prettyPrinted, .sortedKeys]
        return encoder
    }
}

private extension JSONDecoder {
    static var quizDecoder: JSONDecoder {
        let decoder = JSONDecoder()
        decoder.dateDecodingStrategy = .iso8601
        return decoder
    }
}
