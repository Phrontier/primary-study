import Foundation

struct SupabaseAccountConfiguration: Hashable {
    static let production = SupabaseAccountConfiguration(
        projectURL: URL(string: "https://nsnezmbmosqtpychvpea.supabase.co")!,
        publishableKey: "sb_publishable_GNMwpLi9rOZpyy8ACZLgsA_gD_WTcGZ"
    )

    let projectURL: URL
    let publishableKey: String

    var authBaseURL: URL {
        projectURL.appending(path: "auth/v1")
    }

    var restBaseURL: URL {
        projectURL.appending(path: "rest/v1")
    }

    var functionsBaseURL: URL {
        projectURL.appending(path: "functions/v1")
    }
}

final class SupabaseAccountRemoteClient {
    private struct AppleIDTokenPayload: Encodable {
        let provider = "apple"
        let idToken: String
        let nonce: String?

        enum CodingKeys: String, CodingKey {
            case provider
            case idToken = "id_token"
            case nonce
        }
    }

    private struct EmailSignUpPayload: Encodable {
        let email: String
        let password: String
        let data: EmailSignUpMetadata?
    }

    private struct EmailSignUpMetadata: Encodable {
        let displayName: String

        enum CodingKeys: String, CodingKey {
            case displayName = "display_name"
        }
    }

    private struct EmailPasswordPayload: Encodable {
        let email: String
        let password: String
    }

    private struct RefreshPayload: Encodable {
        let refreshToken: String

        enum CodingKeys: String, CodingKey {
            case refreshToken = "refresh_token"
        }
    }

    private struct VerifyPayload: Encodable {
        let email: String
        let token: String
        let type: String
    }

    private struct PasswordResetRequestPayload: Encodable {
        let email: String
    }

    private struct PasswordUpdatePayload: Encodable {
        let password: String
    }

    private struct ProfileUpsertPayload: Encodable {
        let id: String
        let displayName: String?
        let squadronID: String?
        let syllabusID: SyllabusTrack?

        enum CodingKeys: String, CodingKey {
            case id
            case displayName = "display_name"
            case squadronID = "squadron_id"
            case syllabusID = "syllabus_id"
        }

        func encode(to encoder: Encoder) throws {
            var container = encoder.container(keyedBy: CodingKeys.self)
            try container.encode(id, forKey: .id)
            try container.encode(displayName, forKey: .displayName)
            try container.encode(squadronID, forKey: .squadronID)
            try container.encode(syllabusID, forKey: .syllabusID)
        }
    }

    private struct DeletePayload: Encodable {
        let appleAuthorizationCode: String?
    }

    private struct SupabaseAuthResponse: Decodable {
        let accessToken: String?
        let refreshToken: String?
        let expiresIn: TimeInterval?
        let expiresAt: TimeInterval?
        let user: SupabaseUser?

        enum CodingKeys: String, CodingKey {
            case accessToken = "access_token"
            case refreshToken = "refresh_token"
            case expiresIn = "expires_in"
            case expiresAt = "expires_at"
            case user
        }
    }

    private struct SupabaseUser: Decodable {
        let id: String
        let email: String?
        let confirmedAt: String?
        let emailConfirmedAt: String?
        let appMetadata: SupabaseAppMetadata?
        let userMetadata: SupabaseUserMetadata?

        enum CodingKeys: String, CodingKey {
            case id
            case email
            case confirmedAt = "confirmed_at"
            case emailConfirmedAt = "email_confirmed_at"
            case appMetadata = "app_metadata"
            case userMetadata = "user_metadata"
        }
    }

    private struct SupabaseAppMetadata: Decodable {
        let provider: String?
        let providers: [String]?
    }

    private struct SupabaseUserMetadata: Decodable {
        let displayName: String?
        let fullName: String?
        let name: String?

        enum CodingKeys: String, CodingKey {
            case displayName = "display_name"
            case fullName = "full_name"
            case name
        }
    }

