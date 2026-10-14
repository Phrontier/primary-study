import Combine
import Foundation

@MainActor
final class SubscriptionStore: ObservableObject {
    static let premiumMonthlyProductID = "bolt.primarygouge.premium.monthly"
    @Published private(set) var entitlement: SubscriptionEntitlement = .loading
    @Published private(set) var product: SubscriptionProductInfo?
    @Published private(set) var isWorking = false
    @Published private(set) var purchaseIsPending = false
    @Published var errorMessage: String?

    var hasPremiumAccess: Bool { entitlement.grantsAccess(at: now()) }
    var displayPrice: String { product?.displayPrice ?? "Price unavailable" }
    var trialDescription: String? { product?.trialDescription }
    var offerDescription: String {
        if let trialDescription { return "Start with a \(trialDescription), then \(displayPrice) per month." }
        return product == nil ? "Premium pricing is currently unavailable." : "\(displayPrice) per month."
    }
    var isPurchaseLaunchEnabled: Bool { product != nil }

    // The provider refreshes authentication without retaining credentials here.
    var tokenProvider: ((UUID, Bool) async throws -> String)?
    private let backend: SubscriptionBackendServing
    private let storeKit: StoreKitServing
    private let now: () -> Date
    private let queueURL: URL
    private struct Pending: Codable { let userID: UUID; let transaction: VerifiedSubscriptionTransaction }
    private var pending: [Pending] = []
    private var userID: UUID?
    private var accessToken: String?
    private var generation = UUID()
    private var listener: Task<Void, Never>?
    private var expiryTask: Task<Void, Never>?

    init(backend: SubscriptionBackendServing? = nil, storeKit: StoreKitServing? = nil,
         queueURL: URL? = nil, now: @escaping () -> Date = { .now }) {
        self.backend = backend ?? SubscriptionBackendClient()
        self.storeKit = storeKit ?? StoreKitClient()
        self.now = now
        self.queueURL = queueURL ?? URL.applicationSupportDirectory.appending(path: "PendingPremiumTransactions.json")
        if let data = try? Data(contentsOf: self.queueURL), let saved = try? JSONDecoder().decode([Pending].self, from: data) {
            pending = saved
        }
    }

    deinit { listener?.cancel(); expiryTask?.cancel() }

    func configure(userID: String, accessToken: String) async {
        guard let id = UUID(uuidString: userID) else {
            clearAccount()
            entitlement = SubscriptionEntitlement(phase: .error, message: SubscriptionStoreError.invalidAccountIdentifier.localizedDescription)
            return
        }
        if self.userID != id {
            generation = UUID()
            if self.userID != id {
                entitlement = .loading
                purchaseIsPending = false
                isWorking = false
                errorMessage = nil
            }
        }
        self.userID = id
        self.accessToken = accessToken
        if AppLaunchEnvironment.usesSignedInUITestAccount {
            entitlement = SubscriptionEntitlement(phase: .active, expirationDate: .distantFuture, environment: "AppReview")
            return
        }
        if AppLaunchEnvironment.usesFreeUITestAccount || AppLaunchEnvironment.usesModeratorUITestAccount {
            entitlement = .notSubscribed
            return
        }
        startListener()
        await refresh()
    }

    func refresh() async {
        guard !AppLaunchEnvironment.isUITesting, let id = userID else { return }
        let context = generation
        do {
            let loaded = try await storeKit.loadProduct()
            guard generation == context else { return }
            product = loaded
            if loaded == nil { errorMessage = SubscriptionStoreError.productUnavailable.localizedDescription }
        } catch { if generation == context { errorMessage = error.localizedDescription } }
        guard generation == context else { return }
        do {
            let transactions = try await storeKit.currentTransactions()
            guard generation == context else { return }
            for value in transactions.sorted(by: { ($0.entitlement.verifiedAt ?? .distantPast) < ($1.entitlement.verifiedAt ?? .distantPast) }) {
                await consume(value, user: id, context: context, allowRestore: false)
            }
        } catch { if generation == context { errorMessage = error.localizedDescription } }
        guard generation == context else { return }
        for item in pending.filter({ $0.userID == id }) {
            await reconcile(item.transaction, user: id, context: context)
        }
        await fetchRemote(user: id, context: context)
        if generation == context {
            entitlement = entitlement.evaluated(at: now())
            if entitlement.phase == .loading { entitlement = .notSubscribed }
            scheduleExpiry()
        }
    }

