import Foundation
import Network

struct CloudflareBackendConfiguration: Hashable {
    static let defaultsKey = "InstructorReviewBackendURL"
    static let bundleKey = "INSTRUCTOR_REVIEW_BACKEND_URL"

    static let defaultsKeys = [
        "CloudflareBackendURL",
        "InstructorReviewBackendURL"
    ]

    static let bundleKeys = [
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
        case .userDefaultsOverride:
            return "Using local backend override."
        case .unavailable:
            return "No backend URL found in local override or bundled settings."
        }
    }

    static func load(bundle: Bundle = .main, defaults: UserDefaults = .standard) -> CloudflareBackendConfiguration? {
        resolve(
            overrideURLString: defaultsKeys.lazy.compactMap { defaults.string(forKey: $0) }.first,
            bundledURLString: bundleKeys.lazy.compactMap { bundle.object(forInfoDictionaryKey: $0) as? String }.first
        )
    }

    static func resolve(overrideURLString: String?, bundledURLString: String?) -> CloudflareBackendConfiguration? {
        if let overrideURL = resolvedURL(from: overrideURLString) {
            return CloudflareBackendConfiguration(baseURL: overrideURL, source: .userDefaultsOverride)
        }

        if let bundledURL = resolvedURL(from: bundledURLString) {
            return CloudflareBackendConfiguration(baseURL: bundledURL, source: .bundled)
        }

        return nil
    }

    @discardableResult
    static func clearBlankOverrides(defaults: UserDefaults = .standard) -> Bool {
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
    static func clearBlankOverride(defaults: UserDefaults = .standard) -> Bool {
        clearBlankOverrides(defaults: defaults)
    }

    private static func resolvedURL(from rawValue: String?) -> URL? {
        guard let rawValue else {
            return nil
        }

        let trimmedValue = rawValue.trimmingCharacters(in: .whitespacesAndNewlines)
        guard
            !trimmedValue.isEmpty,
            let baseURL = URL(string: trimmedValue)
        else {
            return nil
        }

        return baseURL
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
