import Combine
import Foundation

@MainActor
final class InstructorReviewStore: ObservableObject, InstructorReviewRepository {
    @Published private(set) var revision = 0
    @Published private(set) var syncStatus: InstructorReviewSyncStatus = .idle
    @Published private(set) var moderatorSessionState: ModeratorSessionState = .signedOut
    @Published private(set) var isRemoteConfigured = false
    @Published private(set) var openCommunitySubmissions: [CommunitySubmissionModerationItem] = []
    @Published private(set) var hasModeratorPermission = false

    private let localRepository: LocalInstructorReviewRepository
    private let remoteService: InstructorReviewRemoteService
    private let clientIdentityStore: AnonymousInstructorReviewClientIdentityStore
    private let connectivityMonitor: InstructorReviewConnectivityMonitor
    private let syncCoordinator: InstructorReviewSyncCoordinator
    private let configurationDefaults: UserDefaults

    private var syncTask: Task<Void, Never>?

    init(
        localRepository: LocalInstructorReviewRepository? = nil,
        remoteService: InstructorReviewRemoteService? = nil,
        clientIdentityStore: AnonymousInstructorReviewClientIdentityStore? = nil,
        connectivityMonitor: InstructorReviewConnectivityMonitor? = nil,
        configurationDefaults: UserDefaults = .standard
    ) {
        let resolvedLocalRepository = localRepository ?? LocalInstructorReviewRepository()
        let resolvedRemoteService = remoteService ?? CloudflareInstructorReviewRemoteService()
        let resolvedClientIdentityStore = clientIdentityStore ?? AnonymousInstructorReviewClientIdentityStore()
        let resolvedConnectivityMonitor = connectivityMonitor ?? InstructorReviewConnectivityMonitor()

        self.localRepository = resolvedLocalRepository
        self.remoteService = resolvedRemoteService
        self.clientIdentityStore = resolvedClientIdentityStore
        self.connectivityMonitor = resolvedConnectivityMonitor
        self.configurationDefaults = configurationDefaults
        self.syncCoordinator = InstructorReviewSyncCoordinator(
            localRepository: resolvedLocalRepository,
            remoteService: resolvedRemoteService
        )
    }