    func purchase() async -> SubscriptionPurchaseOutcome? {
        guard !isWorking, !purchaseIsPending else { return nil }
        guard let id = userID else { fail(SubscriptionStoreError.accountUnavailable); return nil }
        guard product != nil else { fail(SubscriptionStoreError.productUnavailable); return nil }
        let context = generation
        isWorking = true; errorMessage = nil
        defer { if generation == context { isWorking = false } }
        do {
            switch try await storeKit.purchase(accountToken: id) {
            case .purchased(let value):
                // Persist for the purchasing account even if it signed out while Apple's sheet was open.
                guard value.accountToken == id else { throw SubscriptionStoreError.accountMismatch }
                try enqueue(value, user: id)
                await storeKit.finish(transactionID: value.id)
                guard generation == context else { return nil }
                await consume(value, user: id, context: context, allowRestore: false)
                purchaseIsPending = false
                return .purchased
            case .pending:
                guard generation == context else { return nil }
                purchaseIsPending = true; return .pending
            case .cancelled: return generation == context ? .cancelled : nil
            }
        } catch { if generation == context { fail(error) }; return nil }
    }

    func restorePurchases() async {
        guard !isWorking, let id = userID else { return }
        let context = generation
        isWorking = true; errorMessage = nil
        defer { if generation == context { isWorking = false } }
        do {
            try await storeKit.sync()
            let values = try await storeKit.currentTransactions()
            guard generation == context else { return }
            for value in values { await consume(value, user: id, context: context, allowRestore: true) }
            await fetchRemote(user: id, context: context)
        } catch { if generation == context { fail(error) } }
    }

    func clearAccount() {
        generation = UUID(); userID = nil; accessToken = nil
        entitlement = .notSubscribed; purchaseIsPending = false; isWorking = false; errorMessage = nil
        expiryTask?.cancel()
    }

    func removePendingTransactions(for userID: String) {
        pending.removeAll { $0.userID.uuidString.lowercased() == userID.lowercased() }
        try? persistQueue()
    }

    private func startListener() {
        guard listener == nil else { return }
        listener = Task { [weak self, storeKit] in
            for await result in storeKit.updates() {
                guard let self, !Task.isCancelled else { return }
                switch result {
                case .success(let value):
                    guard let id = self.userID else { continue }
                    await self.consume(value, user: id, context: self.generation, allowRestore: false)
                case .failure(let error): self.fail(error)
                }
            }
        }
    }

    private func consume(_ value: VerifiedSubscriptionTransaction, user: UUID, context: UUID, allowRestore: Bool) async {
        guard generation == context, value.productID == Self.premiumMonthlyProductID else { return }
        if value.accountToken == user {
            accept(value.entitlement)
        } else if !allowRestore {
            return // Never grant local access for another app account.
        }
        do { try enqueue(value, user: user) }
        catch { fail(error); return } // Leave unfinished transactions for StoreKit redelivery.
        await reconcile(value, user: user, context: context)
        await storeKit.finish(transactionID: value.id)
        if generation == context { purchaseIsPending = false }
    }

    private func authenticated<T>(user: UUID, operation: (String) async throws -> T) async throws -> T {
        let token = try await tokenProvider?(user, false) ?? accessToken
        guard let token, userID == user else { throw SubscriptionStoreError.accountUnavailable }
        do { return try await operation(token) }
        catch SubscriptionStoreError.authenticationRequired {
            guard let provider = tokenProvider else { throw SubscriptionStoreError.authenticationRequired }
            let fresh = try await provider(user, true)
            guard userID == user else { throw SubscriptionStoreError.accountUnavailable }
            return try await operation(fresh)
        }
    }

