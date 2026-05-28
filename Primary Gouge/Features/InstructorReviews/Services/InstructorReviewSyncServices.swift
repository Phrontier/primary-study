import Foundation
import Network
import Security

struct InstructorReviewBackendConfiguration: Hashable {
    let baseURL: URL

    var apiBaseURL: URL {
        baseURL.appending(path: "v1")
    }

    static func load(bundle: Bundle = .main, defaults: UserDefaults = .standard) -> InstructorReviewBackendConfiguration? {
        let rawURL = (
            defaults.string(forKey: "InstructorReviewBackendURL")
            ?? bundle.object(forInfoDictionaryKey: "INSTRUCTOR_REVIEW_BACKEND_URL") as? String
        )?.trimmingCharacters(in: .whitespacesAndNewlines)

        guard
            let rawURL,
            !rawURL.isEmpty,
            let baseURL = URL(string: rawURL)
        else {
            return nil
        }

        return InstructorReviewBackendConfiguration(baseURL: baseURL)
    }
}

final class AnonymousInstructorReviewClientIdentityStore {
    private let defaults: UserDefaults
    private let key: String

    init(defaults: UserDefaults = .standard, key: String = "InstructorReviewAnonymousClientID") {
        self.defaults = defaults
        self.key = key
    }

    func clientID() -> String {
        if let existing = defaults.string(forKey: key), !existing.isEmpty {
            return existing
        }

        let value = UUID().uuidString.lowercased()
        defaults.set(value, forKey: key)
        return value
    }
}

final class ModeratorSessionStore {
    private let service = "com.primarygouge.instructorreviews.moderator"
    private let account = "cloudflare-backend-session"

    func load() -> ModeratorSession? {
        let query: [CFString: Any] = [
            kSecClass: kSecClassGenericPassword,
            kSecAttrService: service,
            kSecAttrAccount: account,
            kSecReturnData: true,
            kSecMatchLimit: kSecMatchLimitOne
        ]

        var item: CFTypeRef?
        let status = SecItemCopyMatching(query as CFDictionary, &item)
        guard status == errSecSuccess, let data = item as? Data else { return nil }
        return try? JSONDecoder.reviewDecoder.decode(ModeratorSession.self, from: data)
    }

    func save(_ session: ModeratorSession) {
        guard let data = try? JSONEncoder.reviewEncoder.encode(session) else { return }

        let baseQuery: [CFString: Any] = [
            kSecClass: kSecClassGenericPassword,
            kSecAttrService: service,
            kSecAttrAccount: account
        ]

        let attributes: [CFString: Any] = [
            kSecValueData: data
        ]

        let status = SecItemUpdate(baseQuery as CFDictionary, attributes as CFDictionary)
        if status == errSecItemNotFound {
            var createQuery = baseQuery
            createQuery[kSecValueData] = data
            SecItemAdd(createQuery as CFDictionary, nil)
        }
    }

    func clear() {
        let query: [CFString: Any] = [
            kSecClass: kSecClassGenericPassword,
            kSecAttrService: service,
            kSecAttrAccount: account
        ]
        SecItemDelete(query as CFDictionary)
    }
}

final class InstructorReviewConnectivityMonitor {
    var onConnectivityChanged: (@MainActor (Bool) -> Void)?

    private let monitor = NWPathMonitor()
    private let queue = DispatchQueue(label: "InstructorReviewConnectivityMonitor")

    init() {
        monitor.pathUpdateHandler = { [weak self] path in
            guard let self else { return }
            let online = path.status == .satisfied
            Task { @MainActor in
                self.onConnectivityChanged?(online)
            }
        }
        monitor.start(queue: queue)
    }

    deinit {
        monitor.cancel()
    }
}

struct RemoteSubmissionStatusSnapshot: Hashable {
    let id: String
    let status: ReviewStatus
    let updatedAt: Date
}

struct RemoteReportStatusSnapshot: Hashable {
    let id: String
    let status: InstructorGougeReportStatus
    let updatedAt: Date
}

struct RemoteModerationQueueSnapshot: Hashable {
    let pendingReviews: [InstructorReviewRecord]
    let openReports: [InstructorGougeReportRecord]
}

