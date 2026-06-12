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

    func update(accessToken: String?) {
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

    private let keychainStore: AccountKeychainSessionStore
    private let remoteClient: CloudflareAccountRemoteClient
    private var didConfigure = false

    init(
        keychainStore: AccountKeychainSessionStore? = nil,
        remoteClient: CloudflareAccountRemoteClient? = nil
    ) {
        self.keychainStore = keychainStore ?? AccountKeychainSessionStore()
        self.remoteClient = remoteClient ?? CloudflareAccountRemoteClient()
    }

    func configure() async {
        guard !didConfigure else { return }
        didConfigure = true

        if let storedSession = keychainStore.load() {
            applySession(storedSession)
            await refreshCachedSessionIfPossible()
        } else {
            phase = .signedOut
            await CloudflareAuthenticationContext.shared.update(accessToken: nil)
        }
    }

    func registerWithEmail(email: String, password: String, displayName: String?) async throws {
        try await perform {
            try await remoteClient.registerWithEmail(
                email: email,
                password: password,
                displayName: displayName
            )
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
        guard let accessToken = session?.accessToken else { return }
        do {
            let profile = try await remoteClient.fetchProfile(accessToken: accessToken)
            updateCachedProfile(profile)
        } catch {
            errorMessage = error.localizedDescription
        }
    }

    func updateProfile(displayName: String?, squadronID: String, syllabusID: SyllabusTrack) async throws {
        try await perform {
            let accessToken = try requireAccessToken()
            let profile = try await remoteClient.updateProfile(
                accessToken: accessToken,
                displayName: displayName,
                squadronID: squadronID,
                syllabusID: syllabusID
            )
            updateCachedProfile(profile)
        }
    }

    func refreshSession() async throws {
        guard let refreshToken = session?.refreshToken else {
            throw AccountStoreError.missingSession
        }

        let refreshed = try await remoteClient.refresh(refreshToken: refreshToken)
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
            let accessToken = try requireAccessToken()
            try await remoteClient.deleteAccount(accessToken: accessToken, appleAuthorizationCode: appleAuthorizationCode)
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

    private func applySession(_ session: AccountSession) {
        self.session = session
        self.phase = .signedIn
        keychainStore.save(session)
        Task {
            await CloudflareAuthenticationContext.shared.update(accessToken: session.accessToken)
        }
    }

    private func updateCachedProfile(_ profile: AccountProfile) {
        guard var session else { return }
        session.profile = profile
        applySession(session)
    }

    private func clearLocalSession() {
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
}

final class AccountKeychainSessionStore {
    private let service = "com.primarygouge.account"
    private let account = "cloudflare-account-session"

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

final class CloudflareAccountRemoteClient {
    private struct AppleAuthPayload: Encodable {
        let identityToken: String
        let authorizationCode: String?
        let displayName: String?
        let email: String?
        let nonce: String?
    }

    private struct EmailRegisterPayload: Encodable {
        let email: String
        let password: String
        let displayName: String?
    }

    private struct EmailCodePayload: Encodable {
        let email: String
        let code: String
    }

    private struct EmailSignInPayload: Encodable {
        let email: String
        let password: String
    }

    private struct PasswordResetRequestPayload: Encodable {
        let email: String
    }

    private struct PasswordResetConfirmPayload: Encodable {
        let email: String
        let code: String
        let newPassword: String
    }

    private struct RefreshPayload: Encodable {
        let refreshToken: String
    }

    private struct ProfileUpdatePayload: Encodable {
        let displayName: String?
        let squadronID: String
        let syllabusID: SyllabusTrack
    }

    private struct DeletePayload: Encodable {
        let appleAuthorizationCode: String?
    }

    private struct ProfileResponse: Decodable {
        let profile: AccountProfile
    }

    private struct EmptyResponse: Decodable {}

    private let configuration: CloudflareBackendConfiguration?
    private let session: URLSession

    init(configuration: CloudflareBackendConfiguration? = CloudflareBackendConfiguration.load(), session: URLSession = .shared) {
        self.configuration = configuration
        self.session = session
    }

    func signInWithApple(identityToken: String, authorizationCode: String?, displayName: String?, email: String?, nonce: String?) async throws -> AccountSession {
        try await send(
            path: "auth/apple",
            method: "POST",
            body: AppleAuthPayload(
                identityToken: identityToken,
                authorizationCode: authorizationCode,
                displayName: displayName,
                email: email,
                nonce: nonce
            ),
            accessToken: nil
        )
    }

    func registerWithEmail(email: String, password: String, displayName: String?) async throws {
        let _: EmptyResponse = try await send(
            path: "auth/email/register",
            method: "POST",
            body: EmailRegisterPayload(email: email, password: password, displayName: displayName),
            accessToken: nil
        )
    }

    func verifyEmail(email: String, code: String) async throws -> AccountSession {
        try await send(
            path: "auth/email/verify",
            method: "POST",
            body: EmailCodePayload(email: email, code: code),
            accessToken: nil
        )
    }

    func signInWithEmail(email: String, password: String) async throws -> AccountSession {
        try await send(
            path: "auth/email/sign-in",
            method: "POST",
            body: EmailSignInPayload(email: email, password: password),
            accessToken: nil
        )
    }

    func requestPasswordReset(email: String) async throws {
        let _: EmptyResponse = try await send(
            path: "auth/email/password-reset/request",
            method: "POST",
            body: PasswordResetRequestPayload(email: email),
            accessToken: nil
        )
    }

    func confirmPasswordReset(email: String, code: String, newPassword: String) async throws -> AccountSession {
        try await send(
            path: "auth/email/password-reset/confirm",
            method: "POST",
            body: PasswordResetConfirmPayload(email: email, code: code, newPassword: newPassword),
            accessToken: nil
        )
    }

    func refresh(refreshToken: String) async throws -> AccountSession {
        try await send(
            path: "auth/refresh",
            method: "POST",
            body: RefreshPayload(refreshToken: refreshToken),
            accessToken: nil
        )
    }

    func signOut(accessToken: String) async throws {
        try await sendNoContent(
            path: "auth/sign-out",
            method: "POST",
            body: Optional<Int>.none as Int?,
            accessToken: accessToken
        )
    }

    func fetchProfile(accessToken: String) async throws -> AccountProfile {
        let response: ProfileResponse = try await send(
            path: "me",
            method: "GET",
            body: Optional<Int>.none as Int?,
            accessToken: accessToken
        )
        return response.profile
    }

    func updateProfile(accessToken: String, displayName: String?, squadronID: String, syllabusID: SyllabusTrack) async throws -> AccountProfile {
        let response: ProfileResponse = try await send(
            path: "me",
            method: "PATCH",
            body: ProfileUpdatePayload(displayName: displayName, squadronID: squadronID, syllabusID: syllabusID),
            accessToken: accessToken
        )
        return response.profile
    }

    func deleteAccount(accessToken: String, appleAuthorizationCode: String?) async throws {
        try await sendNoContent(
            path: "me",
            method: "DELETE",
            body: DeletePayload(appleAuthorizationCode: appleAuthorizationCode),
            accessToken: accessToken
        )
    }

    private func endpointURL(for path: String) throws -> URL {
        guard let configuration else {
            throw AccountStoreError.backendNotConfigured
        }
        return configuration.apiBaseURL.appending(path: path)
    }

    private func send<T: Decodable, Body: Encodable>(
        path: String,
        method: String,
        body: Body?,
        accessToken: String?
    ) async throws -> T {
        var request = URLRequest(url: try endpointURL(for: path))
        request.httpMethod = method
        request.setValue("application/json", forHTTPHeaderField: "Accept")
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")
        if let accessToken {
            request.setValue("Bearer \(accessToken)", forHTTPHeaderField: "Authorization")
        }
        if let body {
            request.httpBody = try JSONEncoder.reviewEncoder.encode(body)
        }

        let (data, response) = try await session.data(for: request)
        try validate(response: response, data: data)
        if data.isEmpty, T.self == EmptyResponse.self {
            return EmptyResponse() as! T
        }
        return try JSONDecoder.reviewDecoder.decode(T.self, from: data)
    }

    private func sendNoContent<Body: Encodable>(
        path: String,
        method: String,
        body: Body?,
        accessToken: String?
    ) async throws {
        var request = URLRequest(url: try endpointURL(for: path))
        request.httpMethod = method
        request.setValue("application/json", forHTTPHeaderField: "Accept")
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")
        if let accessToken {
            request.setValue("Bearer \(accessToken)", forHTTPHeaderField: "Authorization")
        }
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
            let resolvedMessage = message?.isEmpty == false ? message! : "Account request failed."
            throw AccountStoreError.requestFailed(
                statusCode: httpResponse.statusCode,
                message: friendlyErrorMessage(statusCode: httpResponse.statusCode, message: resolvedMessage)
            )
        }
    }

    private func friendlyErrorMessage(statusCode: Int, message: String) -> String {
        if statusCode == 404 && message.localizedCaseInsensitiveContains("not found") {
            return "Account service is not updated yet. Try again after the Cloudflare auth deploy finishes."
        }
        return message
    }
}