    private func fetchRemote(user: UUID, context: UUID) async {
        guard generation == context else { return }
        do {
            let remote = try await authenticated(user: user) { try await backend.fetchEntitlement(accessToken: $0) }
            guard generation == context else { return }
            accept(remote)
        } catch {
            guard generation == context else { return }
            entitlement = entitlement.evaluated(at: now())
            if errorMessage == nil { errorMessage = "Premium status could not sync. It will retry when you reopen the app or Premium." }
        }
    }

    private func reconcile(_ value: VerifiedSubscriptionTransaction, user: UUID, context: UUID) async {
        guard generation == context else { return }
        do {
            let remote = try await authenticated(user: user) { try await backend.reconcile(signedTransaction: value.signedTransaction, accessToken: $0) }
            guard generation == context else { return }
            pending.removeAll { $0.userID == user && $0.transaction.id == value.id && $0.transaction.signedTransaction == value.signedTransaction }
            try persistQueue()
            accept(remote); errorMessage = nil
        } catch SubscriptionStoreError.accountMismatch {
            guard generation == context else { return }
            pending.removeAll { $0.userID == user && $0.transaction.id == value.id }
            try? persistQueue()
            entitlement = .notSubscribed
            fail(SubscriptionStoreError.accountMismatch)
        } catch {
            guard generation == context else { return }
            entitlement = entitlement.evaluated(at: now())
            errorMessage = hasPremiumAccess ? "Your purchase is active here. Account synchronization will retry." : "Premium could not sync. Please try Restore Purchases again when connected."
        }
    }

    private func accept(_ candidate: SubscriptionEntitlement) {
        let evaluated = candidate.evaluated(at: now())
        let isOverride = candidate.environment == "AppReview" || candidate.environment == "SupportOverride"
        if !isOverride, let localDate = entitlement.verifiedAt,
           (candidate.verifiedAt ?? .distantPast) < localDate { return }
        if candidate.phase == .notSubscribed && entitlement.grantsAccess(at: now()),
           entitlement.environment != "AppReview", entitlement.environment != "SupportOverride" { return }
        entitlement = evaluated
        scheduleExpiry()
    }

    private func enqueue(_ value: VerifiedSubscriptionTransaction, user: UUID) throws {
        if let existing = pending.first(where: { $0.userID == user && $0.transaction.id == value.id }),
           (existing.transaction.entitlement.verifiedAt ?? .distantPast) > (value.entitlement.verifiedAt ?? .distantPast) { return }
        pending.removeAll { $0.userID == user && $0.transaction.id == value.id }
        pending.append(Pending(userID: user, transaction: value))
        try persistQueue()
    }

    private func persistQueue() throws {
        try FileManager.default.createDirectory(at: queueURL.deletingLastPathComponent(), withIntermediateDirectories: true)
        try JSONEncoder().encode(pending).write(to: queueURL, options: [.atomic, .completeFileProtectionUntilFirstUserAuthentication])
    }

    private func scheduleExpiry() {
        expiryTask?.cancel()
        let deadline = entitlement.phase == .gracePeriod ? entitlement.gracePeriodExpirationDate : entitlement.expirationDate
        guard let deadline, deadline > now() else { return }
        let context = generation
        let seconds = min(deadline.timeIntervalSince(now()), 86400)
        expiryTask = Task { [weak self] in
            do { try await Task.sleep(for: .seconds(seconds)) } catch { return }
            guard let self, self.generation == context else { return }
            self.entitlement = self.entitlement.evaluated(at: self.now())
            self.scheduleExpiry()
        }
    }

    private func fail(_ error: Error) {
        errorMessage = error.localizedDescription
        if !hasPremiumAccess { entitlement = SubscriptionEntitlement(phase: .error, message: error.localizedDescription) }
    }
}
