import Foundation

@MainActor
final class SwiftDataInstructorReviewRepository: InstructorReviewRepository {
    private struct InstructorReviewDatabase: Codable {
        var seedVersion: Int
        var reviews: [InstructorReviewRecord]
        var reports: [InstructorGougeReportRecord]

        init(seedVersion: Int = 0, reviews: [InstructorReviewRecord] = [], reports: [InstructorGougeReportRecord] = []) {
            self.seedVersion = seedVersion
            self.reviews = reviews
            self.reports = reports
        }

        private enum CodingKeys: String, CodingKey {
            case seedVersion
            case reviews
            case reports
        }

        init(from decoder: Decoder) throws {
            let container = try decoder.container(keyedBy: CodingKeys.self)
            seedVersion = try container.decodeIfPresent(Int.self, forKey: .seedVersion) ?? 0
            reviews = try container.decodeIfPresent([InstructorReviewRecord].self, forKey: .reviews) ?? []
            reports = try container.decodeIfPresent([InstructorGougeReportRecord].self, forKey: .reports) ?? []
        }
    }

    private let persistenceURL: URL
    private var database: InstructorReviewDatabase

    init(persistenceURL: URL? = nil) {
        self.persistenceURL = persistenceURL ?? Self.defaultPersistenceURL()
        self.database = Self.loadDatabase(from: self.persistenceURL)
    }

    func seedIfNeeded() throws {
        if database.reviews.isEmpty {
            database.reviews = InstructorReviewSeedData.reviews.map(Self.makeRecord(from:))
            database.seedVersion = InstructorReviewSeedData.currentSeedVersion
            try persist()
            return
        }

        guard database.seedVersion < InstructorReviewSeedData.currentSeedVersion else { return }
        try migrateSeedData()
    }

    func fetchInstructorSummaries(searchText: String) -> [Instructor] {
        let instructors = Dictionary(grouping: approvedRecords(), by: instructorID(for:))
            .compactMap { _, records in
                makeInstructor(from: records)
            }
            .sorted { lhs, rhs in
                if lhs.name == rhs.name {
                    return lhs.squadron.displayName < rhs.squadron.displayName
                }
                return lhs.name < rhs.name
            }

        guard !searchText.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty else {
            return instructors
        }

        let query = normalized(searchText)
        return instructors.filter { instructor in
            normalized(instructor.name).contains(query) || normalized(instructor.squadron.displayName).contains(query)
        }
    }

    func fetchInstructor(id: String) -> Instructor? {
        let records = approvedRecords().filter { instructorID(for: $0) == id }
        return makeInstructor(from: records)
    }

    func fetchPublishedReviews(for instructorID: String) -> [InstructorReview] {
        approvedRecords()
            .filter { self.instructorID(for: $0) == instructorID }
            .map(makeReview(from:))
            .sorted { $0.submittedAt > $1.submittedAt }
    }

    func fetchPendingReviews() -> [InstructorReview] {
        database.reviews
            .filter { $0.status == .pending }
            .map(makeReview(from:))
            .sorted { $0.submittedAt > $1.submittedAt }
    }

    func fetchOpenReports() -> [InstructorGougeReport] {
        database.reports
            .map(makeReport(from:))
            .sorted { $0.submittedAt > $1.submittedAt }
    }

    func fetchInstructorSuggestions(matching query: String) -> [InstructorNameSuggestion] {
        let query = query.trimmingCharacters(in: .whitespacesAndNewlines)
        let suggestions = Set(database.reviews.map {
            InstructorNameSuggestion(
                id: instructorID(for: $0),
                name: $0.instructorName,
                squadron: InstructorReviewSeedData.squadron(for: $0.squadronID)
            )
        })
        .sorted { lhs, rhs in
            if lhs.name == rhs.name {
                return lhs.squadron.submissionSortRank < rhs.squadron.submissionSortRank
            }
            return lhs.name < rhs.name
        }

        guard !query.isEmpty else {
            return Array(suggestions.prefix(6))
        }

        let normalizedQuery = normalized(query)
        let queryTokens = normalizedNameTokens(query)
        let prefixMatches = suggestions.filter { normalized($0.name).hasPrefix(normalizedQuery) }
        let tokenMatches = suggestions.filter {
            !normalized($0.name).hasPrefix(normalizedQuery) &&
            normalizedNameTokens($0.name) == queryTokens
        }
        let containsMatches = suggestions.filter {
            !normalized($0.name).hasPrefix(normalizedQuery) &&
            normalizedNameTokens($0.name) != queryTokens &&
            (normalized($0.name).contains(normalizedQuery) || normalized($0.squadron.displayName).contains(normalizedQuery))
        }
        return Array((prefixMatches + tokenMatches + containsMatches).prefix(6))
    }

