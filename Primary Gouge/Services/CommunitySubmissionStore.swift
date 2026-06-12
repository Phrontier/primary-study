import Combine
import Foundation

enum CommunitySubmissionStoreError: LocalizedError {
    case invalidSummary
    case invalidMessage
    case invalidEmail
    case remoteNotConfigured
    case offline

    var errorDescription: String? {
        switch self {
        case .invalidSummary:
            return "Add a short headline before sending."
        case .invalidMessage:
            return "Add a little more detail before sending."
        case .invalidEmail:
            return "That email address does not look valid."
        case .remoteNotConfigured:
            return "The Cloudflare submission backend is not configured yet."
        case .offline:
            return "This action needs a network connection."
        }
    }
}

protocol CommunitySubmissionRemoteService {
    var isConfigured: Bool { get }
    var configurationSource: InstructorReviewBackendSource { get }
    var configurationStatusDetail: String { get }

    func submit(_ record: CommunitySubmissionRecord, clientID: String) async throws -> String
    func fetchStatuses(for clientID: String) async throws -> [CommunitySubmissionStatusSnapshot]
}

@MainActor
final class CommunitySubmissionStore: ObservableObject {
    @Published private(set) var revision = 0
    @Published private(set) var syncStatus: CommunitySubmissionSyncStatus = .idle
    @Published private(set) var isRemoteConfigured = false

    private let localStore: LocalCommunitySubmissionRepository
    private let remoteService: CommunitySubmissionRemoteService
    private let clientIdentityStore: AnonymousCloudflareClientIdentityStore
    private let connectivityMonitor: CloudflareConnectivityMonitor
    private let configurationDefaults: UserDefaults

    private var syncTask: Task<Void, Never>?

    init(
        localStore: LocalCommunitySubmissionRepository? = nil,
        remoteService: CommunitySubmissionRemoteService? = nil,
        clientIdentityStore: AnonymousCloudflareClientIdentityStore? = nil,
        connectivityMonitor: CloudflareConnectivityMonitor? = nil,
        configurationDefaults: UserDefaults = .standard
    ) {
        self.localStore = localStore ?? LocalCommunitySubmissionRepository()
        self.remoteService = remoteService ?? CloudflareCommunitySubmissionRemoteService()
        self.clientIdentityStore = clientIdentityStore ?? AnonymousCloudflareClientIdentityStore()
        self.connectivityMonitor = connectivityMonitor ?? CloudflareConnectivityMonitor()
        self.configurationDefaults = configurationDefaults
    }

    func configure() {
        _ = CloudflareBackendConfiguration.clearBlankOverrides(defaults: configurationDefaults)
        isRemoteConfigured = remoteService.isConfigured
        syncStatus = makeSyncStatus(
            phase: remoteService.isConfigured ? .idle : .offline,
            errorMessage: remoteService.isConfigured ? nil : "Community submission backend is not configured. \(remoteService.configurationStatusDetail)"
        )

        connectivityMonitor.onConnectivityChanged = { [weak self] online in
            guard let self else { return }
            if online {
                self.scheduleSync()
            } else {
                self.syncStatus = self.makeSyncStatus(phase: .offline, errorMessage: nil)
            }
        }

        revision &+= 1
        scheduleSync()
    }

    func draft(for category: CommunitySubmissionCategory) -> CommunitySubmissionDraft {
        localStore.draft(for: category)
    }

    func saveDraft(_ draft: CommunitySubmissionDraft, for category: CommunitySubmissionCategory) {
        localStore.saveDraft(draft, for: category)
        revision &+= 1
    }

    func clearDraft(for category: CommunitySubmissionCategory) {
        localStore.clearDraft(for: category)
        revision &+= 1
    }

    func submissions(for category: CommunitySubmissionCategory, limit: Int? = nil) -> [CommunitySubmissionRecord] {
        localStore.fetchSubmissions(category: category, limit: limit)
    }

