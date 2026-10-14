import Foundation
import Combine
import Security

enum AccountStoreError: LocalizedError {
    case backendNotConfigured
    case invalidAppleCredential
    case missingSession
    case requestFailed(statusCode: Int, message: String)

    var errorDescription: String? {
        switch self {
        case .backendNotConfigured:
            return "The account server is not configured yet."
        case .invalidAppleCredential:
            return "Apple did not return a usable sign-in credential."
        case .missingSession:
            return "Sign in again to continue."
        case .requestFailed(_, let message):
            return message
        }
    }

    var isAuthenticationFailure: Bool {
        if case .requestFailed(let statusCode, _) = self {
            return statusCode == 401 || statusCode == 403
        }
        return false
    }
}

actor CloudflareAuthenticationContext {
    static let shared = CloudflareAuthenticationContext()

    private var accessToken: String?
    private var tokenProvider: ((String?, Bool) async throws -> String)?
    private var revision = UUID()
    private var accountID: String?

    func configureTokenProvider(_ provider: @escaping (String?, Bool) async throws -> String) { tokenProvider = provider }

    func data(for request: URLRequest, session: URLSession) async throws -> (Data, URLResponse) {
        guard let header = request.value(forHTTPHeaderField: "Authorization"),
              header == accessToken.map({ "Bearer \($0)" }), let provider = tokenProvider else {
            return try await session.data(for: request)
        }
        let context = revision
        var authorized = request
        authorized.setValue("Bearer \(try await provider(accountID, false))", forHTTPHeaderField: "Authorization")
        guard context == revision else { throw AccountStoreError.missingSession }
        var result = try await session.data(for: authorized)
        guard context == revision else { throw AccountStoreError.missingSession }
        if (result.1 as? HTTPURLResponse)?.statusCode == 401 {
            authorized.setValue("Bearer \(try await provider(accountID, true))", forHTTPHeaderField: "Authorization")
            guard context == revision else { throw AccountStoreError.missingSession }
            result = try await session.data(for: authorized)
            guard context == revision else { throw AccountStoreError.missingSession }
        }
        return result
    }

    func update(accessToken: String?, userID: String? = nil) {
        if accessToken == nil || accountID != userID { revision = UUID() }
        accountID = userID
        self.accessToken = accessToken
    }

    func authorizationHeader() -> String? {
        guard let accessToken, !accessToken.isEmpty else { return nil }
        return "Bearer \(accessToken)"
    }
}

@MainActor
final class AccountStore: ObservableObject {
    @Published private(set) var phase: AccountPhase = .loading
    @Published private(set) var session: AccountSession?
    @Published private(set) var isWorking = false
    @Published var errorMessage: String?

    var profile: AccountProfile? { session?.profile }
    var isSignedIn: Bool { session != nil && phase == .signedIn }
    var profileComplete: Bool { profile?.profileComplete == true }

    var localDataResetHandler: (() -> Void)?
    var accountDeletedHandler: ((String) -> Void)?

    private let keychainStore: AccountKeychainSessionStore
    private let remoteClient: SupabaseAccountRemoteClient
    private let accountLinkedDataClient: AccountLinkedDataDeleting
    private var didConfigure = false
    private var sessionGeneration = UUID()
    private var refreshTask: Task<AccountSession, Error>?

    init(
        keychainStore: AccountKeychainSessionStore? = nil,
        remoteClient: SupabaseAccountRemoteClient? = nil,
        accountLinkedDataClient: AccountLinkedDataDeleting? = nil
    ) {
        self.keychainStore = keychainStore ?? AccountKeychainSessionStore()
        self.remoteClient = remoteClient ?? SupabaseAccountRemoteClient()
        self.accountLinkedDataClient = accountLinkedDataClient ?? CloudflareAccountDataClient()
    }