    func fetchSquadrons() -> [Squadron] {
        InstructorReviewSeedData.squadrons.submissionSorted()
    }

    func fetchEvents() -> [InstructorReviewEvent] {
        InstructorReviewSeedData.events.sorted { $0.displayName < $1.displayName }
    }

    func submitReview(_ submission: InstructorReviewSubmission) throws {
        let record = InstructorReviewRecord(
            instructorName: submission.instructorName.trimmingCharacters(in: .whitespacesAndNewlines),
            squadronID: submission.squadron.id,
            eventName: submission.event.displayName,
            eventKind: submission.event.kind,
            chillScore: InstructorRatingScale.clamped(submission.chillScore),
            gradingScore: InstructorRatingScale.clamped(submission.gradingScore),
            reviewText: submission.reviewText.trimmingCharacters(in: .whitespacesAndNewlines),
            submittedAt: .now,
            status: .pending
        )

        database.reviews.append(record)
        try persist()
    }

    func submitReport(_ submission: InstructorGougeReportSubmission) throws {
        let trimmedNote = submission.note?.trimmingCharacters(in: .whitespacesAndNewlines)
        let record = InstructorGougeReportRecord(
            targetKind: submission.targetKind,
            instructorID: submission.instructorID,
            reviewID: submission.reviewID,
            instructorName: submission.instructorName.trimmingCharacters(in: .whitespacesAndNewlines),
            squadronID: submission.squadron.id,
            eventName: submission.eventName,
            eventKind: submission.eventKind,
            reviewText: submission.reviewText?.trimmingCharacters(in: .whitespacesAndNewlines),
            reasonTitle: submission.reasonTitle,
            note: trimmedNote?.isEmpty == true ? nil : trimmedNote
        )

        database.reports.append(record)
        try persist()
    }

    func dismissReport(id: String) throws {
        guard let index = database.reports.firstIndex(where: { $0.id == id }) else {
            throw InstructorReviewRepositoryError.reviewNotFound
        }

        database.reports.remove(at: index)
        try persist()
    }

    func approveReview(id: String) throws {
        guard let index = database.reviews.firstIndex(where: { $0.id == id }) else {
            throw InstructorReviewRepositoryError.reviewNotFound
        }

        database.reviews[index].status = .approved
        try persist()
    }

    func rejectReview(id: String) throws {
        guard let index = database.reviews.firstIndex(where: { $0.id == id }) else {
            throw InstructorReviewRepositoryError.reviewNotFound
        }

        database.reviews[index].status = .rejected
        database.reports.removeAll { $0.reviewID == id }
        try persist()
    }

    private func approvedRecords() -> [InstructorReviewRecord] {
        database.reviews.filter { $0.status == .approved }
    }

    private func makeInstructor(from records: [InstructorReviewRecord]) -> Instructor? {
        guard let first = records.first else { return nil }

        let chillAverage = records.map(\.chillScore).average
        let gradingAverage = records.map(\.gradingScore).average
        let capabilities = Set(records.map(\.eventKind))

        return Instructor(
            id: instructorID(for: first),
            name: first.instructorName,
            squadron: InstructorReviewSeedData.squadron(for: first.squadronID),
            capabilities: capabilities,
            publishedReviewCount: records.count,
            averageChillScore: chillAverage,
            averageGradingScore: gradingAverage
        )
    }

    private func makeReview(from record: InstructorReviewRecord) -> InstructorReview {
        let squadron = InstructorReviewSeedData.squadron(for: record.squadronID)
        return InstructorReview(
            id: record.id,
            instructorID: instructorID(for: record),
            instructorName: record.instructorName,
            squadron: squadron,
            eventName: record.eventName,
            eventKind: record.eventKind,
            chillScore: InstructorRatingScale.clamped(record.chillScore),
            gradingScore: InstructorRatingScale.clamped(record.gradingScore),
            reviewText: record.reviewText,
            submittedAt: record.submittedAt,
            status: record.status
        )
    }

