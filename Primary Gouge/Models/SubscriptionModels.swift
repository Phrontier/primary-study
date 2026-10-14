import Foundation

enum SubscriptionEntitlementPhase: String, Codable, Hashable {
    case loading
    case notSubscribed = "not_subscribed"
    case active
    case billingRetry = "billing_retry"
    case gracePeriod = "grace_period"
    case expired
    case error
}

struct SubscriptionEntitlement: Codable, Hashable {
    var phase: SubscriptionEntitlementPhase
    var productID: String? = nil
    var expirationDate: Date? = nil
    var willAutoRenew: Bool? = nil
    var environment: String? = nil
    var message: String? = nil
    var gracePeriodExpirationDate: Date? = nil
    var verifiedAt: Date? = nil

    static let loading = SubscriptionEntitlement(phase: .loading)
    static let notSubscribed = SubscriptionEntitlement(phase: .notSubscribed)

    var hasPremiumAccess: Bool {
        grantsAccess(at: .now)
    }

    func grantsAccess(at date: Date) -> Bool {
        switch phase {
        case .active:
            if environment == "AppReview" || environment == "SupportOverride" {
                return expirationDate.map { $0 > date } ?? true
            }
            return expirationDate.map { $0 > date } ?? false
        case .gracePeriod:
            return gracePeriodExpirationDate.map { $0 > date } ?? false
        default:
            return false
        }
    }

    func evaluated(at date: Date) -> Self {
        guard (phase == .active || phase == .gracePeriod), !grantsAccess(at: date) else { return self }
        var result = self
        result.phase = .expired
        return result
    }
}

enum SubscriptionPurchaseOutcome: Equatable {
    case purchased
    case pending
    case cancelled
}

enum SubscriptionStoreError: LocalizedError, Equatable {
    case accountUnavailable
    case invalidAccountIdentifier
    case productUnavailable
    case transactionUnverified
    case accountMismatch
    case authenticationRequired
    case backendRejected(String)

    var errorDescription: String? {
        switch self {
        case .accountUnavailable:
            return "Sign in to your Primary Gouge account to manage Premium."
        case .invalidAccountIdentifier:
            return "Your account could not be linked to an App Store purchase. Sign out and back in, then try again."
        case .productUnavailable:
            return "Premium is not available from the App Store right now."
        case .transactionUnverified:
            return "The App Store could not verify this transaction."
        case .accountMismatch:
            return "This subscription is linked to another Primary Gouge account. Sign in with the account that originally purchased Premium."
        case .authenticationRequired:
            return "Sign in again to synchronize Premium."
        case .backendRejected(let message):
            return message
        }
    }
}