    @discardableResult
    func submit(
        category: CommunitySubmissionCategory,
        draft: CommunitySubmissionDraft,
        lockedTarget: CommunitySubmissionDraft? = nil
    ) throws -> CommunitySubmissionRecord {
        let trimmedSummary = draft.trimmedSummary
        let trimmedMessage = draft.trimmedMessage

        guard trimmedSummary.count >= 4 else {
            throw CommunitySubmissionStoreError.invalidSummary
        }

        guard trimmedMessage.count >= 12 else {
            throw CommunitySubmissionStoreError.invalidMessage
        }

        let contactEmail = try normalizedEmail(from: draft.trimmedContactEmail)
        let resolvedTarget = lockedTarget ?? draft

        let version = Bundle.main.object(forInfoDictionaryKey: "CFBundleShortVersionString") as? String ?? "Unknown"
        let build = Bundle.main.object(forInfoDictionaryKey: "CFBundleVersion") as? String

        let record = CommunitySubmissionRecord(
            category: category,
            summary: trimmedSummary,
            message: trimmedMessage,
            contactEmail: contactEmail,
            targetKind: resolvedTarget.targetKind,
            targetID: resolvedTarget.normalizedTargetID,
            targetTitle: resolvedTarget.normalizedTargetTitle,
            targetContext: resolvedTarget.normalizedTargetContext,
            appVersion: version,
            buildNumber: build,
            submitterClientID: clientIdentityStore.clientID()
        )

        localStore.enqueue(record)
        localStore.clearDraft(for: category)
        revision &+= 1
        scheduleSync()
        return record
    }

    func syncIfPossible() async {
        guard remoteService.isConfigured else {
            syncStatus = makeSyncStatus(
                phase: .offline,
                errorMessage: "Community submission backend is not configured. \(remoteService.configurationStatusDetail)"
            )
            return
        }

        syncStatus = makeSyncStatus(phase: .syncing, errorMessage: nil)

        let syncedAt = Date()
        let clientID = clientIdentityStore.clientID()

        do {
            let queuedUploads = localStore.fetchQueuedUploads()
            for record in queuedUploads {
                do {
                    let remoteID = try await remoteService.submit(record, clientID: clientID)
                    localStore.markUploaded(localID: record.id, remoteID: remoteID, syncedAt: syncedAt)
                } catch {
                    localStore.markUploadFailed(localID: record.id, message: error.localizedDescription)
                }
            }

            let statuses = try await remoteService.fetchStatuses(for: clientID)
            localStore.applyStatuses(statuses, syncedAt: syncedAt)
            localStore.setLastSuccessfulSync(at: syncedAt)

            syncStatus = makeSyncStatus(phase: .idle, lastSyncedAt: syncedAt, errorMessage: nil)
            revision &+= 1
        } catch {
            syncStatus = makeSyncStatus(
                phase: CloudflareBackendErrorClassifier.isConnectivityFailure(error) ? .offline : .failed,
                errorMessage: error.localizedDescription
            )
            revision &+= 1
        }
    }

    func clearLocalAccountData() {
        localStore.clearAll()
        revision &+= 1
    }

    private func scheduleSync() {
        guard remoteService.isConfigured else { return }
        syncTask?.cancel()
        syncTask = Task { [weak self] in
            guard let self else { return }
            await self.syncIfPossible()
        }
    }

    private func normalizedEmail(from value: String) throws -> String? {
        guard !value.isEmpty else { return nil }
        guard value.contains("@"), value.contains(".") else {
            throw CommunitySubmissionStoreError.invalidEmail
        }
        return value
    }

    private func makeSyncStatus(
        phase: InstructorReviewSyncPhase,
        lastSyncedAt: Date? = nil,
        errorMessage: String?
    ) -> CommunitySubmissionSyncStatus {
        CommunitySubmissionSyncStatus(
            phase: phase,
            lastSyncedAt: lastSyncedAt ?? localStore.lastSuccessfulSyncAt(),
            errorMessage: errorMessage,
            backendSource: remoteService.configurationSource,
            configurationDetail: remoteService.configurationStatusDetail
        )
    }
}

@MainActor
final class LocalCommunitySubmissionRepository {
    private struct CommunitySubmissionDatabase: Codable {
        var submissions: [CommunitySubmissionRecord] = []
        var drafts: [String: CommunitySubmissionDraft] = [:]
        var lastSuccessfulSyncAt: Date?
    }

    private let persistenceURL: URL
    private var database: CommunitySubmissionDatabase

    init(persistenceURL: URL? = nil) {
        self.persistenceURL = persistenceURL ?? Self.defaultPersistenceURL()
        self.database = Self.loadDatabase(from: self.persistenceURL)
    }

    func draft(for category: CommunitySubmissionCategory) -> CommunitySubmissionDraft {
        database.drafts[category.rawValue] ?? CommunitySubmissionDraft()
    }

    func saveDraft(_ draft: CommunitySubmissionDraft, for category: CommunitySubmissionCategory) {
        database.drafts[category.rawValue] = draft
        persist()
    }

