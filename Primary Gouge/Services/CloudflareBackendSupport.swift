import Foundation
import Network

struct CloudflareBackendConfiguration: Hashable {
    nonisolated static let productionBackendURLString = "https://primary-gouge-instructor-reviews.tz4mz7ry42.workers.dev"
    nonisolated static let defaultsKey = "InstructorReviewBackendURL"
    nonisolated static let bundleKey = "INSTRUCTOR_REVIEW_BACKEND_URL"

    nonisolated static let defaultsKeys = [
        "CloudflareBackendURL",
        "InstructorReviewBackendURL"
    ]

    nonisolated static let bundleKeys = [
        "CLOUDFLARE_BACKEND_URL",
        "INSTRUCTOR_REVIEW_BACKEND_URL"
    ]

    let baseURL: URL
    let source: InstructorReviewBackendSource

    var apiBaseURL: URL {
        baseURL.appending(path: "v1")
    }

    var statusDetail: String {
        switch source {
        case .bundled:
            return "Using bundled Cloudflare backend."
        case .productionDefault:
            return "Using built-in production Cloudflare backend."
        case .userDefaultsOverride:
            return "Using local backend override."
        case .unavailable:
            return "No valid backend URL found in local override, bundled settings, or production defaults."
        }
    }

    nonisolated static func load(bundle: Bundle = .main, defaults: UserDefaults = .standard) -> CloudflareBackendConfiguration? {
        resolve(
            overrideURLStrings: defaultsKeys.map { defaults.string(forKey: $0) },
            bundledURLStrings: bundleKeys.map { bundle.object(forInfoDictionaryKey: $0) as? String }
        )
    }

    nonisolated static func resolve(
        overrideURLString: String?,
        bundledURLString: String?,
        productionURLString: String? = productionBackendURLString
    ) -> CloudflareBackendConfiguration? {
        resolve(
            overrideURLStrings: [overrideURLString],
            bundledURLStrings: [bundledURLString],
            productionURLString: productionURLString
        )
    }

    nonisolated private static func resolve(
        overrideURLStrings: [String?],
        bundledURLStrings: [String?],
        productionURLString: String? = productionBackendURLString
    ) -> CloudflareBackendConfiguration? {
        if let overrideURL = overrideURLStrings.lazy.compactMap(resolvedURL).first {
            return CloudflareBackendConfiguration(baseURL: overrideURL, source: .userDefaultsOverride)
        }

        if let bundledURL = bundledURLStrings.lazy.compactMap(resolvedURL).first {
            return CloudflareBackendConfiguration(baseURL: bundledURL, source: .bundled)
        }

        if let productionURL = resolvedURL(from: productionURLString) {
            return CloudflareBackendConfiguration(baseURL: productionURL, source: .productionDefault)
        }

        return nil
    }

    @discardableResult
    nonisolated static func clearBlankOverrides(defaults: UserDefaults = .standard) -> Bool {
        var removedAny = false

        for key in defaultsKeys {
            guard let existingValue = defaults.object(forKey: key) as? String else {
                continue
            }

            if existingValue.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty {
                defaults.removeObject(forKey: key)
                removedAny = true
            }
        }

        return removedAny
    }

    @discardableResult
    nonisolated static func clearBlankOverride(defaults: UserDefaults = .standard) -> Bool {
        clearBlankOverrides(defaults: defaults)
    }

    nonisolated private static func resolvedURL(from rawValue: String?) -> URL? {
        guard let rawValue else {
            return nil
        }

        let trimmedValue = rawValue.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !trimmedValue.isEmpty else {
            return nil
        }

        guard
            let components = URLComponents(string: trimmedValue),
            let scheme = components.scheme?.lowercased(),
            ["http", "https"].contains(scheme),
            let host = components.host,
            !host.isEmpty,
            let baseURL = components.url
        else {
            return nil
        }

        return baseURL
    }
}

enum CloudflareBackendErrorClassifier {
    static func isConnectivityFailure(_ error: Error) -> Bool {
        let nsError = error as NSError
        guard nsError.domain == NSURLErrorDomain else {
            return false
        }

        switch URLError.Code(rawValue: nsError.code) {
        case .notConnectedToInternet,
             .networkConnectionLost,
             .cannotFindHost,
             .cannotConnectToHost,
             .dnsLookupFailed,
             .timedOut,
             .internationalRoamingOff,
             .dataNotAllowed:
            return true
        default:
            return false
        }
    }
}

final class AnonymousCloudflareClientIdentityStore {
    private let defaults: UserDefaults
    private let key: String
    private let legacyKeys: [String]

    init(
        defaults: UserDefaults = .standard,
        key: String = "PrimaryGougeAnonymousCloudflareClientID",
        legacyKeys: [String] = ["InstructorReviewAnonymousClientID"]
    ) {
        self.defaults = defaults
        self.key = key
        self.legacyKeys = legacyKeys
    }

    func clientID() -> String {
        if let existing = defaults.string(forKey: key), !existing.isEmpty {
            return existing
        }

        for legacyKey in legacyKeys {
            if let legacyValue = defaults.string(forKey: legacyKey), !legacyValue.isEmpty {
                defaults.set(legacyValue, forKey: key)
                return legacyValue
            }
        }

        let value = UUID().uuidString.lowercased()
        defaults.set(value, forKey: key)
        return value
    }
}

final class CloudflareConnectivityMonitor {
    var onConnectivityChanged: (@MainActor (Bool) -> Void)?

    private let monitor = NWPathMonitor()
    private let queue = DispatchQueue(label: "CloudflareConnectivityMonitor")

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

typealias InstructorReviewBackendConfiguration = CloudflareBackendConfiguration
typealias AnonymousInstructorReviewClientIdentityStore = AnonymousCloudflareClientIdentityStore
typealias InstructorReviewConnectivityMonitor = CloudflareConnectivityMonitor
