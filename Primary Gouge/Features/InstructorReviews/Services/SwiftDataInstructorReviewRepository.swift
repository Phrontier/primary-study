import Foundation

@MainActor
final class LocalInstructorReviewRepository: InstructorReviewRepository {
    private struct InstructorReviewDatabase: Codable {
        var seedVersion: Int
        var lastSuccessfulSyncAt: Date?
        var reviews: [InstructorReviewRecord]
        var reports: [InstructorGougeReportRecord]

        init(
            seedVersion: Int = 0,
            lastSuccessfulSyncAt: Date? = nil,
            reviews: [InstructorReviewRecord] = [],
            reports: [InstructorGougeReportRecord] = []
        ) {
            self.seedVersion = seedVersion
            self.lastSuccessfulSyncAt = lastSuccessfulSyncAt
            self.reviews = reviews
            self.reports = reports
        }

        private enum CodingKeys: String, CodingKey {
            case seedVersion
            case lastSuccessfulSyncAt
            case reviews
            case reports
        }

        init(from decoder: Decoder) throws {
            let container = try decoder.container(keyedBy: CodingKeys.self)
            seedVersion = try container.decodeIfPresent(Int.self, forKey: .seedVersion) ?? 0
            lastSuccessfulSyncAt = try container.decodeIfPresent(Date.self, forKey: .lastSuccessfulSyncAt)
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
            database.reviews = InstructorReviewSeedData.reviews.map(Self.makeSeedRecord(from:))
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
            .filter { $0.status == .open }
            .map(makeReport(from:))
            .sorted { $0.submittedAt > $1.submittedAt }
    }

    func fetchOpenCommunitySubmissions() -> [CommunitySubmissionModerationItem] {
        []
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
        try enqueueReviewSubmission(submission, clientID: nil)
    }

    func submitReport(_ submission: InstructorGougeReportSubmission) throws {
        try enqueueReport(submission, clientID: nil)
    }

    func dismissReport(id: String) async throws {
        guard let index = database.reports.firstIndex(where: { $0.id == id }) else {
            throw InstructorReviewRepositoryError.reviewNotFound
        }

        database.reports[index].status = .dismissed
        database.reports[index].lastModifiedAt = .now
        try persist()
    }

    func resolveCommunitySubmission(id: String) async throws {
        throw InstructorReviewRepositoryError.unavailable
    }

    func dismissCommunitySubmission(id: String) async throws {
        throw InstructorReviewRepositoryError.unavailable
    }

    func approveReview(id: String) async throws {
        guard let index = database.reviews.firstIndex(where: { $0.id == id }) else {
            throw InstructorReviewRepositoryError.reviewNotFound
        }

        database.reviews[index].status = .approved
        database.reviews[index].syncState = .synced
        database.reviews[index].lastModifiedAt = .now
        try persist()
    }

    func rejectReview(id: String) async throws {
        guard let index = database.reviews.firstIndex(where: { $0.id == id }) else {
            throw InstructorReviewRepositoryError.reviewNotFound
        }

        database.reviews[index].status = .rejected
        database.reviews[index].syncState = .synced
        database.reviews[index].lastModifiedAt = .now
        database.reports.indices
            .filter { database.reports[$0].reviewID == id && database.reports[$0].status == .open }
            .forEach {
                database.reports[$0].status = .resolved
                database.reports[$0].lastModifiedAt = .now
            }
        try persist()
    }

    func enqueueReviewSubmission(_ submission: InstructorReviewSubmission, clientID: String?) throws {
        let now = Date()
        let record = InstructorReviewRecord(
            instructorName: submission.instructorName.trimmingCharacters(in: .whitespacesAndNewlines),
            squadronID: submission.squadron.id,
            eventName: submission.event.displayName,
            eventKind: submission.event.kind,
            chillScore: InstructorRatingScale.clamped(submission.chillScore),
            gradingScore: InstructorRatingScale.clamped(submission.gradingScore),
            reviewText: submission.reviewText.trimmingCharacters(in: .whitespacesAndNewlines),
            submittedAt: now,
            status: .pending,
            origin: .localSubmission,
            syncState: .queuedUpload,
            lastModifiedAt: now,
            lastSyncedAt: nil,
            submitterClientID: clientID
        )

        database.reviews.append(record)
        try persist()
    }