    func clearDraft(for category: CommunitySubmissionCategory) {
        database.drafts.removeValue(forKey: category.rawValue)
        persist()
    }

    func enqueue(_ record: CommunitySubmissionRecord) {
        database.submissions.removeAll { $0.id == record.id }
        database.submissions.append(record)
        sortSubmissions()
        persist()
    }

    func fetchSubmissions(category: CommunitySubmissionCategory, limit: Int? = nil) -> [CommunitySubmissionRecord] {
        let filtered = database.submissions
            .filter { $0.category == category }
            .sorted { $0.submittedAt > $1.submittedAt }

        if let limit {
            return Array(filtered.prefix(limit))
        }

        return filtered
    }

    func fetchQueuedUploads() -> [CommunitySubmissionRecord] {
        database.submissions
            .filter { $0.syncState == .queuedUpload || $0.syncState == .failed }
            .sorted { $0.submittedAt < $1.submittedAt }
    }

    func markUploaded(localID: String, remoteID _: String, syncedAt: Date) {
        updateRecord(id: localID) { record in
            record.syncState = .uploadedOpen
            record.status = .open
            record.lastSyncedAt = syncedAt
            record.lastErrorMessage = nil
        }
    }

    func markUploadFailed(localID: String, message: String) {
        updateRecord(id: localID) { record in
            record.syncState = .failed
            record.lastErrorMessage = message
            record.lastModifiedAt = .now
        }
    }

    func applyStatuses(_ statuses: [CommunitySubmissionStatusSnapshot], syncedAt: Date) {
        guard !statuses.isEmpty else { return }
        let statusMap = Dictionary(uniqueKeysWithValues: statuses.map { ($0.id, $0) })

        var didMutate = false
        for index in database.submissions.indices {
            guard let status = statusMap[database.submissions[index].id] else { continue }
            database.submissions[index].status = status.status
            database.submissions[index].lastSyncedAt = syncedAt
            database.submissions[index].lastModifiedAt = status.updatedAt
            database.submissions[index].lastErrorMessage = nil
            database.submissions[index].syncState = status.status == .open ? .uploadedOpen : .synced
            didMutate = true
        }

        if didMutate {
            sortSubmissions()
            persist()
        }
    }

    func setLastSuccessfulSync(at date: Date) {
        database.lastSuccessfulSyncAt = date
        persist()
    }

    func lastSuccessfulSyncAt() -> Date? {
        database.lastSuccessfulSyncAt
    }

    func clearAll() {
        database = CommunitySubmissionDatabase()
        persist()
    }

    private func updateRecord(id: String, mutate: (inout CommunitySubmissionRecord) -> Void) {
        guard let index = database.submissions.firstIndex(where: { $0.id == id }) else { return }
        mutate(&database.submissions[index])
        sortSubmissions()
        persist()
    }

    private func sortSubmissions() {
        database.submissions.sort { lhs, rhs in
            if lhs.submittedAt == rhs.submittedAt {
                return lhs.lastModifiedAt > rhs.lastModifiedAt
            }
            return lhs.submittedAt > rhs.submittedAt
        }
    }

    private func persist() {
        do {
            let directory = persistenceURL.deletingLastPathComponent()
            try FileManager.default.createDirectory(at: directory, withIntermediateDirectories: true)
            let data = try JSONEncoder.reviewEncoder.encode(database)
            try data.write(to: persistenceURL, options: .atomic)
        } catch {
            assertionFailure("Failed to persist community submissions: \(error)")
        }
    }

    private static func defaultPersistenceURL() -> URL {
        let baseURL = FileManager.default.urls(for: .applicationSupportDirectory, in: .userDomainMask).first
            ?? FileManager.default.temporaryDirectory
        return baseURL
            .appendingPathComponent("PrimaryGouge", isDirectory: true)
            .appendingPathComponent("community-submissions.json")
    }

    private static func loadDatabase(from url: URL) -> CommunitySubmissionDatabase {
        guard
            let data = try? Data(contentsOf: url),
            let database = try? JSONDecoder.reviewDecoder.decode(CommunitySubmissionDatabase.self, from: data)
        else {
            return CommunitySubmissionDatabase()
        }

        return database
    }
}

final class CloudflareCommunitySubmissionRemoteService: CommunitySubmissionRemoteService {
    private struct CreatedRecordResponse: Decodable {
        let id: String
    }

    private struct StatusesResponse: Decodable {
        let statuses: [RemoteStatusRecord]
    }

