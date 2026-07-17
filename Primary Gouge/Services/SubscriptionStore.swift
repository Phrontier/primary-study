import Combine
import Foundation
import StoreKit

@MainActor
final class SubscriptionStore: ObservableObject {
    static let premiumMonthlyProductID = "bolt.primarygouge.premium.monthly"

    @Published private(set) var entitlement: SubscriptionEntitlement = .loading
    @Published private(set) var product: Product?
    @Published private(set) var isWorking = false
    @Published private(set) var purchaseIsPending = false
    @Published var errorMessage: String?

    var hasPremiumAccess: Bool { entitlement.hasPremiumAccess }
    var displayPrice: String { product?.displayPrice ?? "$6.99" }
    var isPurchaseLaunchEnabled: Bool { product != nil }

    var trialDescription: String? {
        guard let offer = product?.subscription?.introductoryOffer else { return nil }
        let period = offer.period
        guard offer.paymentMode == .freeTrial else { return nil }
        return "\(period.value)-\(period.unit.displayName) free trial"
    }

    private let backend: SubscriptionBackendServing
    private var userID: UUID?
    private var accessToken: String?
    private var transactionListener: Task<Void, Never>?
    private var didStart = false

    init(backend: SubscriptionBackendServing? = nil) {
        self.backend = backend ?? SubscriptionBackendClient()
    }

    deinit {
        transactionListener?.cancel()
    }

    func configure(userID: String, accessToken: String) async {
        guard let accountToken = UUID(uuidString: userID) else {
            entitlement = SubscriptionEntitlement(
                phase: .error,
                message: SubscriptionStoreError.invalidAccountIdentifier.localizedDescription
            )
            return
        }

        let accountChanged = self.userID != accountToken
        self.userID = accountToken
        self.accessToken = accessToken

        if AppLaunchEnvironment.usesSignedInUITestAccount {
            entitlement = SubscriptionEntitlement(
                phase: .active,
                productID: Self.premiumMonthlyProductID,
                expirationDate: .distantFuture,
                willAutoRenew: false,
                environment: "AppReview",
                message: nil
            )
            product = nil
            errorMessage = nil
            return
        }
        if AppLaunchEnvironment.usesFreeUITestAccount {
            entitlement = .notSubscribed
            product = nil
            errorMessage = nil
            return
        }
        if accountChanged {
            entitlement = .loading
            purchaseIsPending = false
            errorMessage = nil
        }

        startTransactionListenerIfNeeded()
        await loadProductsIfNeeded()
        await refresh()
    }

    func refresh() async {
        if AppLaunchEnvironment.usesSignedInUITestAccount || AppLaunchEnvironment.usesFreeUITestAccount { return }
        guard userID != nil, accessToken != nil else { return }
        await refreshLocalEntitlement()
        await refreshBackendEntitlement()
    }

    func purchase() async -> SubscriptionPurchaseOutcome? {
        guard isPurchaseLaunchEnabled else {
            set(error: SubscriptionStoreError.productUnavailable, updateEntitlement: false)
            return nil
        }
        guard let product else {
            set(error: SubscriptionStoreError.productUnavailable)
            return nil
        }
        guard let userID else {
            set(error: SubscriptionStoreError.accountUnavailable)
            return nil
        }

        isWorking = true
        errorMessage = nil
        defer { isWorking = false }

        do {
            let result = try await product.purchase(options: [.appAccountToken(userID)])
            switch result {
            case .success(let verification):
                let transaction = try verified(verification)
                apply(transaction: transaction, phase: .active)
                await reconcile(transaction, signedTransaction: verification.jwsRepresentation)
                await transaction.finish()
                purchaseIsPending = false
                await refresh()
                return .purchased
            case .pending:
                purchaseIsPending = true
                return .pending
            case .userCancelled:
                return .cancelled
            @unknown default:
                return .cancelled
            }
        } catch {
            set(error: error)
            return nil
        }
    }

    func restorePurchases() async {
        guard userID != nil else {
            set(error: SubscriptionStoreError.accountUnavailable)
            return
        }

        isWorking = true
        errorMessage = nil
        defer { isWorking = false }

        do {
            try await AppStore.sync()
            await refreshLocalEntitlement(reconcileTransactions: true)
            await refreshBackendEntitlement()
        } catch {
            set(error: error)
        }
    }

    func clearAccount() {
        userID = nil
        accessToken = nil
        entitlement = .notSubscribed
        purchaseIsPending = false
        errorMessage = nil
    }

    private func loadProductsIfNeeded() async {
        guard product == nil else { return }
        do {
            product = try await Product.products(for: [Self.premiumMonthlyProductID]).first
            if product == nil {
                set(error: SubscriptionStoreError.productUnavailable, updateEntitlement: false)
            }
        } catch {
            set(error: error, updateEntitlement: false)
        }
    }

