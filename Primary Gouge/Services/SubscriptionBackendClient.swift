import Foundation

protocol SubscriptionBackendServing {
    func fetchEntitlement(accessToken: String) async throws -> SubscriptionEntitlement
    func reconcile(signedTransaction: String, accessToken: String) async throws -> SubscriptionEntitlement
}

final class SubscriptionBackendClient: SubscriptionBackendServing {
    private struct ReconcilePayload: Encodable {
        let signedTransaction: String

        enum CodingKeys: String, CodingKey {
            case signedTransaction = "signed_transaction"
        }
    }

    private struct EntitlementResponse: Decodable {
        let status: SubscriptionEntitlementPhase
        let productID: String?
        let expiresAt: Date?
        let willAutoRenew: Bool?
        let environment: String?

        enum CodingKeys: String, CodingKey {
            case status
            case productID = "product_id"
            case expiresAt = "expires_at"
            case willAutoRenew = "will_auto_renew"
            case environment
        }

        var entitlement: SubscriptionEntitlement {
            SubscriptionEntitlement(
                phase: status,
                productID: productID,
                expirationDate: expiresAt,
                willAutoRenew: willAutoRenew,
                environment: environment,
                message: nil
            )
        }
    }

    private struct ErrorResponse: Decodable {
        let error: String?
        let message: String?
        let code: String?
    }

    private let configuration: SupabaseAccountConfiguration
    private let session: URLSession

    init(
        configuration: SupabaseAccountConfiguration = .production,
        session: URLSession = .shared
    ) {
        self.configuration = configuration
        self.session = session
    }

    func fetchEntitlement(accessToken: String) async throws -> SubscriptionEntitlement {
        try await send(method: "GET", body: Optional<Int>.none, accessToken: accessToken).entitlement
    }

    func reconcile(signedTransaction: String, accessToken: String) async throws -> SubscriptionEntitlement {
        try await send(
            method: "POST",
            body: ReconcilePayload(signedTransaction: signedTransaction),
            accessToken: accessToken
        ).entitlement
    }

    private func send<Body: Encodable>(
        method: String,
        body: Body?,
        accessToken: String
    ) async throws -> EntitlementResponse {
        let url = configuration.functionsBaseURL.appending(path: "subscription-entitlement")
        var request = URLRequest(url: url)
        request.httpMethod = method
        request.setValue("application/json", forHTTPHeaderField: "Accept")
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")
        request.setValue(configuration.publishableKey, forHTTPHeaderField: "apikey")
        request.setValue("Bearer \(accessToken)", forHTTPHeaderField: "Authorization")
        if let body {
            request.httpBody = try JSONEncoder.reviewEncoder.encode(body)
        }

        let (data, response) = try await session.data(for: request)
        guard let httpResponse = response as? HTTPURLResponse else {
            throw URLError(.badServerResponse)
        }

        guard (200..<300).contains(httpResponse.statusCode) else {
            let error = try? JSONDecoder.reviewDecoder.decode(ErrorResponse.self, from: data)
            if error?.code == "account_mismatch" {
                throw SubscriptionStoreError.accountMismatch
            }
            throw SubscriptionStoreError.backendRejected(
                error?.message ?? error?.error ?? "Premium could not be synchronized with your account."
            )
        }

        return try JSONDecoder.reviewDecoder.decode(EntitlementResponse.self, from: data)
    }
}