    private struct RemoteStatusRecord: Decodable {
        let id: String
        let status: CommunitySubmissionStatus
        let updatedAt: Date
    }

    private struct RemoteSubmissionRecord: Codable {
        let id: String
        let category: CommunitySubmissionCategory
        let summary: String
        let message: String
        let contactEmail: String?
        let targetKind: CommunitySubmissionTargetKind?
        let targetID: String?
        let targetTitle: String?
        let targetContext: String?
        let appVersion: String
        let buildNumber: String?
        let platform: String
        let submittedAt: Date
        let status: CommunitySubmissionStatus
        let submitterClientID: String?
        let updatedAt: Date?
    }

    private let configuration: CloudflareBackendConfiguration?
    private let session: URLSession

    var isConfigured: Bool { configuration != nil }
    var configurationSource: InstructorReviewBackendSource { configuration?.source ?? .unavailable }
    var configurationStatusDetail: String { configuration?.statusDetail ?? "No valid backend URL found in local override, bundled settings, or production defaults." }

    init(configuration: CloudflareBackendConfiguration? = CloudflareBackendConfiguration.load(), session: URLSession = .shared) {
        self.configuration = configuration
        self.session = session
    }

    func submit(_ record: CommunitySubmissionRecord, clientID: String) async throws -> String {
        let response: CreatedRecordResponse = try await send(
            path: "community/submissions",
            method: "POST",
            body: payload(from: record, clientID: clientID),
            additionalHeaders: submitterHeaders(clientID: clientID)
        )
        return response.id
    }

    func fetchStatuses(for clientID: String) async throws -> [CommunitySubmissionStatusSnapshot] {
        let response: StatusesResponse = try await send(
            path: "community/submissions/statuses",
            method: "GET",
            body: Optional<Int>.none as Int?,
            additionalHeaders: submitterHeaders(clientID: clientID)
        )

        return response.statuses.map {
            CommunitySubmissionStatusSnapshot(id: $0.id, status: $0.status, updatedAt: $0.updatedAt)
        }
    }

    private func payload(from record: CommunitySubmissionRecord, clientID: String) -> RemoteSubmissionRecord {
        RemoteSubmissionRecord(
            id: record.id,
            category: record.category,
            summary: record.summary,
            message: record.message,
            contactEmail: record.contactEmail,
            targetKind: record.targetKind,
            targetID: record.targetID,
            targetTitle: record.targetTitle,
            targetContext: record.targetContext,
            appVersion: record.appVersion,
            buildNumber: record.buildNumber,
            platform: record.platform,
            submittedAt: record.submittedAt,
            status: .open,
            submitterClientID: clientID,
            updatedAt: record.lastModifiedAt
        )
    }

    private func endpointURL(for path: String) throws -> URL {
        guard let configuration else {
            throw CommunitySubmissionStoreError.remoteNotConfigured
        }
        return configuration.apiBaseURL.appending(path: path)
    }

    private func send<T: Decodable, Body: Encodable>(
        path: String,
        method: String,
        body: Body?,
        additionalHeaders: [String: String] = [:]
    ) async throws -> T {
        var request = URLRequest(url: try endpointURL(for: path))
        request.httpMethod = method
        request.setValue("application/json", forHTTPHeaderField: "Accept")
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")
        if let authorization = await CloudflareAuthenticationContext.shared.authorizationHeader() {
            request.setValue(authorization, forHTTPHeaderField: "Authorization")
        }
        additionalHeaders.forEach { request.setValue($1, forHTTPHeaderField: $0) }

        if let body {
            request.httpBody = try JSONEncoder.reviewEncoder.encode(body)
        }

        let (data, response) = try await session.data(for: request)
        try validate(response: response, data: data)
        return try JSONDecoder.reviewDecoder.decode(T.self, from: data)
    }

    private func validate(response: URLResponse, data: Data) throws {
        guard let httpResponse = response as? HTTPURLResponse else {
            throw URLError(.badServerResponse)
        }

        guard (200..<300).contains(httpResponse.statusCode) else {
            let message = String(data: data, encoding: .utf8)?.trimmingCharacters(in: .whitespacesAndNewlines)
            throw NSError(
                domain: "CommunitySubmissionRemoteService",
                code: httpResponse.statusCode,
                userInfo: [NSLocalizedDescriptionKey: message?.isEmpty == false ? message! : "Community submission backend request failed."]
            )
        }
    }

    private func submitterHeaders(clientID: String) -> [String: String] {
        ["x-submitter-client-id": clientID]
    }
}
