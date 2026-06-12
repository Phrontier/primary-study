import Foundation

@MainActor
final class ProgressStore {
    private struct ProgressDatabase: Codable {
        var cardProgress: [String: CardProgressRecord] = [:]
        var eventProgress: [String: EventProgressRecord] = [:]
        var testAttempts: [TestAttemptRecord] = []
        var activities: [StudyActivityRecord] = []
        var sessions: [StudySessionRecord] = []
        var dailyQuestionProgress: [String: DailyQuestionProgressRecord] = [:]
        var homePreferences = HomePreferencesRecord()

        init() {}

        private enum CodingKeys: String, CodingKey {
            case cardProgress
            case eventProgress
            case testAttempts
            case activities
            case sessions
            case dailyQuestionProgress
            case homePreferences
        }

        init(from decoder: Decoder) throws {
            let container = try decoder.container(keyedBy: CodingKeys.self)
            cardProgress = try container.decodeIfPresent([String: CardProgressRecord].self, forKey: .cardProgress) ?? [:]
            eventProgress = try container.decodeIfPresent([String: EventProgressRecord].self, forKey: .eventProgress) ?? [:]
            testAttempts = try container.decodeIfPresent([TestAttemptRecord].self, forKey: .testAttempts) ?? []
            activities = try container.decodeIfPresent([StudyActivityRecord].self, forKey: .activities) ?? []
            sessions = try container.decodeIfPresent([StudySessionRecord].self, forKey: .sessions) ?? []
            dailyQuestionProgress = try container.decodeIfPresent([String: DailyQuestionProgressRecord].self, forKey: .dailyQuestionProgress) ?? [:]
            homePreferences = try container.decodeIfPresent(HomePreferencesRecord.self, forKey: .homePreferences) ?? HomePreferencesRecord()
        }
    }

    private let persistenceURL: URL
    private var database: ProgressDatabase

    init(persistenceURL: URL? = nil) {
        self.persistenceURL = persistenceURL ?? Self.defaultPersistenceURL()
        self.database = Self.loadDatabase(from: self.persistenceURL)
    }

    func progress(for cardID: String) -> CardProgressSnapshot {
        guard let record = database.cardProgress[cardID] else {
            return .unseen
        }

        let adjustedMastery = decayMastery(record.mastery, lastReviewedAt: record.lastReviewedAt)
        return CardProgressSnapshot(
            mastery: adjustedMastery,
            stability: record.stability,
            nextReviewAt: record.nextReviewAt,
            lastReviewedAt: record.lastReviewedAt
        )
    }

    func recordReview(for cardID: String, rating: FlashcardRating) {
        var record = database.cardProgress[cardID] ?? CardProgressRecord(cardID: cardID)
        let updated = SpacedRepetitionEngine.nextState(
            from: progress(for: cardID),
            rating: rating,
            now: .now
        )

        record.mastery = updated.mastery
        record.stability = updated.stability
        record.lastReviewedAt = updated.lastReviewedAt
        record.nextReviewAt = updated.nextReviewAt
        record.reviewCount += 1
        record.lastRating = rating

        switch rating {
        case .missed:
            record.missedCount += 1
        case .hard:
            record.hardCount += 1
        case .good:
            record.goodCount += 1
        case .easy:
            record.easyCount += 1
        }

        database.cardProgress[cardID] = record
        persist()
    }

    func markEventViewed(eventID: String) {
        var record = database.eventProgress[eventID] ?? EventProgressRecord(eventID: eventID)
        if record.firstViewedAt == nil {
            record.firstViewedAt = .now
        }
        database.eventProgress[eventID] = record
        persist()
    }

    func markEventStudied(eventID: String) {
        var record = database.eventProgress[eventID] ?? EventProgressRecord(eventID: eventID)
        if record.firstViewedAt == nil {
            record.firstViewedAt = .now
        }
        record.lastStudiedAt = .now
        record.completedAt = record.completedAt ?? .now
        database.eventProgress[eventID] = record
        persist()
    }

    func eventProgress(for eventID: String) -> EventProgressSnapshot {
        guard let record = database.eventProgress[eventID] else {
            return .empty
        }

        return EventProgressSnapshot(
            firstViewedAt: record.firstViewedAt,
            lastStudiedAt: record.lastStudiedAt,
            completedAt: record.completedAt
        )
    }