    func configure() async {
        guard !didConfigure else { return }
        didConfigure = true
        await CloudflareAuthenticationContext.shared.configureTokenProvider { [weak self] id, force in
            guard let self else { throw AccountStoreError.missingSession }
            return try await self.validAccessToken(for: id.flatMap(UUID.init(uuidString:)), forceRefresh: force)
        }

        if AppLaunchEnvironment.usesSignedOutUITestAccount {
            clearLocalSession()
            return
        }

        if AppLaunchEnvironment.usesSignedInUITestAccount ||
            AppLaunchEnvironment.usesFreeUITestAccount ||
            AppLaunchEnvironment.usesModeratorUITestAccount {
            applySession(Self.uiTestSession)
            return
        }

        if let storedSession = keychainStore.load() {
            applySession(storedSession, restoringCachedSession: true)
            await refreshCachedSessionIfPossible()
        } else {
            phase = .signedOut
            await CloudflareAuthenticationContext.shared.update(accessToken: nil)
        }
    }

    func registerWithEmail(email: String, password: String, displayName: String?) async throws {
        try await perform {
            if let session = try await remoteClient.registerWithEmail(
                email: email,
                password: password,
                displayName: displayName
            ) {
                applySession(session)
            }
        }
    }

    func verifyEmail(email: String, code: String) async throws {
        try await perform {
            let session = try await remoteClient.verifyEmail(email: email, code: code)
            applySession(session)
        }
    }

    func signInWithEmail(email: String, password: String) async throws {
        try await perform {
            let session = try await remoteClient.signInWithEmail(email: email, password: password)
            applySession(session)
        }
    }

    func requestPasswordReset(email: String) async throws {
        try await perform {
            try await remoteClient.requestPasswordReset(email: email)
        }
    }

    func confirmPasswordReset(email: String, code: String, newPassword: String) async throws {
        try await perform {
            let session = try await remoteClient.confirmPasswordReset(
                email: email,
                code: code,
                newPassword: newPassword
            )
            applySession(session)
        }
    }

    func signInWithApple(identityToken: String, authorizationCode: String?, displayName: String?, email: String?, nonce: String?) async throws {
        try await perform {
            let session = try await remoteClient.signInWithApple(
                identityToken: identityToken,
                authorizationCode: authorizationCode,
                displayName: displayName,
                email: email,
                nonce: nonce
            )
            applySession(session)
        }
    }

    func refreshProfile() async {
        guard let id = session?.profile.id else { return }
        do {
            let accessToken = try await validAccessToken()
            let profile = try await remoteClient.fetchProfile(accessToken: accessToken)
            guard session?.profile.id == id else { return }
            updateCachedProfile(profile)
        } catch {
            errorMessage = error.localizedDescription
        }
    }

    func updateProfile(displayName: String?, squadronID: String, syllabusID: SyllabusTrack) async throws {
        try await perform {
            let context = sessionGeneration
            let accessToken = try await validAccessToken()
            let profile = try await remoteClient.updateProfile(
                accessToken: accessToken,
                displayName: displayName,
                squadronID: squadronID,
                syllabusID: syllabusID
            )
            guard sessionGeneration == context else { throw AccountStoreError.missingSession }
            updateCachedProfile(profile)
        }
    }

    func validAccessToken(for expectedUserID: UUID? = nil, forceRefresh: Bool = false) async throws -> String {
        guard let session, expectedUserID == nil || UUID(uuidString: session.profile.id) == expectedUserID else {
            throw AccountStoreError.missingSession
        }
        if forceRefresh || session.expiresAt <= Date.now.addingTimeInterval(60) {
            try await refreshSession()
        }
        guard let current = self.session, current.profile.id == session.profile.id else { throw AccountStoreError.missingSession }
        return current.accessToken
    }

    func refreshSession() async throws {
        guard let current = session else { throw AccountStoreError.missingSession }
        let context = sessionGeneration
        if refreshTask == nil {
            refreshTask = Task { [remoteClient] in try await remoteClient.refresh(refreshToken: current.refreshToken) }
        }
        guard let task = refreshTask else { throw AccountStoreError.missingSession }
        defer { if sessionGeneration == context { refreshTask = nil } }
        let refreshed = try await task.value
        guard sessionGeneration == context, session?.profile.id == current.profile.id else { throw AccountStoreError.missingSession }
        applySession(refreshed)
    }

    func signOut() {
        let accessToken = session?.accessToken
        clearLocalSession()

        if let accessToken {
            Task {
                try? await remoteClient.signOut(accessToken: accessToken)
            }
        }
    }

