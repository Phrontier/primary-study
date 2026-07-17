import Foundation

protocol AccountLinkedDataDeleting {
    func deleteAccountData(accessToken: String) async throws
}

final class CloudflareAccountDataClient: AccountLinkedDataDeleting {
    private let configuration: CloudflareBackendConfiguration?
    private let session: URLSession

    init(
        configuration: CloudflareBackendConfiguration? = CloudflareBackendConfiguration.load(),
        session: URLSession = .shared
    ) {
        self.configuration = configuration
        self.session = session
    }

    func deleteAccountData(accessToken: String) async throws {
        guard let configuration else {
            throw AccountStoreError.backendNotConfigured
        }

        var request = URLRequest(url: configuration.apiBaseURL.appending(path: "me"))
        request.httpMethod = "DELETE"
        request.setValue("application/json", forHTTPHeaderField: "Accept")
        request.setValue("Bearer \(accessToken)", forHTTPHeaderField: "Authorization")

        let (data, response) = try await session.data(for: request)
        guard let httpResponse = response as? HTTPURLResponse else {
            throw URLError(.badServerResponse)
        }
        guard (200..<300).contains(httpResponse.statusCode) else {
            let message = String(data: data, encoding: .utf8)?
                .trimmingCharacters(in: .whitespacesAndNewlines)
            throw AccountStoreError.requestFailed(
                statusCode: httpResponse.statusCode,
                message: message?.isEmpty == false
                    ? message!
                    : "Account-linked reviews and submissions could not be deleted."
            )
        }
    }
}