    private struct SupabaseProfileRow: Decodable {
        let id: String
        let displayName: String?
        let squadronID: String?
        let syllabusID: SyllabusTrack?

        enum CodingKeys: String, CodingKey {
            case id
            case displayName = "display_name"
            case squadronID = "squadron_id"
            case syllabusID = "syllabus_id"
        }
    }

    private struct SupabaseRoleRow: Decodable {
        let permission: AccountPermission
    }

    private struct SupabaseErrorResponse: Decodable {
        let message: String?
        let msg: String?
        let errorDescription: String?
        let error: String?

        enum CodingKeys: String, CodingKey {
            case message
            case msg
            case errorDescription = "error_description"
            case error
        }

        var resolvedMessage: String? {
            message ?? msg ?? errorDescription ?? error
        }
    }

    private struct EmptyResponse: Decodable {}

    private let configuration: SupabaseAccountConfiguration
    private let session: URLSession

    init(configuration: SupabaseAccountConfiguration = .production, session: URLSession = .shared) {
        self.configuration = configuration
        self.session = session
    }

    func signInWithApple(identityToken: String, authorizationCode: String?, displayName: String?, email: String?, nonce: String?) async throws -> AccountSession {
        var authSession: AccountSession = try await sendAuthSession(
            path: "token",
            queryItems: [URLQueryItem(name: "grant_type", value: "id_token")],
            method: "POST",
            body: AppleIDTokenPayload(idToken: identityToken, nonce: nonce)
        )

        if let displayName, !displayName.isEmpty {
            let profile = try await upsertProfile(
                accessToken: authSession.accessToken,
                userID: authSession.profile.id,
                displayName: displayName,
                squadronID: authSession.profile.squadronID,
                syllabusID: authSession.profile.syllabusID
            )
            authSession.profile = profile
        }

        return authSession
    }

    func registerWithEmail(email: String, password: String, displayName: String?) async throws -> AccountSession? {
        let response: SupabaseAuthResponse = try await sendAuth(
            path: "signup",
            method: "POST",
            body: EmailSignUpPayload(
                email: email,
                password: password,
                data: displayName.map { EmailSignUpMetadata(displayName: $0) }
            ),
            accessToken: nil
        )

        guard response.accessToken != nil else {
            return nil
        }
        return try await accountSession(from: response)
    }

    func verifyEmail(email: String, code: String) async throws -> AccountSession {
        try await sendAuthSession(
            path: "verify",
            method: "POST",
            body: VerifyPayload(email: email, token: code, type: "signup")
        )
    }

    func signInWithEmail(email: String, password: String) async throws -> AccountSession {
        try await sendAuthSession(
            path: "token",
            queryItems: [URLQueryItem(name: "grant_type", value: "password")],
            method: "POST",
            body: EmailPasswordPayload(email: email, password: password)
        )
    }

    func requestPasswordReset(email: String) async throws {
        try await sendAuthNoContent(
            path: "recover",
            method: "POST",
            body: PasswordResetRequestPayload(email: email),
            accessToken: nil
        )
    }

    func confirmPasswordReset(email: String, code: String, newPassword: String) async throws -> AccountSession {
        let verifiedSession: AccountSession = try await sendAuthSession(
            path: "verify",
            method: "POST",
            body: VerifyPayload(email: email, token: code, type: "recovery")
        )

        let _: SupabaseUser = try await sendAuth(
            path: "user",
            method: "PUT",
            body: PasswordUpdatePayload(password: newPassword),
            accessToken: verifiedSession.accessToken
        )

        return try await refresh(refreshToken: verifiedSession.refreshToken)
    }

    func refresh(refreshToken: String) async throws -> AccountSession {
        try await sendAuthSession(
            path: "token",
            queryItems: [URLQueryItem(name: "grant_type", value: "refresh_token")],
            method: "POST",
            body: RefreshPayload(refreshToken: refreshToken)
        )
    }