    func enqueueReport(_ submission: InstructorGougeReportSubmission, clientID: String?) throws {
        let trimmedNote = submission.note?.trimmingCharacters(in: .whitespacesAndNewlines)
        let now = Date()
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
            note: trimmedNote?.isEmpty == true ? nil : trimmedNote,
            submittedAt: now,
            status: .open,
            origin: .localSubmission,
            syncState: .queuedUpload,
            lastModifiedAt: now,
            lastSyncedAt: nil,
            submitterClientID: clientID
        )

        database.reports.append(record)
        try persist()
    }

    func fetchQueuedReviewUploads() -> [InstructorReviewRecord] {
        database.reviews
            .filter {
                $0.origin == .localSubmission &&
                $0.status == .pending &&
                ($0.syncState == .queuedUpload || $0.syncState == .failed)
            }
            .sorted { $0.submittedAt < $1.submittedAt }
    }

    func fetchQueuedReportUploads() -> [InstructorGougeReportRecord] {
        database.reports
            .filter {
                $0.origin == .localSubmission &&
                $0.status == .open &&
                ($0.syncState == .queuedUpload || $0.syncState == .failed)
            }
            .sorted { $0.submittedAt < $1.submittedAt }
    }

    func markReviewUploaded(localID: String, remoteID: String, syncedAt: Date) {
        guard let index = database.reviews.firstIndex(where: { $0.id == localID }) else { return }
        database.reviews[index].remoteID = remoteID
        database.reviews[index].syncState = .uploadedPending
        database.reviews[index].lastSyncedAt = syncedAt
        database.reviews[index].submitterClientID = database.reviews[index].submitterClientID ?? database.reviews[index].submitterClientID
        try? persist()
    }

    func markReviewUploadFailed(localID: String) {
        guard let index = database.reviews.firstIndex(where: { $0.id == localID }) else { return }
        database.reviews[index].syncState = .failed
        try? persist()
    }

    func markReportUploaded(localID: String, remoteID: String, syncedAt: Date) {
        guard let index = database.reports.firstIndex(where: { $0.id == localID }) else { return }
        database.reports[index].remoteID = remoteID
        database.reports[index].syncState = .synced
        database.reports[index].lastSyncedAt = syncedAt
        try? persist()
    }

    func markReportUploadFailed(localID: String) {
        guard let index = database.reports.firstIndex(where: { $0.id == localID }) else { return }
        database.reports[index].syncState = .failed
        try? persist()
    }

    func applySubmissionStatuses(_ statuses: [RemoteSubmissionStatusSnapshot], syncedAt: Date) {
        guard !statuses.isEmpty else { return }

        for snapshot in statuses {
            guard let index = database.reviews.firstIndex(where: { ($0.remoteID ?? $0.id) == snapshot.id }) else {
                continue
            }

            database.reviews[index].status = snapshot.status
            database.reviews[index].lastModifiedAt = snapshot.updatedAt
            database.reviews[index].lastSyncedAt = syncedAt
            switch snapshot.status {
            case .approved, .rejected:
                database.reviews[index].syncState = .synced
            case .pending:
                database.reviews[index].syncState = .uploadedPending
            }
        }
        try? persist()
    }

    func applyReportStatuses(_ statuses: [RemoteReportStatusSnapshot], syncedAt: Date) {
        guard !statuses.isEmpty else { return }

        for snapshot in statuses {
            guard let index = database.reports.firstIndex(where: { ($0.remoteID ?? $0.id) == snapshot.id }) else {
                continue
            }

            database.reports[index].status = snapshot.status
            database.reports[index].lastModifiedAt = snapshot.updatedAt
            database.reports[index].lastSyncedAt = syncedAt
            database.reports[index].syncState = snapshot.status == .open ? .synced : .synced
        }
        try? persist()
    }