    func configure() {
        _ = InstructorReviewBackendConfiguration.clearBlankOverrides(defaults: configurationDefaults)
        isRemoteConfigured = remoteService.isConfigured
        try? localRepository.seedIfNeeded()

        ModeratorSessionStore().clear()
        refreshModeratorState()

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

    func seedIfNeeded() throws {
        try localRepository.seedIfNeeded()
        revision &+= 1
    }

    func fetchInstructorSummaries(searchText: String) -> [Instructor] {
        localRepository.fetchInstructorSummaries(searchText: searchText)
    }

    func fetchInstructor(id: String) -> Instructor? {
        localRepository.fetchInstructor(id: id)
    }

    func fetchPublishedReviews(for instructorID: String) -> [InstructorReview] {
        localRepository.fetchPublishedReviews(for: instructorID)
    }

    func fetchPendingReviews() -> [InstructorReview] {
        guard canModerate else { return [] }
        return localRepository.fetchPendingReviews()
    }

    func fetchOpenReports() -> [InstructorGougeReport] {
        guard canModerate else { return [] }
        return localRepository.fetchOpenReports()
    }

    func fetchOpenCommunitySubmissions() -> [CommunitySubmissionModerationItem] {
        guard canModerate else { return [] }
        return openCommunitySubmissions
    }

    func fetchInstructorSuggestions(matching query: String) -> [InstructorNameSuggestion] {
        localRepository.fetchInstructorSuggestions(matching: query)
    }

    func fetchSquadrons() -> [Squadron] {
        localRepository.fetchSquadrons()
    }

    func fetchEvents() -> [InstructorReviewEvent] {
        localRepository.fetchEvents()
    }

    func submitReview(_ submission: InstructorReviewSubmission) throws {
        try localRepository.enqueueReviewSubmission(submission, clientID: clientIdentityStore.clientID())
        revision &+= 1
        scheduleSync()
    }

    func submitReport(_ submission: InstructorGougeReportSubmission) throws {
        try localRepository.enqueueReport(submission, clientID: clientIdentityStore.clientID())
        revision &+= 1
        scheduleSync()
    }

    func fetchOwnedReviews() async throws -> [OwnedInstructorReview] {
        guard remoteService.isConfigured else {
            throw InstructorReviewRepositoryError.remoteNotConfigured
        }
        return try await remoteService.fetchOwnedReviews()
    }

    func submitOwnedReviewEdit(reviewID: String, submission: InstructorReviewSubmission) async throws {
        guard remoteService.isConfigured else {
            throw InstructorReviewRepositoryError.remoteNotConfigured
        }
        do {
            try await remoteService.submitReviewEdit(reviewID: reviewID, submission: submission)
            scheduleSync()
            revision &+= 1
        } catch {
            throw mappedBackendError(error)
        }
    }

    func requestOwnedReviewDeletion(reviewID: String) async throws {
        guard remoteService.isConfigured else {
            throw InstructorReviewRepositoryError.remoteNotConfigured
        }
        do {
            try await remoteService.requestReviewDeletion(reviewID: reviewID)
            localRepository.hideOwnedReview(reviewID)
            scheduleSync()
            revision &+= 1
        } catch {
            throw mappedBackendError(error)
        }
    }

    func dismissReport(id: String) async throws {
        let session = try await requireModerationSession()

        do {
            try await remoteService.dismissReport(id: id, session: session)
        } catch {
            throw mappedBackendError(error)
        }
        try await localRepository.dismissReport(id: id)
        scheduleSync()
        revision &+= 1
    }

    func resolveCommunitySubmission(id: String) async throws {
        let session = try await requireModerationSession()

        do {
            try await remoteService.resolveCommunitySubmission(id: id, session: session)
        } catch {
            throw mappedBackendError(error)
        }
        openCommunitySubmissions.removeAll { $0.id == id }
        scheduleSync()
        revision &+= 1
    }

    func dismissCommunitySubmission(id: String) async throws {
        let session = try await requireModerationSession()

        do {
            try await remoteService.dismissCommunitySubmission(id: id, session: session)
        } catch {
            throw mappedBackendError(error)
        }
        openCommunitySubmissions.removeAll { $0.id == id }
        scheduleSync()
        revision &+= 1
    }

    func approveReview(id: String) async throws {
        let session = try await requireModerationSession()

        do {
            try await remoteService.approveSubmission(id: id, session: session)
        } catch {
            throw mappedBackendError(error)
        }
        try await localRepository.approveReview(id: id)
        scheduleSync()
        revision &+= 1
    }

    func rejectReview(id: String) async throws {
        let session = try await requireModerationSession()

        do {
            try await remoteService.rejectSubmission(id: id, session: session)
        } catch {
            throw mappedBackendError(error)
        }
        try await localRepository.rejectReview(id: id)
        scheduleSync()
        revision &+= 1
    }

    func setModeratorPermission(_ isAllowed: Bool) {
        guard hasModeratorPermission != isAllowed else { return }
        hasModeratorPermission = isAllowed
        if !isAllowed {
            openCommunitySubmissions = []
        }
        refreshModeratorState()
        revision &+= 1
        scheduleSync()
    }

    func clearAccountScopedData() {
        localRepository.clearAccountScopedData()
        ModeratorSessionStore().clear()
        openCommunitySubmissions = []
        moderatorSessionState = .signedOut
        revision &+= 1
    }

    func syncIfPossible() async {
        guard remoteService.isConfigured else {
            syncStatus = makeSyncStatus(
                phase: .offline,
                errorMessage: "Instructor review sync backend is not configured. \(remoteService.configurationStatusDetail)"
            )
            return
        }

        syncStatus = makeSyncStatus(phase: .syncing, errorMessage: nil)

        do {
            let summary = try await syncCoordinator.sync(
                clientID: clientIdentityStore.clientID(),
                moderatorSession: nil,
                canFetchModerationQueue: hasModeratorPermission
            )
            openCommunitySubmissions = summary.openCommunitySubmissions
            refreshModeratorState()
            syncStatus = makeSyncStatus(phase: .idle, lastSyncedAt: summary.syncedAt, errorMessage: nil)
            revision &+= 1
        } catch {
            if case InstructorReviewRepositoryError.remoteNotConfigured = error {
                syncStatus = makeSyncStatus(phase: .offline, errorMessage: error.localizedDescription)
            } else if CloudflareBackendErrorClassifier.isConnectivityFailure(error) {
                syncStatus = makeSyncStatus(phase: .offline, errorMessage: error.localizedDescription)
            } else {
                syncStatus = makeSyncStatus(phase: .failed, errorMessage: error.localizedDescription)
            }
            revision &+= 1
        }
    }

    private func scheduleSync() {
        guard remoteService.isConfigured else { return }
        syncTask?.cancel()
        syncTask = Task { [weak self] in
            guard let self else { return }
            await self.syncIfPossible()
        }
    }

    private func requireModerationSession() async throws -> ModeratorSession? {
        guard hasModeratorPermission else {
            moderatorSessionState = .signedOut
            throw InstructorReviewRepositoryError.unauthorized
        }
        return nil
    }

    private func mappedBackendError(_ error: Error) -> Error {
        CloudflareBackendErrorClassifier.isConnectivityFailure(error) ? InstructorReviewRepositoryError.offline : error
    }

    private func refreshModeratorState() {
        if hasModeratorPermission {
            moderatorSessionState = .signedIn(email: "Account Moderator")
        } else {
            moderatorSessionState = .signedOut
        }
    }

    private var canModerate: Bool {
        hasModeratorPermission
    }

    private func makeSyncStatus(
        phase: InstructorReviewSyncPhase,
        lastSyncedAt: Date? = nil,
        errorMessage: String?
    ) -> InstructorReviewSyncStatus {
        InstructorReviewSyncStatus(
            phase: phase,
            lastSyncedAt: lastSyncedAt ?? localRepository.lastSuccessfulSyncAt(),
            errorMessage: errorMessage,
            backendSource: remoteService.configurationSource,
            configurationDetail: remoteService.configurationStatusDetail
        )
    }
}

@MainActor
private final class UnavailableInstructorReviewRepository: InstructorReviewRepository {
    func seedIfNeeded() throws {
        throw InstructorReviewRepositoryError.unavailable
    }