    func signOut(accessToken: String) async throws {
        try await sendAuthNoContent(
            path: "logout",
            method: "POST",
            body: Optional<Int>.none as Int?,
            accessToken: accessToken
        )
    }

    func fetchProfile(accessToken: String) async throws -> AccountProfile {
        let user: SupabaseUser = try await sendAuth(
            path: "user",
            method: "GET",
            body: Optional<Int>.none as Int?,
            accessToken: accessToken
        )

        let row = try await fetchOrCreateProfileRow(accessToken: accessToken, user: user)
        let permissions = try await fetchPermissions(accessToken: accessToken, userID: user.id)
        return accountProfile(user: user, row: row, permissions: permissions)
    }

    func updateProfile(accessToken: String, displayName: String?, squadronID: String, syllabusID: SyllabusTrack) async throws -> AccountProfile {
        let user: SupabaseUser = try await sendAuth(
            path: "user",
            method: "GET",
            body: Optional<Int>.none as Int?,
            accessToken: accessToken
        )

        return try await upsertProfile(
            accessToken: accessToken,
            userID: user.id,
            displayName: displayName,
            squadronID: squadronID,
            syllabusID: syllabusID
        )
    }

    func deleteAccount(accessToken: String, appleAuthorizationCode: String?) async throws {
        try await sendFunctionNoContent(
            path: "delete-account",
            method: "POST",
            body: DeletePayload(appleAuthorizationCode: appleAuthorizationCode),
            accessToken: accessToken
        )
    }

    private func upsertProfile(
        accessToken: String,
        userID: String,
        displayName: String?,
        squadronID: String?,
        syllabusID: SyllabusTrack?
    ) async throws -> AccountProfile {
        let rows: [SupabaseProfileRow] = try await sendRest(
            path: "account_profiles",
            queryItems: [URLQueryItem(name: "on_conflict", value: "id")],
            method: "POST",
            body: [
                ProfileUpsertPayload(
                    id: userID,
                    displayName: displayName,
                    squadronID: squadronID,
                    syllabusID: syllabusID
                )
            ],
            accessToken: accessToken,
            prefer: "resolution=merge-duplicates,return=representation"
        )

        let user: SupabaseUser = try await sendAuth(
            path: "user",
            method: "GET",
            body: Optional<Int>.none as Int?,
            accessToken: accessToken
        )
        let row: SupabaseProfileRow
        if let firstRow = rows.first {
            row = firstRow
        } else {
            row = try await fetchOrCreateProfileRow(accessToken: accessToken, user: user)
        }
        let permissions = try await fetchPermissions(accessToken: accessToken, userID: userID)
        return accountProfile(user: user, row: row, permissions: permissions)
    }

    private func fetchOrCreateProfileRow(accessToken: String, user: SupabaseUser) async throws -> SupabaseProfileRow {
        let rows: [SupabaseProfileRow] = try await sendRest(
            path: "account_profiles",
            queryItems: [
                URLQueryItem(name: "id", value: "eq.\(user.id)"),
                URLQueryItem(name: "select", value: "id,display_name,squadron_id,syllabus_id"),
                URLQueryItem(name: "limit", value: "1")
            ],
            method: "GET",
            body: Optional<Int>.none as Int?,
            accessToken: accessToken
        )

        if let row = rows.first {
            return row
        }

        let displayName = user.userMetadata?.displayName ?? user.userMetadata?.fullName ?? user.userMetadata?.name
        let insertedRows: [SupabaseProfileRow] = try await sendRest(
            path: "account_profiles",
            queryItems: [URLQueryItem(name: "on_conflict", value: "id")],
            method: "POST",
            body: [
                ProfileUpsertPayload(
                    id: user.id,
                    displayName: displayName,
                    squadronID: nil,
                    syllabusID: nil
                )
            ],
            accessToken: accessToken,
            prefer: "resolution=merge-duplicates,return=representation"
        )

        guard let insertedRow = insertedRows.first else {
            throw AccountStoreError.requestFailed(statusCode: 500, message: "Account profile could not be created.")
        }
        return insertedRow
    }