    func deleteAccount(appleAuthorizationCode: String? = nil) async throws {
        try await perform {
            let context = sessionGeneration
            let accessToken = try await validAccessToken()
            let deletingUserID = session?.profile.id
            // Delete account-linked user-generated content first. If this step
            // fails, the Supabase account remains available so the operation
            // can be retried instead of orphaning reviews or submissions.
            try await accountLinkedDataClient.deleteAccountData(accessToken: accessToken)
            try await remoteClient.deleteAccount(accessToken: accessToken, appleAuthorizationCode: appleAuthorizationCode)
            if let deletingUserID { accountDeletedHandler?(deletingUserID) }
            guard sessionGeneration == context else { return }
            localDataResetHandler?()
            clearLocalSession()
        }
    }

    func hasPermission(_ permission: AccountPermission) -> Bool {
        profile?.hasPermission(permission) == true
    }

    private func refreshCachedSessionIfPossible() async {
        do {
            try await refreshSession()
            await refreshProfile()
        } catch {
            if CloudflareBackendErrorClassifier.isConnectivityFailure(error) {
                return
            }
            if let accountError = error as? AccountStoreError, accountError.isAuthenticationFailure {
                clearLocalSession()
                return
            }
            errorMessage = error.localizedDescription
        }
    }

    private func perform(_ operation: () async throws -> Void) async throws {
        isWorking = true
        errorMessage = nil
        defer { isWorking = false }

        do {
            try await operation()
        } catch {
            errorMessage = error.localizedDescription
            throw error
        }
    }

    private func applySession(_ session: AccountSession, restoringCachedSession: Bool = false) {
        if self.session?.profile.id != session.profile.id {
            sessionGeneration = UUID()
            if !restoringCachedSession { localDataResetHandler?() }
        }
        self.session = session
        self.phase = .signedIn
        keychainStore.save(session)
        Task {
            await CloudflareAuthenticationContext.shared.update(accessToken: session.accessToken, userID: session.profile.id)
        }
    }

    private func updateCachedProfile(_ profile: AccountProfile) {
        guard var session else { return }
        session.profile = profile
        applySession(session)
    }

    private func clearLocalSession() {
        sessionGeneration = UUID()
        refreshTask?.cancel(); refreshTask = nil
        localDataResetHandler?()
        session = nil
        phase = .signedOut
        keychainStore.clear()
        Task {
            await CloudflareAuthenticationContext.shared.update(accessToken: nil)
        }
    }

    private func requireAccessToken() throws -> String {
        guard let accessToken = session?.accessToken else {
            throw AccountStoreError.missingSession
        }
        return accessToken
    }

    private static var uiTestSession: AccountSession {
        AccountSession(
            accessToken: "ui-test-access-token",
            refreshToken: "ui-test-refresh-token",
            expiresAt: .distantFuture,
            profile: AccountProfile(
                id: "00000000-0000-4000-8000-000000000001",
                displayName: "App Review Demo",
                email: "reviewer@example.test",
                emailVerified: true,
                authMethods: [.emailPassword],
                squadronID: "vt-27",
                syllabusID: .echo,
                permissions: AppLaunchEnvironment.usesModeratorUITestAccount
                    ? [.instructorGougeModerator]
                    : [],
                profileComplete: true
            )
        )
    }
}

final class AccountKeychainSessionStore {
    private let service = "com.primarygouge.account"
    private let account = "supabase-account-session"

    func load() -> AccountSession? {
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
        return try? JSONDecoder.reviewDecoder.decode(AccountSession.self, from: data)
    }

    func save(_ session: AccountSession) {
        guard let data = try? JSONEncoder.reviewEncoder.encode(session) else { return }

        let baseQuery: [CFString: Any] = [
            kSecClass: kSecClassGenericPassword,
            kSecAttrService: service,
            kSecAttrAccount: account
        ]

        let attributes: [CFString: Any] = [
            kSecValueData: data,
            kSecAttrAccessible: kSecAttrAccessibleAfterFirstUnlockThisDeviceOnly
        ]

        let status = SecItemUpdate(baseQuery as CFDictionary, attributes as CFDictionary)
        if status == errSecItemNotFound {
            var createQuery = baseQuery
            createQuery[kSecValueData] = data
            createQuery[kSecAttrAccessible] = kSecAttrAccessibleAfterFirstUnlockThisDeviceOnly
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