protocol InstructorReviewRemoteService {
    var isConfigured: Bool { get }
    func signInModerator(email: String, password: String) async throws -> ModeratorSession
    func refreshModeratorSession(_ session: ModeratorSession) async throws -> ModeratorSession
    func fetchPublishedReviews() async throws -> [InstructorReviewRecord]
    func fetchSubmissionStatuses(for clientID: String) async throws -> [RemoteSubmissionStatusSnapshot]
    func fetchReportStatuses(for clientID: String) async throws -> [RemoteReportStatusSnapshot]
    func submitReview(_ record: InstructorReviewRecord, clientID: String) async throws -> String
    func submitReport(_ record: InstructorGougeReportRecord, clientID: String) async throws -> String
    func fetchModerationQueue(session: ModeratorSession) async throws -> RemoteModerationQueueSnapshot
    func approveSubmission(id: String, session: ModeratorSession) async throws
    func rejectSubmission(id: String, session: ModeratorSession) async throws
    func dismissReport(id: String, session: ModeratorSession) async throws
}

struct InstructorReviewSyncSummary {
    let syncedAt: Date
    let uploadedReviewIDs: [String]
    let uploadedReportIDs: [String]
}

@MainActor
final class InstructorReviewSyncCoordinator {
    private let localRepository: LocalInstructorReviewRepository
    private let remoteService: InstructorReviewRemoteService

    init(localRepository: LocalInstructorReviewRepository, remoteService: InstructorReviewRemoteService) {
        self.localRepository = localRepository
        self.remoteService = remoteService
    }

    func sync(clientID: String, moderatorSession: ModeratorSession?) async throws -> InstructorReviewSyncSummary {
        let syncedAt = Date()

        let published = try await remoteService.fetchPublishedReviews()
        localRepository.upsertPublishedReviews(published, syncedAt: syncedAt)

        let queuedReviews = localRepository.fetchQueuedReviewUploads()
        var uploadedReviewIDs: [String] = []
        for review in queuedReviews {
            do {
                let remoteID = try await remoteService.submitReview(review, clientID: clientID)
                localRepository.markReviewUploaded(localID: review.id, remoteID: remoteID, syncedAt: syncedAt)
                uploadedReviewIDs.append(review.id)
            } catch {
                localRepository.markReviewUploadFailed(localID: review.id)
            }
        }

        let queuedReports = localRepository.fetchQueuedReportUploads()
        var uploadedReportIDs: [String] = []
        for report in queuedReports {
            do {
                let remoteID = try await remoteService.submitReport(report, clientID: clientID)
                localRepository.markReportUploaded(localID: report.id, remoteID: remoteID, syncedAt: syncedAt)
                uploadedReportIDs.append(report.id)
            } catch {
                localRepository.markReportUploadFailed(localID: report.id)
            }
        }

        let submissionStatuses = try await remoteService.fetchSubmissionStatuses(for: clientID)
        localRepository.applySubmissionStatuses(submissionStatuses, syncedAt: syncedAt)

        let reportStatuses = try await remoteService.fetchReportStatuses(for: clientID)
        localRepository.applyReportStatuses(reportStatuses, syncedAt: syncedAt)

        if let moderatorSession {
            let queue = try await remoteService.fetchModerationQueue(session: moderatorSession)
            localRepository.mergeModerationSnapshot(queue.pendingReviews, reports: queue.openReports, syncedAt: syncedAt)
        }

        localRepository.setLastSuccessfulSync(at: syncedAt)
        return InstructorReviewSyncSummary(
            syncedAt: syncedAt,
            uploadedReviewIDs: uploadedReviewIDs,
            uploadedReportIDs: uploadedReportIDs
        )
    }
}

final class CloudflareInstructorReviewRemoteService: InstructorReviewRemoteService {
    private struct ModeratorCredentialsPayload: Encodable {
        let email: String
        let password: String
    }

    private struct RefreshPayload: Encodable {
        let refreshToken: String
    }

    private struct SessionResponse: Decodable {
        let email: String
        let accessToken: String
        let refreshToken: String
        let expiresAt: Date

        private enum CodingKeys: String, CodingKey {
            case email
            case accessToken = "accessToken"
            case refreshToken = "refreshToken"
            case expiresAt = "expiresAt"
        }
    }

    private struct ReviewsResponse: Decodable {
        let reviews: [RemoteReviewRecord]
    }

    private struct SubmissionStatusesResponse: Decodable {
        let statuses: [RemoteSubmissionStatusRecord]
    }