    private func fetchPermissions(accessToken: String, userID: String) async throws -> [AccountPermission] {
        let rows: [SupabaseRoleRow] = try await sendRest(
            path: "account_roles",
            queryItems: [
                URLQueryItem(name: "user_id", value: "eq.\(userID)"),
                URLQueryItem(name: "select", value: "permission"),
                URLQueryItem(name: "order", value: "permission.asc")
            ],
            method: "GET",
            body: Optional<Int>.none as Int?,
            accessToken: accessToken
        )
        return rows.map(\.permission)
    }

    private func accountSession(from response: SupabaseAuthResponse) async throws -> AccountSession {
        guard
            let accessToken = response.accessToken,
            let refreshToken = response.refreshToken
        else {
            throw AccountStoreError.missingSession
        }

        let profile = try await fetchProfile(accessToken: accessToken)
        let expiresAt = response.expiresAt.map { Date(timeIntervalSince1970: $0) }
            ?? Date().addingTimeInterval(response.expiresIn ?? 3600)

        return AccountSession(
            accessToken: accessToken,
            refreshToken: refreshToken,
            expiresAt: expiresAt,
            profile: profile
        )
    }

    private func accountProfile(user: SupabaseUser, row: SupabaseProfileRow, permissions: [AccountPermission]) -> AccountProfile {
        let providers = user.appMetadata?.providers ?? user.appMetadata?.provider.map { [$0] } ?? []
        let authMethods = providers.compactMap { provider -> AccountAuthMethod? in
            switch provider {
            case "apple":
                return .apple
            case "email":
                return .emailPassword
            default:
                return nil
            }
        }

        return AccountProfile(
            id: user.id,
            displayName: row.displayName ?? user.userMetadata?.displayName ?? user.userMetadata?.fullName ?? user.userMetadata?.name,
            email: user.email,
            emailVerified: user.emailConfirmedAt != nil || user.confirmedAt != nil,
            authMethods: authMethods.isEmpty && user.email != nil ? [.emailPassword] : authMethods,
            squadronID: row.squadronID,
            syllabusID: row.syllabusID,
            permissions: permissions,
            profileComplete: row.squadronID?.isEmpty == false && row.syllabusID != nil
        )
    }

    private func sendAuthSession<Body: Encodable>(
        path: String,
        queryItems: [URLQueryItem] = [],
        method: String,
        body: Body
    ) async throws -> AccountSession {
        let response: SupabaseAuthResponse = try await sendAuth(
            path: path,
            queryItems: queryItems,
            method: method,
            body: body,
            accessToken: nil
        )
        return try await accountSession(from: response)
    }

    private func sendAuth<T: Decodable, Body: Encodable>(
        path: String,
        queryItems: [URLQueryItem] = [],
        method: String,
        body: Body?,
        accessToken: String?
    ) async throws -> T {
        var request = URLRequest(url: endpointURL(baseURL: configuration.authBaseURL, path: path, queryItems: queryItems))
        request.httpMethod = method
        applySupabaseHeaders(to: &request, accessToken: accessToken)
        if let body {
            request.httpBody = try JSONEncoder.reviewEncoder.encode(body)
        }

        return try await send(request)
    }

    private func sendAuthNoContent<Body: Encodable>(
        path: String,
        method: String,
        body: Body?,
        accessToken: String?
    ) async throws {
        var request = URLRequest(url: endpointURL(baseURL: configuration.authBaseURL, path: path))
        request.httpMethod = method
        applySupabaseHeaders(to: &request, accessToken: accessToken)
        if let body {
            request.httpBody = try JSONEncoder.reviewEncoder.encode(body)
        }

        let (data, response) = try await session.data(for: request)
        try validate(response: response, data: data)
    }