    func upsertPublishedReviews(_ reviews: [InstructorReviewRecord], syncedAt: Date) {
        let remoteIDs = Set(reviews.map(\.id))
        for incoming in reviews {
            if let index = database.reviews.firstIndex(where: { $0.id == incoming.id || $0.remoteID == incoming.remoteID }) {
                database.reviews[index].remoteID = incoming.remoteID ?? incoming.id
                database.reviews[index].instructorName = incoming.instructorName
                database.reviews[index].squadronID = incoming.squadronID
                database.reviews[index].eventName = incoming.eventName
                database.reviews[index].eventKind = incoming.eventKind
                database.reviews[index].chillScore = incoming.chillScore
                database.reviews[index].gradingScore = incoming.gradingScore
                database.reviews[index].reviewText = incoming.reviewText
                database.reviews[index].submittedAt = incoming.submittedAt
                database.reviews[index].status = .approved
                database.reviews[index].syncState = .synced
                database.reviews[index].lastModifiedAt = incoming.lastModifiedAt
                database.reviews[index].lastSyncedAt = syncedAt
                database.reviews[index].submitterClientID = incoming.submitterClientID ?? database.reviews[index].submitterClientID
            } else {
                var record = incoming
                record.lastSyncedAt = syncedAt
                database.reviews.append(record)
            }
        }

        for index in database.reviews.indices {
            let record = database.reviews[index]
            guard record.status == .approved else { continue }
            guard record.origin != .seed else { continue }
            guard let remoteID = record.remoteID ?? Optional(record.id) else { continue }
            guard !remoteIDs.contains(remoteID) else { continue }
            database.reviews[index].status = .rejected
            database.reviews[index].syncState = .synced
            database.reviews[index].lastSyncedAt = syncedAt
        }

        try? persist()
    }

    func mergeModerationSnapshot(_ reviews: [InstructorReviewRecord], reports: [InstructorGougeReportRecord], syncedAt: Date) {
        let pendingIDs = Set(reviews.map(\.id))
        let openReportIDs = Set(reports.map(\.id))

        for incoming in reviews {
            if let index = database.reviews.firstIndex(where: { $0.id == incoming.id || $0.remoteID == incoming.remoteID }) {
                database.reviews[index].remoteID = incoming.remoteID ?? incoming.id
                database.reviews[index].instructorName = incoming.instructorName
                database.reviews[index].squadronID = incoming.squadronID
                database.reviews[index].eventName = incoming.eventName
                database.reviews[index].eventKind = incoming.eventKind
                database.reviews[index].chillScore = incoming.chillScore
                database.reviews[index].gradingScore = incoming.gradingScore
                database.reviews[index].reviewText = incoming.reviewText
                database.reviews[index].submittedAt = incoming.submittedAt
                database.reviews[index].status = .pending
                database.reviews[index].lastModifiedAt = incoming.lastModifiedAt
                database.reviews[index].lastSyncedAt = syncedAt
                database.reviews[index].remoteID = incoming.id
                if database.reviews[index].origin == .seed {
                    database.reviews[index].origin = .remote
                }
                if database.reviews[index].origin == .remote {
                    database.reviews[index].syncState = .synced
                }
            } else {
                var record = incoming
                record.origin = .remote
                record.syncState = .synced
                record.lastSyncedAt = syncedAt
                database.reviews.append(record)
            }
        }

        for incoming in reports {
            if let index = database.reports.firstIndex(where: { $0.id == incoming.id || $0.remoteID == incoming.remoteID }) {
                database.reports[index].remoteID = incoming.remoteID ?? incoming.id
                database.reports[index].targetKind = incoming.targetKind
                database.reports[index].instructorID = incoming.instructorID
                database.reports[index].reviewID = incoming.reviewID
                database.reports[index].instructorName = incoming.instructorName
                database.reports[index].squadronID = incoming.squadronID
                database.reports[index].eventName = incoming.eventName
                database.reports[index].eventKind = incoming.eventKind
                database.reports[index].reviewText = incoming.reviewText
                database.reports[index].reasonTitle = incoming.reasonTitle
                database.reports[index].note = incoming.note
                database.reports[index].submittedAt = incoming.submittedAt
                database.reports[index].status = .open
                database.reports[index].lastModifiedAt = incoming.lastModifiedAt
                database.reports[index].lastSyncedAt = syncedAt
                if database.reports[index].origin == .remote {
                    database.reports[index].syncState = .synced
                }
            } else {
                var record = incoming
                record.origin = .remote
                record.syncState = .synced
                record.lastSyncedAt = syncedAt
                database.reports.append(record)
            }
        }

        for index in database.reviews.indices {
            let record = database.reviews[index]
            guard record.status == .pending, record.origin == .remote else { continue }
            guard !pendingIDs.contains(record.id) else { continue }
            database.reviews[index].status = .rejected
            database.reviews[index].lastSyncedAt = syncedAt
        }

        for index in database.reports.indices {
            let record = database.reports[index]
            guard record.status == .open, record.origin == .remote else { continue }
            guard !openReportIDs.contains(record.id) else { continue }
            database.reports[index].status = .resolved
            database.reports[index].lastSyncedAt = syncedAt
        }

        try? persist()
    }