    func recordTestAttempt(bankID: String, score: Int, total: Int, missedQuestionIDs: [String], topicIDs: [String], elapsedSeconds: Double?) {
        let attempt = TestAttemptRecord(
            bankID: bankID,
            score: score,
            total: total,
            missedQuestionIDs: missedQuestionIDs,
            topicIDs: topicIDs,
            elapsedSeconds: elapsedSeconds
        )

        database.testAttempts.append(attempt)
        persist()
    }

    func testHistory(for bankID: String) -> [TestAttemptRecord] {
        database.testAttempts
            .filter { $0.bankID == bankID }
            .sorted { $0.takenAt > $1.takenAt }
    }

    func allCardProgressRecords() -> [CardProgressRecord] {
        Array(database.cardProgress.values)
    }

    func allTestAttempts() -> [TestAttemptRecord] {
        database.testAttempts.sorted { $0.takenAt > $1.takenAt }
    }

    func recordActivity(_ activity: StudyActivityRecord) {
        database.activities.append(activity)
        database.activities.sort { $0.lastInteractedAt > $1.lastInteractedAt }
        database.activities = Array(database.activities.prefix(250))
        persist()
    }

    func recentActivities(limit: Int? = nil) -> [StudyActivityRecord] {
        let activities = database.activities.sorted { $0.lastInteractedAt > $1.lastInteractedAt }
        if let limit {
            return Array(activities.prefix(limit))
        }
        return activities
    }

    func recordSession(_ session: StudySessionRecord) {
        database.sessions.append(session)
        database.sessions.sort { $0.endedAt > $1.endedAt }
        database.sessions = Array(database.sessions.prefix(200))
        persist()
    }

    func recentSessions(limit: Int? = nil) -> [StudySessionRecord] {
        let sessions = database.sessions.sorted { $0.endedAt > $1.endedAt }
        if let limit {
            return Array(sessions.prefix(limit))
        }
        return sessions
    }

    func homePreferences() -> HomePreferencesRecord {
        database.homePreferences
    }

    func updateHomePreferences(_ mutate: (inout HomePreferencesRecord) -> Void) {
        mutate(&database.homePreferences)
        persist()
    }

    func dailyQuestionProgress(for questionID: String) -> DailyQuestionProgressRecord? {
        database.dailyQuestionProgress[questionID]
    }

    func updateDailyQuestionProgress(for questionID: String, _ mutate: (inout DailyQuestionProgressRecord) -> Void) {
        var record = database.dailyQuestionProgress[questionID] ?? DailyQuestionProgressRecord(questionID: questionID)
        mutate(&record)
        database.dailyQuestionProgress[questionID] = record
        persist()
    }

    func allDailyQuestionProgressRecords() -> [DailyQuestionProgressRecord] {
        Array(database.dailyQuestionProgress.values)
    }

    func resetLocalData() {
        database = ProgressDatabase()
        persist()
    }

    private func persist() {
        do {
            let directory = persistenceURL.deletingLastPathComponent()
            try FileManager.default.createDirectory(at: directory, withIntermediateDirectories: true)
            let data = try JSONEncoder.progressEncoder.encode(database)
            try data.write(to: persistenceURL, options: .atomic)
        } catch {
            assertionFailure("Failed to persist progress database: \(error)")
        }
    }

    private func decayMastery(_ mastery: Double, lastReviewedAt: Date?) -> Double {
        guard let lastReviewedAt else { return mastery }
        let days = max(0, Date().timeIntervalSince(lastReviewedAt) / 86_400.0)
        let decayFactor = exp(-days / 21.0)
        return max(0, min(1, mastery * decayFactor))
    }

    private static func defaultPersistenceURL() -> URL {
        let baseURL = FileManager.default.urls(for: .applicationSupportDirectory, in: .userDomainMask).first
            ?? FileManager.default.temporaryDirectory
        return baseURL
            .appendingPathComponent("PrimaryGouge", isDirectory: true)
            .appendingPathComponent("progress-store.json")
    }

    private static func loadDatabase(from url: URL) -> ProgressDatabase {
        guard
            let data = try? Data(contentsOf: url),
            let database = try? JSONDecoder.progressDecoder.decode(ProgressDatabase.self, from: data)
        else {
            return ProgressDatabase()
        }

        return database
    }
}

private extension JSONEncoder {
    static var progressEncoder: JSONEncoder {
        let encoder = JSONEncoder()
        encoder.dateEncodingStrategy = .iso8601
        encoder.outputFormatting = [.prettyPrinted, .sortedKeys]
        return encoder
    }
}

private extension JSONDecoder {
    static var progressDecoder: JSONDecoder {
        let decoder = JSONDecoder()
        decoder.dateDecodingStrategy = .iso8601
        return decoder
    }
}