    private struct ReportStatusesResponse: Decodable {
        let statuses: [RemoteReportStatusRecord]
    }

    private struct ModerationQueueResponse: Decodable {
        let pendingReviews: [RemoteReviewRecord]
        let openReports: [RemoteReportRecord]
    }

    private struct CreatedRecordResponse: Decodable {
        let id: String
    }

    private struct RemoteReviewRecord: Codable {
        let id: String
        let instructorName: String
        let squadronID: String
        let eventName: String?
        let eventKind: InstructorReviewEventKind
        let chillScore: Int
        let gradingScore: Int
        let reviewText: String
        let submittedAt: Date
        let status: ReviewStatus
        let submitterClientID: String?
        let updatedAt: Date?

        private enum CodingKeys: String, CodingKey {
            case id
            case instructorName = "instructorName"
            case squadronID = "squadronID"
            case eventName = "eventName"
            case eventKind = "eventKind"
            case chillScore = "chillScore"
            case gradingScore = "gradingScore"
            case reviewText = "reviewText"
            case submittedAt = "submittedAt"
            case status
            case submitterClientID = "submitterClientID"
            case updatedAt = "updatedAt"
        }
    }

    private struct RemoteSubmissionStatusRecord: Decodable {
        let id: String
        let status: ReviewStatus
        let updatedAt: Date

        private enum CodingKeys: String, CodingKey {
            case id
            case status
            case updatedAt = "updatedAt"
        }
    }

    private struct RemoteReportRecord: Codable {
        let id: String
        let targetKind: InstructorGougeReportTargetKind
        let instructorID: String
        let reviewID: String?
        let instructorName: String
        let squadronID: String
        let eventName: String?
        let eventKind: InstructorReviewEventKind?
        let reviewText: String?
        let reasonTitle: String
        let note: String?
        let submittedAt: Date
        let status: InstructorGougeReportStatus
        let submitterClientID: String?
        let updatedAt: Date?

        private enum CodingKeys: String, CodingKey {
            case id
            case targetKind = "targetKind"
            case instructorID = "instructorID"
            case reviewID = "reviewID"
            case instructorName = "instructorName"
            case squadronID = "squadronID"
            case eventName = "eventName"
            case eventKind = "eventKind"
            case reviewText = "reviewText"
            case reasonTitle = "reasonTitle"
            case note
            case submittedAt = "submittedAt"
            case status
            case submitterClientID = "submitterClientID"
            case updatedAt = "updatedAt"
        }
    }

    private struct RemoteReportStatusRecord: Decodable {
        let id: String
        let status: InstructorGougeReportStatus
        let updatedAt: Date

        private enum CodingKeys: String, CodingKey {
            case id
            case status
            case updatedAt = "updatedAt"
        }
    }

    private let configuration: InstructorReviewBackendConfiguration?
    private let session: URLSession

    var isConfigured: Bool { configuration != nil }

    init(configuration: InstructorReviewBackendConfiguration? = InstructorReviewBackendConfiguration.load(), session: URLSession = .shared) {
        self.configuration = configuration
        self.session = session
    }

    func signInModerator(email: String, password: String) async throws -> ModeratorSession {
        let response: SessionResponse = try await send(
            path: "moderator/sign-in",
            method: "POST",
            body: ModeratorCredentialsPayload(email: email, password: password),
            bearerToken: nil
        )
        return ModeratorSession(
            email: response.email,
            accessToken: response.accessToken,
            refreshToken: response.refreshToken,
            expiresAt: response.expiresAt
        )
    }

    func refreshModeratorSession(_ session: ModeratorSession) async throws -> ModeratorSession {
        let response: SessionResponse = try await send(
            path: "moderator/refresh",
            method: "POST",
            body: RefreshPayload(refreshToken: session.refreshToken),
            bearerToken: nil
        )
        return ModeratorSession(
            email: response.email,
            accessToken: response.accessToken,
            refreshToken: response.refreshToken,
            expiresAt: response.expiresAt
        )
    }

    func fetchPublishedReviews() async throws -> [InstructorReviewRecord] {
        let response: ReviewsResponse = try await send(
            path: "reviews/published",
            method: "GET",
            body: Optional<Int>.none as Int?,
            bearerToken: nil
        )
        return response.reviews.map(mapReviewRecord)
    }

