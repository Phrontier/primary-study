import Foundation
import StoreKit

struct SubscriptionProductInfo: Equatable {
    let displayPrice: String
    let trialDescription: String?
}

struct VerifiedSubscriptionTransaction: Codable, Equatable {
    let id: UInt64
    let productID: String
    let accountToken: UUID?
    let signedTransaction: String
    var entitlement: SubscriptionEntitlement
}

enum StoreKitPurchaseResult {
    case purchased(VerifiedSubscriptionTransaction)
    case pending
    case cancelled
}

@MainActor
protocol StoreKitServing {
    func loadProduct() async throws -> SubscriptionProductInfo?
    func purchase(accountToken: UUID) async throws -> StoreKitPurchaseResult
    func sync() async throws
    func currentTransactions() async throws -> [VerifiedSubscriptionTransaction]
    func updates() -> AsyncStream<Result<VerifiedSubscriptionTransaction, Error>>
    func finish(transactionID: UInt64) async
}

@MainActor
final class StoreKitClient: StoreKitServing {
    private var product: Product?
    private var transactions: [UInt64: Transaction] = [:]

    func loadProduct() async throws -> SubscriptionProductInfo? {
        product = try await Product.products(for: [SubscriptionStore.premiumMonthlyProductID]).first
        guard let product else { return nil }
        var trial: String?
        if let subscription = product.subscription,
           await subscription.isEligibleForIntroOffer,
           let offer = subscription.introductoryOffer, offer.paymentMode == .freeTrial {
            let unit: String
            switch offer.period.unit {
            case .day: unit = "day"
            case .week: unit = "week"
            case .month: unit = "month"
            case .year: unit = "year"
            @unknown default: unit = "period"
            }
            trial = "\(offer.period.value)-\(unit) free trial"
        }
        return SubscriptionProductInfo(displayPrice: product.displayPrice, trialDescription: trial)
    }

    func purchase(accountToken: UUID) async throws -> StoreKitPurchaseResult {
        guard let product else { throw SubscriptionStoreError.productUnavailable }
        switch try await product.purchase(options: [.appAccountToken(accountToken)]) {
        case .success(let result): return .purchased(try snapshot(result))
        case .pending: return .pending
        case .userCancelled: return .cancelled
        @unknown default: return .cancelled
        }
    }

    func sync() async throws { try await AppStore.sync() }

    func currentTransactions() async throws -> [VerifiedSubscriptionTransaction] {
        var snapshots: [UInt64: VerifiedSubscriptionTransaction] = [:]
        for await result in Transaction.currentEntitlements {
            let value = try snapshot(result)
            snapshots[value.id] = value
        }
        // Status also reports expired/revoked subscriptions and the grace deadline.
        if let statuses = try await product?.subscription?.status {
            for status in statuses {
                var value = try snapshot(status.transaction)
                let renewal = try verified(status.renewalInfo)
                value.entitlement.verifiedAt = max(value.entitlement.verifiedAt ?? .distantPast, renewal.signedDate)
                value.entitlement.willAutoRenew = renewal.willAutoRenew
                value.entitlement.gracePeriodExpirationDate = renewal.gracePeriodExpirationDate
                switch status.state {
                case .subscribed: value.entitlement.phase = .active
                case .inGracePeriod: value.entitlement.phase = .gracePeriod
                case .inBillingRetryPeriod: value.entitlement.phase = .billingRetry
                case .expired, .revoked: value.entitlement.phase = .expired
                default: value.entitlement.phase = .notSubscribed
                }
                snapshots[value.id] = value
            }
        }
        return Array(snapshots.values)
    }

    func updates() -> AsyncStream<Result<VerifiedSubscriptionTransaction, Error>> {
        AsyncStream { continuation in
            let task = Task { [weak self] in
                for await result in Transaction.updates {
                    guard !Task.isCancelled, let self else { break }
                    do { continuation.yield(.success(try self.snapshot(result))) }
                    catch { continuation.yield(.failure(error)) }
                }
                continuation.finish()
            }
            continuation.onTermination = { _ in task.cancel() }
        }
    }

    func finish(transactionID: UInt64) async {
        await transactions[transactionID]?.finish()
        transactions.removeValue(forKey: transactionID)
    }

    private func snapshot(_ result: VerificationResult<Transaction>) throws -> VerifiedSubscriptionTransaction {
        let transaction = try verified(result)
        transactions[transaction.id] = transaction
        return VerifiedSubscriptionTransaction(
            id: transaction.id, productID: transaction.productID,
            accountToken: transaction.appAccountToken, signedTransaction: result.jwsRepresentation,
            entitlement: SubscriptionEntitlement(
                phase: transaction.revocationDate == nil ? .active : .expired,
                productID: transaction.productID, expirationDate: transaction.expirationDate,
                environment: String(describing: transaction.environment).lowercased(),
                verifiedAt: transaction.signedDate
            )
        )
    }

    private func verified<T>(_ result: VerificationResult<T>) throws -> T {
        guard case .verified(let value) = result else { throw SubscriptionStoreError.transactionUnverified }
        return value
    }
}