    func fetchInstructorSummaries(searchText: String) -> [Instructor] { [] }
    func fetchInstructor(id: String) -> Instructor? { nil }
    func fetchPublishedReviews(for instructorID: String) -> [InstructorReview] { [] }
    func fetchPendingReviews() -> [InstructorReview] { [] }
    func fetchOpenReports() -> [InstructorGougeReport] { [] }
    func fetchOpenCommunitySubmissions() -> [CommunitySubmissionModerationItem] { [] }
    func fetchInstructorSuggestions(matching query: String) -> [InstructorNameSuggestion] { [] }
    func fetchSquadrons() -> [Squadron] { [] }
    func fetchEvents() -> [InstructorReviewEvent] { [] }

    func submitReview(_ submission: InstructorReviewSubmission) throws {
        throw InstructorReviewRepositoryError.unavailable
    }

    func submitReport(_ submission: InstructorGougeReportSubmission) throws {
        throw InstructorReviewRepositoryError.unavailable
    }

    func dismissReport(id: String) async throws {
        throw InstructorReviewRepositoryError.unavailable
    }

    func resolveCommunitySubmission(id: String) async throws {
        throw InstructorReviewRepositoryError.unavailable
    }

    func dismissCommunitySubmission(id: String) async throws {
        throw InstructorReviewRepositoryError.unavailable
    }

    func approveReview(id: String) async throws {
        throw InstructorReviewRepositoryError.unavailable
    }

    func rejectReview(id: String) async throws {
        throw InstructorReviewRepositoryError.unavailable
    }
}