    private func makeReport(from record: InstructorGougeReportRecord) -> InstructorGougeReport {
        InstructorGougeReport(
            id: record.id,
            targetKind: record.targetKind,
            instructorID: record.instructorID,
            reviewID: record.reviewID,
            instructorName: record.instructorName,
            squadron: InstructorReviewSeedData.squadron(for: record.squadronID),
            eventName: record.eventName,
            eventKind: record.eventKind,
            reviewText: record.reviewText,
            reasonTitle: record.reasonTitle,
            note: record.note,
            submittedAt: record.submittedAt
        )
    }

    private func migrateSeedData() throws {
        let currentSeedIDs = Set(InstructorReviewSeedData.reviews.map(\.id))
        database.reviews.removeAll { record in
            currentSeedIDs.contains(record.id) || InstructorReviewSeedData.legacyInstructorNames.contains(record.instructorName)
        }
        database.reviews.append(contentsOf: InstructorReviewSeedData.reviews.map(Self.makeRecord(from:)))
        database.seedVersion = InstructorReviewSeedData.currentSeedVersion
        try persist()
    }

    private func instructorID(for record: InstructorReviewRecord) -> String {
        Instructor.makeID(name: record.instructorName, squadronID: record.squadronID)
    }

    private func normalized(_ value: String) -> String {
        value
            .trimmingCharacters(in: .whitespacesAndNewlines)
            .folding(options: [.diacriticInsensitive, .caseInsensitive], locale: .current)
            .lowercased()
    }

    private func normalizedNameTokens(_ value: String) -> [String] {
        value
            .folding(options: [.diacriticInsensitive, .caseInsensitive], locale: .current)
            .components(separatedBy: CharacterSet.alphanumerics.inverted)
            .filter { !$0.isEmpty }
            .map { $0.lowercased() }
            .sorted()
    }

    private func persist() throws {
        let directory = persistenceURL.deletingLastPathComponent()
        try FileManager.default.createDirectory(at: directory, withIntermediateDirectories: true)
        let data = try JSONEncoder.reviewEncoder.encode(database)
        try data.write(to: persistenceURL, options: .atomic)
    }

    private static func defaultPersistenceURL() -> URL {
        let baseURL = FileManager.default.urls(for: .applicationSupportDirectory, in: .userDomainMask).first
            ?? FileManager.default.temporaryDirectory
        return baseURL
            .appendingPathComponent("PrimaryGouge", isDirectory: true)
            .appendingPathComponent("instructor-reviews.json")
    }

    private static func loadDatabase(from url: URL) -> InstructorReviewDatabase {
        guard
            let data = try? Data(contentsOf: url),
            let database = try? JSONDecoder.reviewDecoder.decode(InstructorReviewDatabase.self, from: data)
        else {
            return InstructorReviewDatabase()
        }

        return database
    }

    private static func makeRecord(from item: InstructorReviewSeedItem) -> InstructorReviewRecord {
        InstructorReviewRecord(
            id: item.id,
            instructorName: item.instructorName,
            squadronID: item.squadronID,
            eventName: item.eventName,
            eventKind: item.eventKind,
            chillScore: item.chillScore,
            gradingScore: item.gradingScore,
            reviewText: item.reviewText,
            submittedAt: item.submittedAt,
            status: item.status
        )
    }
}

private extension Collection where Element == Int {
    var average: Double {
        guard !isEmpty else { return 0 }
        return Double(reduce(0, +)) / Double(count)
    }
}

private extension JSONEncoder {
    static var reviewEncoder: JSONEncoder {
        let encoder = JSONEncoder()
        encoder.dateEncodingStrategy = .iso8601
        encoder.outputFormatting = [.prettyPrinted, .sortedKeys]
        return encoder
    }
}

private extension JSONDecoder {
    static var reviewDecoder: JSONDecoder {
        let decoder = JSONDecoder()
        decoder.dateDecodingStrategy = .iso8601
        return decoder
    }
}