    private func startTransactionListenerIfNeeded() {
        guard !didStart else { return }
        didStart = true
        transactionListener = Task { [weak self] in
            for await result in Transaction.updates {
                guard !Task.isCancelled, let self else { return }
                do {
                    let transaction = try self.verified(result)
                    guard transaction.productID == Self.premiumMonthlyProductID else {
                        continue
                    }
                    await self.handle(transaction, signedTransaction: result.jwsRepresentation)
                } catch {
                    self.set(error: error)
                }
            }
        }
    }

    private func handle(_ transaction: Transaction, signedTransaction: String) async {
        guard transaction.appAccountToken == userID else {
            set(error: SubscriptionStoreError.accountMismatch)
            return
        }

        apply(transaction: transaction, phase: localPhase(for: transaction))
        await reconcile(transaction, signedTransaction: signedTransaction)
        await transaction.finish()
        purchaseIsPending = false
        await refreshBackendEntitlement()
    }

    private func refreshLocalEntitlement(reconcileTransactions: Bool = true) async {
        guard let userID else { return }
        var matchedTransaction: Transaction?

        for await result in Transaction.currentEntitlements {
            guard let transaction = try? verified(result),
                  transaction.productID == Self.premiumMonthlyProductID else { continue }

            guard transaction.appAccountToken == userID else {
                set(error: SubscriptionStoreError.accountMismatch)
                continue
            }
            matchedTransaction = transaction
            apply(transaction: transaction, phase: localPhase(for: transaction))
            if reconcileTransactions {
                await reconcile(transaction, signedTransaction: result.jwsRepresentation)
            }
        }

        if matchedTransaction == nil, entitlement.phase == .loading {
            entitlement = .notSubscribed
        }

        await applySubscriptionStatusIfAvailable()
    }

    private func applySubscriptionStatusIfAvailable() async {
        guard let product, let statuses = try? await product.subscription?.status else { return }
        guard let status = statuses.first else { return }

        let renewalInfo = try? verified(status.renewalInfo)
        let transaction = try? verified(status.transaction)
        guard transaction?.appAccountToken == userID else { return }

        let phase: SubscriptionEntitlementPhase
        switch status.state {
        case .subscribed:
            phase = .active
        case .inGracePeriod:
            phase = .gracePeriod
        case .inBillingRetryPeriod:
            phase = .billingRetry
        case .expired, .revoked:
            phase = .expired
        default:
            phase = .notSubscribed
        }

        entitlement = SubscriptionEntitlement(
            phase: phase,
            productID: transaction?.productID ?? Self.premiumMonthlyProductID,
            expirationDate: transaction?.expirationDate,
            willAutoRenew: renewalInfo?.willAutoRenew,
            environment: transaction.map { String(describing: $0.environment).lowercased() },
            message: nil
        )
    }

    private func refreshBackendEntitlement() async {
        guard let accessToken else { return }
        do {
            let remote = try await backend.fetchEntitlement(accessToken: accessToken)
            if !entitlement.hasPremiumAccess || remote.hasPremiumAccess || remote.phase == .expired {
                entitlement = remote
            }
        } catch {
            // A verified StoreKit entitlement remains usable offline. Surface sync
            // errors without replacing valid local access.
            errorMessage = "Premium status could not sync with your account. It will retry automatically."
            if entitlement.phase == .loading {
                entitlement = .notSubscribed
            }
        }
    }

    private func reconcile(_ transaction: Transaction, signedTransaction: String) async {
        guard let accessToken else { return }
        do {
            let remote = try await backend.reconcile(
                signedTransaction: signedTransaction,
                accessToken: accessToken
            )
            entitlement = remote
            errorMessage = nil
        } catch SubscriptionStoreError.accountMismatch {
            set(error: SubscriptionStoreError.accountMismatch)
        } catch {
            errorMessage = "Your purchase is active on this device and will sync to your account when the connection returns."
        }
    }

    private func apply(transaction: Transaction, phase: SubscriptionEntitlementPhase) {
        entitlement = SubscriptionEntitlement(
            phase: phase,
            productID: transaction.productID,
            expirationDate: transaction.expirationDate,
            willAutoRenew: entitlement.willAutoRenew,
            environment: String(describing: transaction.environment).lowercased(),
            message: nil
        )
    }

    private func localPhase(for transaction: Transaction) -> SubscriptionEntitlementPhase {
        if transaction.revocationDate != nil { return .expired }
        if let expirationDate = transaction.expirationDate, expirationDate <= .now { return .expired }
        return .active
    }

    private func verified<T>(_ result: VerificationResult<T>) throws -> T {
        switch result {
        case .verified(let value):
            return value
        case .unverified:
            throw SubscriptionStoreError.transactionUnverified
        }
    }

    private func set(error: Error, updateEntitlement: Bool = true) {
        errorMessage = error.localizedDescription
        if updateEntitlement && !entitlement.hasPremiumAccess {
            entitlement = SubscriptionEntitlement(phase: .error, message: error.localizedDescription)
        }
    }
}

private extension Product.SubscriptionPeriod.Unit {
    var displayName: String {
        switch self {
        case .day: "day"
        case .week: "week"
        case .month: "month"
        case .year: "year"
        @unknown default: "period"
        }
    }
}