    func fetchSubmissionStatuses(for clientID: String) async throws -> [RemoteSubmissionStatusSnapshot] {
        let response: SubmissionStatusesResponse = try await send(
            path: "submissions/statuses",
            method: "GET",
            body: Optional<Int>.none as Int?,
            bearerToken: nil,
            additionalHeaders: submitterHeaders(clientID: clientID)
        )
        return response.statuses.map { RemoteSubmissionStatusSnapshot(id: $0.id, status: $0.status, updatedAt: $0.updatedAt) }
    }

    func fetchReportStatuses(for clientID: String) async throws -> [RemoteReportStatusSnapshot] {
        let response: ReportStatusesResponse = try await send(
            path: "reports/statuses",
            method: "GET",
            body: Optional<Int>.none as Int?,
            bearerToken: nil,
            additionalHeaders: submitterHeaders(clientID: clientID)
        )
        return response.statuses.map { RemoteReportStatusSnapshot(id: $0.id, status: $0.status, updatedAt: $0.updatedAt) }
    }

    func submitReview(_ record: InstructorReviewRecord, clientID: String) async throws -> String {
        let response: CreatedRecordResponse = try await send(
            path: "submissions",
            method: "POST",
            body: reviewPayload(from: record, clientID: clientID),
            bearerToken: nil,
            additionalHeaders: submitterHeaders(clientID: clientID)
        )
        return response.id
    }

    func submitReport(_ record: InstructorGougeReportRecord, clientID: String) async throws -> String {
        let response: CreatedRecordResponse = try await send(
            path: "reports",
            method: "POST",
            body: reportPayload(from: record, clientID: clientID),
            bearerToken: nil,
            additionalHeaders: submitterHeaders(clientID: clientID)
        )
        return response.id
    }

    func fetchModerationQueue(session: ModeratorSession) async throws -> RemoteModerationQueueSnapshot {
        let response: ModerationQueueResponse = try await send(
            path: "moderation/queue",
            method: "GET",
            body: Optional<Int>.none as Int?,
            bearerToken: session.accessToken
        )
        return RemoteModerationQueueSnapshot(
            pendingReviews: response.pendingReviews.map(mapReviewRecord),
            openReports: response.openReports.map(mapReportRecord)
        )
    }

    func approveSubmission(id: String, session: ModeratorSession) async throws {
        try await sendNoContent(
            path: "moderation/submissions/\(id)/approve",
            method: "POST",
            body: Optional<Int>.none as Int?,
            bearerToken: session.accessToken
        )
    }

    func rejectSubmission(id: String, session: ModeratorSession) async throws {
        try await sendNoContent(
            path: "moderation/submissions/\(id)/reject",
            method: "POST",
            body: Optional<Int>.none as Int?,
            bearerToken: session.accessToken
        )
    }

    func dismissReport(id: String, session: ModeratorSession) async throws {
        try await sendNoContent(
            path: "moderation/reports/\(id)/dismiss",
            method: "POST",
            body: Optional<Int>.none as Int?,
            bearerToken: session.accessToken
        )
    }

    private func mapReviewRecord(_ review: RemoteReviewRecord) -> InstructorReviewRecord {
        InstructorReviewRecord(
            id: review.id,
            remoteID: review.id,
            instructorName: review.instructorName,
            squadronID: review.squadronID,
            eventName: review.eventName,
            eventKind: review.eventKind,
            chillScore: review.chillScore,
            gradingScore: review.gradingScore,
            reviewText: review.reviewText,
            submittedAt: review.submittedAt,
            status: review.status,
            origin: review.status == .approved ? .remote : .localSubmission,
            syncState: review.status == .pending ? .uploadedPending : .synced,
            lastModifiedAt: review.updatedAt ?? review.submittedAt,
            lastSyncedAt: Date(),
            submitterClientID: review.submitterClientID
        )
    }

    private func mapReportRecord(_ report: RemoteReportRecord) -> InstructorGougeReportRecord {
        InstructorGougeReportRecord(
            id: report.id,
            remoteID: report.id,
            targetKind: report.targetKind,
            instructorID: report.instructorID,
            reviewID: report.reviewID,
            instructorName: report.instructorName,
            squadronID: report.squadronID,
            eventName: report.eventName,
            eventKind: report.eventKind,
            reviewText: report.reviewText,
            reasonTitle: report.reasonTitle,
            note: report.note,
            submittedAt: report.submittedAt,
            status: report.status,
            origin: .remote,
            syncState: report.status == .open ? .uploadedPending : .synced,
            lastModifiedAt: report.updatedAt ?? report.submittedAt,
            lastSyncedAt: Date(),
            submitterClientID: report.submitterClientID
        )
    }

