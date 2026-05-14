import Foundation
import Network
import Security

struct InstructorReviewRemoteConfiguration: Hashable {
    let projectURL: URL
    let publishableKey: String

    var restBaseURL: URL {
        projectURL.appendingPathComponent("rest/v1", isDirectory: false)
    }

    var authBaseURL: URL {
        projectURL.appendingPathComponent("auth/v1", isDirectory: false)
    }

    static func load(bundle: Bundle = .main, defaults: UserDefaults = .standard) -> InstructorReviewRemoteConfiguration? {
        let urlString = (defaults.string(forKey: "InstructorReviewSupabaseURL")
            ?? bundle.object(forInfoDictionaryKey: "SUPABASE_URL") as? String)?
            .trimmingCharacters(in: .whitespacesAndNewlines)
        let publishableKey = (
            defaults.string(forKey: "InstructorReviewSupabasePublishableKey")
            ?? bundle.object(forInfoDictionaryKey: "SUPABASE_PUBLISHABLE_KEY") as? String
            ?? defaults.string(forKey: "InstructorReviewSupabaseAnonKey")
            ?? bundle.object(forInfoDictionaryKey: "SUPABASE_ANON_KEY") as? String
        )?
            .trimmingCharacters(in: .whitespacesAndNewlines)

        guard
            let urlString, !urlString.isEmpty,
            let publishableKey, !publishableKey.isEmpty,
            let projectURL = URL(string: urlString)
        else {
            return nil
        }

        return InstructorReviewRemoteConfiguration(projectURL: projectURL, publishableKey: publishableKey)
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
    private let account = "supabase-session"

    func load() -> ModeratorSession? {
        var query: [CFString: Any] = [
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

final class SupabaseInstructorReviewRemoteService: InstructorReviewRemoteService {
    private struct AuthResponse: Decodable {
        let accessToken: String
        let refreshToken: String
        let expiresIn: TimeInterval
        let user: AuthUser

        struct AuthUser: Decodable {
            let email: String?
        }

        private enum CodingKeys: String, CodingKey {
            case accessToken = "access_token"
            case refreshToken = "refresh_token"
            case expiresIn = "expires_in"
            case user
        }
    }

    private struct RemoteReviewRow: Codable {
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
            case instructorName = "instructor_name"
            case squadronID = "squadron_id"
            case eventName = "event_name"
            case eventKind = "event_kind"
            case chillScore = "chill_score"
            case gradingScore = "grading_score"
            case reviewText = "review_text"
            case submittedAt = "submitted_at"
            case status
            case submitterClientID = "submitter_client_id"
            case updatedAt = "updated_at"
        }
    }

    private struct RemoteReviewStatusRow: Decodable {
        let id: String
        let status: ReviewStatus
        let updatedAt: Date?

        private enum CodingKeys: String, CodingKey {
            case id
            case status
            case updatedAt = "updated_at"
        }
    }

    private struct RemoteReportRow: Codable {
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
            case targetKind = "target_kind"
            case instructorID = "instructor_id"
            case reviewID = "review_id"
            case instructorName = "instructor_name"
            case squadronID = "squadron_id"
            case eventName = "event_name"
            case eventKind = "event_kind"
            case reviewText = "review_text"
            case reasonTitle = "reason_title"
            case note
            case submittedAt = "submitted_at"
            case status
            case submitterClientID = "submitter_client_id"
            case updatedAt = "updated_at"
        }
    }

    private struct RemoteReportStatusRow: Decodable {
        let id: String
        let status: InstructorGougeReportStatus
        let updatedAt: Date?

        private enum CodingKeys: String, CodingKey {
            case id
            case status
            case updatedAt = "updated_at"
        }
    }

    private let configuration: InstructorReviewRemoteConfiguration?
    private let session: URLSession

    var isConfigured: Bool { configuration != nil }

    init(configuration: InstructorReviewRemoteConfiguration? = InstructorReviewRemoteConfiguration.load(), session: URLSession = .shared) {
        self.configuration = configuration
        self.session = session
    }

    func signInModerator(email: String, password: String) async throws -> ModeratorSession {
        let configuration = try requireConfiguration()
        let url = configuration.authBaseURL.appending(path: "token")
        var components = URLComponents(url: url, resolvingAgainstBaseURL: false)
        components?.queryItems = [URLQueryItem(name: "grant_type", value: "password")]

        let body = [
            "email": email,
            "password": password
        ]

        let response: AuthResponse = try await send(
            url: try requireURL(from: components),
            method: "POST",
            body: body,
            bearerToken: configuration.publishableKey
        )

        return ModeratorSession(
            email: response.user.email ?? email,
            accessToken: response.accessToken,
            refreshToken: response.refreshToken,
            expiresAt: Date().addingTimeInterval(response.expiresIn)
        )
    }

    func refreshModeratorSession(_ session: ModeratorSession) async throws -> ModeratorSession {
        let configuration = try requireConfiguration()
        let url = configuration.authBaseURL.appending(path: "token")
        var components = URLComponents(url: url, resolvingAgainstBaseURL: false)
        components?.queryItems = [URLQueryItem(name: "grant_type", value: "refresh_token")]

        let body = [
            "refresh_token": session.refreshToken
        ]

        let response: AuthResponse = try await send(
            url: try requireURL(from: components),
            method: "POST",
            body: body,
            bearerToken: configuration.publishableKey
        )

        return ModeratorSession(
            email: response.user.email ?? session.email,
            accessToken: response.accessToken,
            refreshToken: response.refreshToken,
            expiresAt: Date().addingTimeInterval(response.expiresIn)
        )
    }

    func fetchPublishedReviews() async throws -> [InstructorReviewRecord] {
        let rows: [RemoteReviewRow] = try await fetchReviewRows(
            table: "instructor_reviews",
            filters: [
                URLQueryItem(name: "status", value: "eq.approved"),
                URLQueryItem(name: "order", value: "submitted_at.desc")
            ]
        )

        return rows.map {
            InstructorReviewRecord(
                id: $0.id,
                remoteID: $0.id,
                instructorName: $0.instructorName,
                squadronID: $0.squadronID,
                eventName: $0.eventName,
                eventKind: $0.eventKind,
                chillScore: $0.chillScore,
                gradingScore: $0.gradingScore,
                reviewText: $0.reviewText,
                submittedAt: $0.submittedAt,
                status: .approved,
                origin: .remote,
                syncState: .synced,
                lastModifiedAt: $0.updatedAt ?? $0.submittedAt,
                lastSyncedAt: Date(),
                submitterClientID: $0.submitterClientID
            )
        }
    }

    func fetchSubmissionStatuses(for clientID: String) async throws -> [RemoteSubmissionStatusSnapshot] {
        let rows: [RemoteReviewStatusRow] = try await fetchDecodableRows(
            table: "review_submissions",
            filters: [
                URLQueryItem(name: "submitter_client_id", value: "eq.\(clientID)"),
                URLQueryItem(name: "select", value: "id,status,updated_at")
            ],
            sessionToken: nil,
            headers: submitterHeaders(clientID: clientID)
        )
        return rows.map {
            RemoteSubmissionStatusSnapshot(id: $0.id, status: $0.status, updatedAt: $0.updatedAt ?? Date())
        }
    }

    func fetchReportStatuses(for clientID: String) async throws -> [RemoteReportStatusSnapshot] {
        let rows: [RemoteReportStatusRow] = try await fetchDecodableRows(
            table: "gouge_reports",
            filters: [
                URLQueryItem(name: "submitter_client_id", value: "eq.\(clientID)"),
                URLQueryItem(name: "select", value: "id,status,updated_at")
            ],
            sessionToken: nil,
            headers: submitterHeaders(clientID: clientID)
        )
        return rows.map {
            RemoteReportStatusSnapshot(id: $0.id, status: $0.status, updatedAt: $0.updatedAt ?? Date())
        }
    }

    func submitReview(_ record: InstructorReviewRecord, clientID: String) async throws -> String {
        _ = try await postReviewRow(record, table: "review_submissions", clientID: clientID)
        return record.id
    }

    func submitReport(_ record: InstructorGougeReportRecord, clientID: String) async throws -> String {
        let configuration = try requireConfiguration()
        let url = configuration.restBaseURL.appending(path: "gouge_reports")

        let payload = RemoteReportRow(
            id: record.id,
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

        _ = try await sendNoContent(
            url: url,
            method: "POST",
            body: payload,
            bearerToken: configuration.anonKey,
            preferRepresentation: false
        )
        return record.id
    }

    func fetchModerationQueue(session: ModeratorSession) async throws -> RemoteModerationQueueSnapshot {
        let pendingRows: [RemoteReviewRow] = try await fetchReviewRows(
            table: "review_submissions",
            filters: [
                URLQueryItem(name: "status", value: "eq.pending"),
                URLQueryItem(name: "order", value: "submitted_at.desc")
            ],
            sessionToken: session.accessToken
        )

        let reportRows: [RemoteReportRow] = try await fetchReportRows(
            filters: [
                URLQueryItem(name: "status", value: "eq.open"),
                URLQueryItem(name: "order", value: "submitted_at.desc")
            ],
            sessionToken: session.accessToken
        )

        return RemoteModerationQueueSnapshot(
            pendingReviews: pendingRows.map {
                InstructorReviewRecord(
                    id: $0.id,
                    remoteID: $0.id,
                    instructorName: $0.instructorName,
                    squadronID: $0.squadronID,
                    eventName: $0.eventName,
                    eventKind: $0.eventKind,
                    chillScore: $0.chillScore,
                    gradingScore: $0.gradingScore,
                    reviewText: $0.reviewText,
                    submittedAt: $0.submittedAt,
                    status: .pending,
                    origin: .remote,
                    syncState: .synced,
                    lastModifiedAt: $0.updatedAt ?? $0.submittedAt,
                    lastSyncedAt: Date(),
                    submitterClientID: $0.submitterClientID
                )
            },
            openReports: reportRows.map {
                InstructorGougeReportRecord(
                    id: $0.id,
                    remoteID: $0.id,
                    targetKind: $0.targetKind,
                    instructorID: $0.instructorID,
                    reviewID: $0.reviewID,
                    instructorName: $0.instructorName,
                    squadronID: $0.squadronID,
                    eventName: $0.eventName,
                    eventKind: $0.eventKind,
                    reviewText: $0.reviewText,
                    reasonTitle: $0.reasonTitle,
                    note: $0.note,
                    submittedAt: $0.submittedAt,
                    status: .open,
                    origin: .remote,
                    syncState: .synced,
                    lastModifiedAt: $0.updatedAt ?? $0.submittedAt,
                    lastSyncedAt: Date(),
                    submitterClientID: $0.submitterClientID
                )
            }
        )
    }

    func approveSubmission(id: String, session: ModeratorSession) async throws {
        guard let submission = try await fetchSubmission(id: id, session: session) else {
            throw InstructorReviewRepositoryError.reviewNotFound
        }

        let configuration = try requireConfiguration()
        let reviewsURL = configuration.restBaseURL.appending(path: "instructor_reviews")
        let approvedRow = RemoteReviewRow(
            id: submission.id,
            instructorName: submission.instructorName,
            squadronID: submission.squadronID,
            eventName: submission.eventName,
            eventKind: submission.eventKind,
            chillScore: submission.chillScore,
            gradingScore: submission.gradingScore,
            reviewText: submission.reviewText,
            submittedAt: submission.submittedAt,
            status: .approved,
            submitterClientID: submission.submitterClientID,
            updatedAt: Date()
        )

        _ = try await sendNoContent(
            url: reviewsURL,
            method: "POST",
            body: approvedRow,
            bearerToken: session.accessToken,
            preferRepresentation: false,
            headers: ["Prefer": "resolution=merge-duplicates"]
        )

        try await patchReviewSubmissionStatus(id: id, status: .approved, session: session)
    }

    func rejectSubmission(id: String, session: ModeratorSession) async throws {
        try await patchReviewSubmissionStatus(id: id, status: .rejected, session: session)
        try await deletePublishedReview(id: id, session: session)
        try await resolveReports(reviewID: id, session: session)
    }

    func dismissReport(id: String, session: ModeratorSession) async throws {
        let configuration = try requireConfiguration()
        var components = URLComponents(url: configuration.restBaseURL.appending(path: "gouge_reports"), resolvingAgainstBaseURL: false)
        components?.queryItems = [URLQueryItem(name: "id", value: "eq.\(id)")]
        try await sendNoContent(
            url: try requireURL(from: components),
            method: "PATCH",
            body: ["status": InstructorGougeReportStatus.dismissed.rawValue, "updated_at": ISO8601DateFormatter().string(from: Date())],
            bearerToken: session.accessToken
        )
    }

    private func fetchSubmission(id: String, session: ModeratorSession) async throws -> RemoteReviewRow? {
        let rows: [RemoteReviewRow] = try await fetchReviewRows(
            table: "review_submissions",
            filters: [
                URLQueryItem(name: "id", value: "eq.\(id)"),
                URLQueryItem(name: "limit", value: "1")
            ],
            sessionToken: session.accessToken
        )
        return rows.first
    }

    private func patchReviewSubmissionStatus(id: String, status: ReviewStatus, session: ModeratorSession) async throws {
        let configuration = try requireConfiguration()
        var components = URLComponents(url: configuration.restBaseURL.appending(path: "review_submissions"), resolvingAgainstBaseURL: false)
        components?.queryItems = [URLQueryItem(name: "id", value: "eq.\(id)")]
        try await sendNoContent(
            url: try requireURL(from: components),
            method: "PATCH",
            body: ["status": status.rawValue, "updated_at": ISO8601DateFormatter().string(from: Date())],
            bearerToken: session.accessToken
        )
    }

    private func deletePublishedReview(id: String, session: ModeratorSession) async throws {
        let configuration = try requireConfiguration()
        var components = URLComponents(url: configuration.restBaseURL.appending(path: "instructor_reviews"), resolvingAgainstBaseURL: false)
        components?.queryItems = [URLQueryItem(name: "id", value: "eq.\(id)")]
        try await sendNoContent(
            url: try requireURL(from: components),
            method: "DELETE",
            body: Optional<Int>.none as Int?,
            bearerToken: session.accessToken
        )
    }

    private func resolveReports(reviewID: String, session: ModeratorSession) async throws {
        let configuration = try requireConfiguration()
        var components = URLComponents(url: configuration.restBaseURL.appending(path: "gouge_reports"), resolvingAgainstBaseURL: false)
        components?.queryItems = [
            URLQueryItem(name: "review_id", value: "eq.\(reviewID)"),
            URLQueryItem(name: "status", value: "eq.open")
        ]
        try await sendNoContent(
            url: try requireURL(from: components),
            method: "PATCH",
            body: ["status": InstructorGougeReportStatus.resolved.rawValue, "updated_at": ISO8601DateFormatter().string(from: Date())],
            bearerToken: session.accessToken
        )
    }

    private func fetchReviewRows(table: String, filters: [URLQueryItem], sessionToken: String? = nil) async throws -> [RemoteReviewRow] {
        try await fetchDecodableRows(table: table, filters: filters, sessionToken: sessionToken)
    }

    private func fetchReportRows(filters: [URLQueryItem], sessionToken: String?) async throws -> [RemoteReportRow] {
        try await fetchDecodableRows(table: "gouge_reports", filters: filters, sessionToken: sessionToken)
    }

    private func fetchDecodableRows<T: Decodable>(table: String, filters: [URLQueryItem], sessionToken: String?) async throws -> [T] {
        let configuration = try requireConfiguration()
        var components = URLComponents(url: configuration.restBaseURL.appending(path: table), resolvingAgainstBaseURL: false)
        var queryItems = filters
        if !queryItems.contains(where: { $0.name == "select" }) {
            queryItems.insert(URLQueryItem(name: "select", value: "*"), at: 0)
        }
        components?.queryItems = queryItems
        return try await send(
            url: try requireURL(from: components),
            method: "GET",
            body: Optional<Int>.none as Int?,
            bearerToken: sessionToken ?? configuration.anonKey
        )
    }

    private func postReviewRow(_ record: InstructorReviewRecord, table: String, clientID: String) async throws -> String {
        let configuration = try requireConfiguration()
        let url = configuration.restBaseURL.appending(path: table)

        let payload = RemoteReviewRow(
            id: record.remoteID ?? record.id,
            instructorName: record.instructorName,
            squadronID: record.squadronID,
            eventName: record.eventName,
            eventKind: record.eventKind,
            chillScore: record.chillScore,
            gradingScore: record.gradingScore,
            reviewText: record.reviewText,
            submittedAt: record.submittedAt,
            status: record.status,
            submitterClientID: clientID,
            updatedAt: record.lastModifiedAt
        )

        _ = try await sendNoContent(
            url: url,
            method: "POST",
            body: payload,
            bearerToken: configuration.anonKey,
            preferRepresentation: false
        )
        return payload.id
    }

    private func requireConfiguration() throws -> InstructorReviewRemoteConfiguration {
        guard let configuration else {
            throw InstructorReviewRepositoryError.remoteNotConfigured
        }
        return configuration
    }

    private func requireURL(from components: URLComponents?) throws -> URL {
        guard let url = components?.url else {
            throw URLError(.badURL)
        }
        return url
    }

    private func send<T: Decodable, Body: Encodable>(
        url: URL,
        method: String,
        body: Body?,
        bearerToken: String,
        headers: [String: String] = [:]
    ) async throws -> T {
        var request = URLRequest(url: url)
        request.httpMethod = method
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")
        request.setValue("application/json", forHTTPHeaderField: "Accept")
        request.setValue(try requireConfiguration().anonKey, forHTTPHeaderField: "apikey")
        request.setValue("Bearer \(bearerToken)", forHTTPHeaderField: "Authorization")
        headers.forEach { request.setValue($1, forHTTPHeaderField: $0) }
        if let body {
            request.httpBody = try JSONEncoder.reviewEncoder.encode(body)
        }

        let (data, response) = try await session.data(for: request)
        try validate(response: response, data: data)
        return try JSONDecoder.reviewDecoder.decode(T.self, from: data)
    }

    private func sendNoContent<Body: Encodable>(
        url: URL,
        method: String,
        body: Body?,
        bearerToken: String,
        preferRepresentation: Bool = true,
        headers: [String: String] = [:]
    ) async throws {
        var request = URLRequest(url: url)
        request.httpMethod = method
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")
        request.setValue(preferRepresentation ? "return=representation" : "return=minimal", forHTTPHeaderField: "Prefer")
        request.setValue(try requireConfiguration().anonKey, forHTTPHeaderField: "apikey")
        request.setValue("Bearer \(bearerToken)", forHTTPHeaderField: "Authorization")
        headers.forEach { request.setValue($1, forHTTPHeaderField: $0) }
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
            let message = String(data: data, encoding: .utf8)
            throw NSError(
                domain: "InstructorReviewRemoteService",
                code: httpResponse.statusCode,
                userInfo: [NSLocalizedDescriptionKey: message?.isEmpty == false ? message! : "Supabase request failed."]
            )
        }
    }
}
