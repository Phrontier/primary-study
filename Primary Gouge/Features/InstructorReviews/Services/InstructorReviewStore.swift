import Combine
import Foundation

@MainActor
final class InstructorReviewStore: ObservableObject, InstructorReviewRepository {
    @Published private(set) var revision = 0
    @Published private(set) var syncStatus: InstructorReviewSyncStatus = .idle
    @Published private(set) var moderatorSessionState: ModeratorSessionState = .signedOut
    @Published private(set) var isRemoteConfigured = false

    private let localRepository: LocalInstructorReviewRepository
    private let remoteService: InstructorReviewRemoteService
    private let sessionStore: ModeratorSessionStore
    private let clientIdentityStore: AnonymousInstructorReviewClientIdentityStore
    private let connectivityMonitor: InstructorReviewConnectivityMonitor
    private let syncCoordinator: InstructorReviewSyncCoordinator

    private var moderatorSession: ModeratorSession?
    private var isOnline = false
    private var syncTask: Task<Void, Never>?

    init(
        localRepository: LocalInstructorReviewRepository? = nil,
        remoteService: InstructorReviewRemoteService? = nil,
        sessionStore: ModeratorSessionStore? = nil,
        clientIdentityStore: AnonymousInstructorReviewClientIdentityStore? = nil,
        connectivityMonitor: InstructorReviewConnectivityMonitor? = nil
    ) {
        let resolvedLocalRepository = localRepository ?? LocalInstructorReviewRepository()
        let resolvedRemoteService = remoteService ?? CloudflareInstructorReviewRemoteService()
        let resolvedSessionStore = sessionStore ?? ModeratorSessionStore()
        let resolvedClientIdentityStore = clientIdentityStore ?? AnonymousInstructorReviewClientIdentityStore()
        let resolvedConnectivityMonitor = connectivityMonitor ?? InstructorReviewConnectivityMonitor()

        self.localRepository = resolvedLocalRepository
        self.remoteService = resolvedRemoteService
        self.sessionStore = resolvedSessionStore
        self.clientIdentityStore = resolvedClientIdentityStore
        self.connectivityMonitor = resolvedConnectivityMonitor
        self.syncCoordinator = InstructorReviewSyncCoordinator(
            localRepository: resolvedLocalRepository,
            remoteService: resolvedRemoteService
        )
    }

    func configure() {
        isRemoteConfigured = remoteService.isConfigured
        try? localRepository.seedIfNeeded()

        moderatorSession = sessionStore.load()
        refreshModeratorState()

        connectivityMonitor.onConnectivityChanged = { [weak self] online in
            guard let self else { return }
            self.isOnline = online
            if online {
                self.scheduleSync()
            } else {
                self.syncStatus = InstructorReviewSyncStatus(
                    phase: .offline,
                    lastSyncedAt: self.localRepository.lastSuccessfulSyncAt(),
                    errorMessage: nil
                )
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
        guard moderatorSession != nil else { return [] }
        return localRepository.fetchPendingReviews()
    }

    func fetchOpenReports() -> [InstructorGougeReport] {
        guard moderatorSession != nil else { return [] }
        return localRepository.fetchOpenReports()
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

    func dismissReport(id: String) async throws {
        let session = try await requireModeratorSession()
        guard isOnline else { throw InstructorReviewRepositoryError.offline }

        try await remoteService.dismissReport(id: id, session: session)
        try await localRepository.dismissReport(id: id)
        scheduleSync()
        revision &+= 1
    }

    func approveReview(id: String) async throws {
        let session = try await requireModeratorSession()
        guard isOnline else { throw InstructorReviewRepositoryError.offline }

        try await remoteService.approveSubmission(id: id, session: session)
        try await localRepository.approveReview(id: id)
        scheduleSync()
        revision &+= 1
    }

    func rejectReview(id: String) async throws {
        let session = try await requireModeratorSession()
        guard isOnline else { throw InstructorReviewRepositoryError.offline }

        try await remoteService.rejectSubmission(id: id, session: session)
        try await localRepository.rejectReview(id: id)
        scheduleSync()
        revision &+= 1
    }

    func signInModerator(email: String, password: String) async throws {
        moderatorSessionState = .signingIn
        let session = try await remoteService.signInModerator(email: email, password: password)
        moderatorSession = session
        sessionStore.save(session)
        refreshModeratorState()
        revision &+= 1
        scheduleSync()
    }

    func signOutModerator() {
        moderatorSession = nil
        sessionStore.clear()
        moderatorSessionState = .signedOut
        revision &+= 1
    }

    func syncIfPossible() async {
        guard remoteService.isConfigured else {
            syncStatus = InstructorReviewSyncStatus(
                phase: .offline,
                lastSyncedAt: localRepository.lastSuccessfulSyncAt(),
                errorMessage: "Instructor review sync backend is not configured."
            )
            return
        }

        guard isOnline else {
            syncStatus = InstructorReviewSyncStatus(
                phase: .offline,
                lastSyncedAt: localRepository.lastSuccessfulSyncAt(),
                errorMessage: nil
            )
            return
        }

        syncStatus = InstructorReviewSyncStatus(
            phase: .syncing,
            lastSyncedAt: localRepository.lastSuccessfulSyncAt(),
            errorMessage: nil
        )

        do {
            let session = try await currentValidModeratorSession()
            let summary = try await syncCoordinator.sync(
                clientID: clientIdentityStore.clientID(),
                moderatorSession: session
            )
            moderatorSession = session
            if let session {
                sessionStore.save(session)
            }
            refreshModeratorState()
            syncStatus = InstructorReviewSyncStatus(
                phase: .idle,
                lastSyncedAt: summary.syncedAt,
                errorMessage: nil
            )
            revision &+= 1
        } catch {
            if case InstructorReviewRepositoryError.remoteNotConfigured = error {
                syncStatus = InstructorReviewSyncStatus(
                    phase: .offline,
                    lastSyncedAt: localRepository.lastSuccessfulSyncAt(),
                    errorMessage: error.localizedDescription
                )
            } else {
                syncStatus = InstructorReviewSyncStatus(
                    phase: .failed,
                    lastSyncedAt: localRepository.lastSuccessfulSyncAt(),
                    errorMessage: error.localizedDescription
                )
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

    private func currentValidModeratorSession() async throws -> ModeratorSession? {
        guard let moderatorSession else { return nil }
        guard moderatorSession.isExpired else { return moderatorSession }

        let refreshed = try await remoteService.refreshModeratorSession(moderatorSession)
        self.moderatorSession = refreshed
        sessionStore.save(refreshed)
        return refreshed
    }

    private func requireModeratorSession() async throws -> ModeratorSession {
        guard let session = try await currentValidModeratorSession() else {
            moderatorSessionState = .signedOut
            throw InstructorReviewRepositoryError.unauthorized
        }
        return session
    }

    private func refreshModeratorState() {
        if let moderatorSession {
            moderatorSessionState = .signedIn(email: moderatorSession.email)
        } else {
            moderatorSessionState = .signedOut
        }
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

    func approveReview(id: String) async throws {
        throw InstructorReviewRepositoryError.unavailable
    }

    func rejectReview(id: String) async throws {
        throw InstructorReviewRepositoryError.unavailable
    }
}