    private func reviewPayload(from record: InstructorReviewRecord, clientID: String) -> RemoteReviewRecord {
        RemoteReviewRecord(
            id: record.remoteID ?? record.id,
            instructorName: record.instructorName,
            squadronID: record.squadronID,
            eventName: record.eventName,
            eventKind: record.eventKind,
            chillScore: record.chillScore,
            gradingScore: record.gradingScore,
            reviewText: record.reviewText,
            submittedAt: record.submittedAt,
            status: .pending,
            submitterClientID: clientID,
            updatedAt: record.lastModifiedAt
        )
    }

    private func reportPayload(from record: InstructorGougeReportRecord, clientID: String) -> RemoteReportRecord {
        RemoteReportRecord(
            id: record.remoteID ?? record.id,
            targetKind: record.targetKind,
            instructorID: record.instructorID,
            reviewID: record.reviewID,
            instructorName: record.instructorName,
            squadronID: record.squadronID,
            eventName: record.eventName,
            eventKind: record.eventKind,
            reviewText: record.reviewText,
            reasonTitle: record.reasonTitle,
            note: record.note,
            submittedAt: record.submittedAt,
            status: .open,
            submitterClientID: clientID,
            updatedAt: record.lastModifiedAt
        )
    }

    private func requireConfiguration() throws -> InstructorReviewBackendConfiguration {
        guard let configuration else {
            throw InstructorReviewRepositoryError.remoteNotConfigured
        }
        return configuration
    }

    private func endpointURL(for path: String) throws -> URL {
        try requireConfiguration().apiBaseURL.appending(path: path)
    }

    private func send<T: Decodable, Body: Encodable>(
        path: String,
        method: String,
        body: Body?,
        bearerToken: String?,
        additionalHeaders: [String: String] = [:]
    ) async throws -> T {
        var request = URLRequest(url: try endpointURL(for: path))
        request.httpMethod = method
        request.setValue("application/json", forHTTPHeaderField: "Accept")
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")
        if let bearerToken {
            request.setValue("Bearer \(bearerToken)", forHTTPHeaderField: "Authorization")
        }
        additionalHeaders.forEach { request.setValue($1, forHTTPHeaderField: $0) }
        if let body {
            request.httpBody = try JSONEncoder.reviewEncoder.encode(body)
        }

        let (data, response) = try await session.data(for: request)
        try validate(response: response, data: data)
        return try JSONDecoder.reviewDecoder.decode(T.self, from: data)
    }

    private func sendNoContent<Body: Encodable>(
        path: String,
        method: String,
        body: Body?,
        bearerToken: String?,
        additionalHeaders: [String: String] = [:]
    ) async throws {
        var request = URLRequest(url: try endpointURL(for: path))
        request.httpMethod = method
        request.setValue("application/json", forHTTPHeaderField: "Accept")
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")
        if let bearerToken {
            request.setValue("Bearer \(bearerToken)", forHTTPHeaderField: "Authorization")
        }
        additionalHeaders.forEach { request.setValue($1, forHTTPHeaderField: $0) }
        if let body {
            request.httpBody = try JSONEncoder.reviewEncoder.encode(body)
        }

        let (data, response) = try await session.data(for: request)
        try validate(response: response, data: data)
    }

    private func validate(response: URLResponse, data: Data) throws {
        guard let httpResponse = response as? HTTPURLResponse else {
            throw URLError(.badServerResponse)
        }

        guard (200..<300).contains(httpResponse.statusCode) else {
            let message = String(data: data, encoding: .utf8)?.trimmingCharacters(in: .whitespacesAndNewlines)
            throw NSError(
                domain: "InstructorReviewRemoteService",
                code: httpResponse.statusCode,
                userInfo: [NSLocalizedDescriptionKey: message?.isEmpty == false ? message! : "Instructor review backend request failed."]
            )
        }
    }

    private func submitterHeaders(clientID: String) -> [String: String] {
        ["x-submitter-client-id": clientID]
    }
}