    func setLastSuccessfulSync(at date: Date) {
        database.lastSuccessfulSyncAt = date
        try? persist()
    }

    func lastSuccessfulSyncAt() -> Date? {
        database.lastSuccessfulSyncAt
    }

    func clearAccountScopedData() {
        database.lastSuccessfulSyncAt = nil
        database.reviews.removeAll { $0.origin == .localSubmission || $0.submitterClientID != nil }
        database.reports.removeAll { $0.origin == .localSubmission || $0.submitterClientID != nil }
        try? persist()
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
            status: record.status,
            origin: record.origin,
            syncState: record.syncState,
            submitterClientID: record.submitterClientID
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
            submittedAt: record.submittedAt,
            status: record.status,
            origin: record.origin,
            syncState: record.syncState,
            submitterClientID: record.submitterClientID
        )
    }

    private func migrateSeedData() throws {
        let currentSeedIDs = Set(InstructorReviewSeedData.reviews.map(\.id))
        database.reviews.removeAll { record in
            currentSeedIDs.contains(record.id) || InstructorReviewSeedData.legacyInstructorNames.contains(record.instructorName)
        }
        database.reviews.append(contentsOf: InstructorReviewSeedData.reviews.map(Self.makeSeedRecord(from:)))
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

    private static func makeSeedRecord(from item: InstructorReviewSeedItem) -> InstructorReviewRecord {
        InstructorReviewRecord(
            id: item.id,
            remoteID: item.id,
            instructorName: item.instructorName,
            squadronID: item.squadronID,
            eventName: item.eventName,
            eventKind: item.eventKind,
            chillScore: item.chillScore,
            gradingScore: item.gradingScore,
            reviewText: item.reviewText,
            submittedAt: item.submittedAt,
            status: item.status,
            origin: .seed,
            syncState: .synced,
            lastModifiedAt: item.submittedAt,
            lastSyncedAt: nil,
            submitterClientID: nil
        )
    }
}

typealias SwiftDataInstructorReviewRepository = LocalInstructorReviewRepository

private extension Collection where Element == Int {
    var average: Double {
        guard !isEmpty else { return 0 }
        return Double(reduce(0, +)) / Double(count)
    }
}

extension JSONEncoder {
    static var reviewEncoder: JSONEncoder {
        let encoder = JSONEncoder()
        encoder.dateEncodingStrategy = .iso8601
        encoder.outputFormatting = [.prettyPrinted, .sortedKeys]
        return encoder
    }
}

extension JSONDecoder {
    static var reviewDecoder: JSONDecoder {
        let decoder = JSONDecoder()
        decoder.dateDecodingStrategy = .iso8601
        return decoder
    }
}