    private func sendRest<T: Decodable, Body: Encodable>(
        path: String,
        queryItems: [URLQueryItem],
        method: String,
        body: Body?,
        accessToken: String,
        prefer: String? = nil
    ) async throws -> T {
        var request = URLRequest(url: endpointURL(baseURL: configuration.restBaseURL, path: path, queryItems: queryItems))
        request.httpMethod = method
        applySupabaseHeaders(to: &request, accessToken: accessToken)
        if let prefer {
            request.setValue(prefer, forHTTPHeaderField: "Prefer")
        }
        if let body {
            request.httpBody = try JSONEncoder.reviewEncoder.encode(body)
        }

        return try await send(request)
    }

    private func sendFunctionNoContent<Body: Encodable>(
        path: String,
        method: String,
        body: Body?,
        accessToken: String
    ) async throws {
        var request = URLRequest(url: endpointURL(baseURL: configuration.functionsBaseURL, path: path))
        request.httpMethod = method
        applySupabaseHeaders(to: &request, accessToken: accessToken)
        if let body {
            request.httpBody = try JSONEncoder.reviewEncoder.encode(body)
        }

        let (data, response) = try await session.data(for: request)
        try validate(response: response, data: data)
    }

    private func send<T: Decodable>(_ request: URLRequest) async throws -> T {
        let (data, response) = try await session.data(for: request)
        try validate(response: response, data: data)
        if data.isEmpty, T.self == EmptyResponse.self {
            return EmptyResponse() as! T
        }
        return try JSONDecoder.reviewDecoder.decode(T.self, from: data)
    }

    private func validate(response: URLResponse, data: Data) throws {
        guard let httpResponse = response as? HTTPURLResponse else {
            throw URLError(.badServerResponse)
        }

        guard (200..<300).contains(httpResponse.statusCode) else {
            let message = decodedErrorMessage(from: data) ?? "Account request failed."
            throw AccountStoreError.requestFailed(
                statusCode: httpResponse.statusCode,
                message: friendlyErrorMessage(statusCode: httpResponse.statusCode, message: message)
            )
        }
    }

    private func endpointURL(baseURL: URL, path: String, queryItems: [URLQueryItem] = []) -> URL {
        let url = baseURL.appending(path: path)
        guard !queryItems.isEmpty else {
            return url
        }

        var components = URLComponents(url: url, resolvingAgainstBaseURL: false)
        components?.queryItems = queryItems
        return components?.url ?? url
    }

    private func applySupabaseHeaders(to request: inout URLRequest, accessToken: String?) {
        request.setValue("application/json", forHTTPHeaderField: "Accept")
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")
        request.setValue(configuration.publishableKey, forHTTPHeaderField: "apikey")
        if let accessToken {
            request.setValue("Bearer \(accessToken)", forHTTPHeaderField: "Authorization")
        }
    }

    private func decodedErrorMessage(from data: Data) -> String? {
        if let error = try? JSONDecoder.reviewDecoder.decode(SupabaseErrorResponse.self, from: data),
           let message = error.resolvedMessage?.trimmingCharacters(in: .whitespacesAndNewlines),
           !message.isEmpty {
            return message
        }

        let message = String(data: data, encoding: .utf8)?.trimmingCharacters(in: .whitespacesAndNewlines)
        return message?.isEmpty == false ? message : nil
    }

    private func friendlyErrorMessage(statusCode: Int, message: String) -> String {
        if statusCode == 404 && message.localizedCaseInsensitiveContains("not found") {
            return "Account service is not available yet. Try again in a moment."
        }
        if message.localizedCaseInsensitiveContains("invalid login credentials") {
            return "The email or password did not match an account."
        }
        if message.localizedCaseInsensitiveContains("email not confirmed") {
            return "Check your email for the verification code before signing in."
        }
        if message.localizedCaseInsensitiveContains("token has expired") || message.localizedCaseInsensitiveContains("token is expired") {
            return "That code expired. Request a new code and try again."
        }
        if message.localizedCaseInsensitiveContains("invalid token") {
            return "That code did not work. Check the email and try again."
        }
        return message
    }
}
