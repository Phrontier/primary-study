import Foundation
import Testing
@testable import Primary_Gouge

@MainActor
struct SubscriptionLifecycleTests {
    private let user = UUID(uuidString: "AAAAAAAA-AAAA-4AAA-8AAA-AAAAAAAAAAAA")!
    private let other = UUID(uuidString: "BBBBBBBB-BBBB-4BBB-8BBB-BBBBBBBBBBBB")!

    private func transaction(owner: UUID? = nil, phase: SubscriptionEntitlementPhase = .active,
                             expiration: Date = .now.addingTimeInterval(3600), signed: Date = .now) -> VerifiedSubscriptionTransaction {
        VerifiedSubscriptionTransaction(id: 42, productID: SubscriptionStore.premiumMonthlyProductID,
            accountToken: owner ?? user, signedTransaction: "signed-42",
            entitlement: SubscriptionEntitlement(phase: phase, productID: SubscriptionStore.premiumMonthlyProductID,
                expirationDate: expiration, willAutoRenew: true, environment: "sandbox", verifiedAt: signed))
    }
    private func store(_ kit: FakeStoreKit, _ backend: FakeSubscriptionBackend, url: URL? = nil) -> SubscriptionStore {
        SubscriptionStore(backend: backend, storeKit: kit,
            queueURL: url ?? FileManager.default.temporaryDirectory.appending(path: UUID().uuidString + "/queue.json"))
    }

    @Test func missingDeadlinesAndExpiredAccessFailClosed() {
        let now = Date(timeIntervalSince1970: 1000)
        #expect(!SubscriptionEntitlement(phase: .active).grantsAccess(at: now))
        #expect(!SubscriptionEntitlement(phase: .gracePeriod).grantsAccess(at: now))
        #expect(!SubscriptionEntitlement(phase: .active, expirationDate: now).grantsAccess(at: now))
        #expect(SubscriptionEntitlement(phase: .gracePeriod, expirationDate: now.addingTimeInterval(-10), gracePeriodExpirationDate: now.addingTimeInterval(10)).grantsAccess(at: now))
        #expect(!SubscriptionEntitlement(phase: .gracePeriod, gracePeriodExpirationDate: now).grantsAccess(at: now))
        #expect(!SubscriptionEntitlement(phase: .billingRetry, expirationDate: .distantFuture).grantsAccess(at: now))
        #expect(SubscriptionEntitlement(phase: .active, environment: "AppReview").grantsAccess(at: now))
    }

    @Test func purchasesUnlockAndPersistBeforeFinish() async {
        let kit = FakeStoreKit(), backend = FakeSubscriptionBackend()
        kit.result = .purchased(transaction()); backend.remote = transaction().entitlement
        let subject = store(kit, backend)
        await subject.configure(userID: user.uuidString, accessToken: "token")
        #expect(await subject.purchase() == .purchased)
        #expect(subject.hasPremiumAccess)
        #expect(kit.purchasedToken == user)
        #expect(kit.finished.contains(42))
        #expect(backend.reconciled.contains("signed-42"))
    }

    @Test func cancellationAndPendingDoNotUnlock() async {
        let kit = FakeStoreKit(), backend = FakeSubscriptionBackend(), subject = store(kit, backend)
        await subject.configure(userID: user.uuidString, accessToken: "token")
        #expect(await subject.purchase() == .cancelled)
        #expect(!subject.hasPremiumAccess)
        kit.result = .pending
        #expect(await subject.purchase() == .pending)
        #expect(subject.purchaseIsPending)
        #expect(await subject.purchase() == nil)
        subject.clearAccount()
        #expect(!subject.purchaseIsPending)
    }

    @Test func unavailableAndUnverifiedPurchasesDoNotUnlock() async {
        let kit = FakeStoreKit(), backend = FakeSubscriptionBackend()
        kit.info = nil
        let subject = store(kit, backend)
        await subject.configure(userID: user.uuidString, accessToken: "token")
        #expect(!subject.isPurchaseLaunchEnabled)
        #expect(await subject.purchase() == nil)
        kit.info = SubscriptionProductInfo(displayPrice: "£5.99", trialDescription: nil)
        await subject.refresh()
        #expect(subject.displayPrice == "£5.99")
        #expect(subject.trialDescription == nil)
        kit.purchaseError = SubscriptionStoreError.transactionUnverified
        #expect(await subject.purchase() == nil)
        #expect(!subject.hasPremiumAccess)
    }

    @Test func queueRetriesAfterRelaunchWithoutCrossingAccounts() async {
        let url = FileManager.default.temporaryDirectory.appending(path: UUID().uuidString + "/queue.json")
        let kit = FakeStoreKit(), backend = FakeSubscriptionBackend()
        backend.failure = URLError(.notConnectedToInternet); kit.result = .purchased(transaction())
        let first = store(kit, backend, url: url)
        await first.configure(userID: user.uuidString, accessToken: "token")
        #expect(await first.purchase() == .purchased)
        #expect(first.hasPremiumAccess)
        first.clearAccount()
        let nextBackend = FakeSubscriptionBackend(); nextBackend.remote = transaction().entitlement
        let next = store(FakeStoreKit(), nextBackend, url: url)
        await next.configure(userID: other.uuidString, accessToken: "other")
        #expect(nextBackend.reconciled.isEmpty)
        next.clearAccount()
        await next.configure(userID: user.uuidString, accessToken: "token")
        #expect(nextBackend.reconciled == ["signed-42"])
        #expect(next.hasPremiumAccess)
        #expect((try? JSONSerialization.jsonObject(with: Data(contentsOf: url)) as? [Any])?.isEmpty == true)
    }

    @Test func deletedAccountRestoreRequiresServerAcceptance() async {
        let kit = FakeStoreKit(), backend = FakeSubscriptionBackend()
        kit.values = [transaction(owner: other)]
        let subject = store(kit, backend)
        await subject.configure(userID: user.uuidString, accessToken: "token")
        #expect(!subject.hasPremiumAccess)
        #expect(backend.reconciled.isEmpty)
        backend.remote = transaction().entitlement
        await subject.restorePurchases()
        #expect(subject.hasPremiumAccess)
        #expect(kit.syncCalls == 1)
        backend.failure = SubscriptionStoreError.accountMismatch
        await subject.restorePurchases()
        #expect(!subject.hasPremiumAccess)
        #expect(subject.errorMessage == SubscriptionStoreError.accountMismatch.localizedDescription)
    }

    @Test func renewalCancellationGraceRetryExpiryAndRefund() async {
        let kit = FakeStoreKit(), backend = FakeSubscriptionBackend()
        backend.failure = URLError(.notConnectedToInternet)
        let subject = store(kit, backend)
        await subject.configure(userID: user.uuidString, accessToken: "token")
        var value = transaction()
        value.entitlement.willAutoRenew = false
        kit.values = [value]; await subject.refresh()
        #expect(subject.hasPremiumAccess) // Cancelling renewal retains the paid period.
        for phase in [SubscriptionEntitlementPhase.gracePeriod, .billingRetry, .expired] {
            value.entitlement.phase = phase
            value.entitlement.verifiedAt = Date.now.addingTimeInterval(10)
            value.entitlement.gracePeriodExpirationDate = .now.addingTimeInterval(60)
            kit.values = [value]; await subject.refresh()
            #expect(subject.hasPremiumAccess == (phase == .gracePeriod))
        }
        value.entitlement = transaction(expiration: .now.addingTimeInterval(-1), signed: .now.addingTimeInterval(20)).entitlement
        kit.values = [value]; await subject.refresh()
        #expect(!subject.hasPremiumAccess)
    }

    @Test func oldPurchaseResponseDoesNotUnlockNewAccount() async {
        let kit = FakeStoreKit(), backend = FakeSubscriptionBackend(), subject = store(kit, backend)
        kit.result = .purchased(transaction()); kit.pausePurchase = true
        await subject.configure(userID: user.uuidString, accessToken: "token")
        let purchase = Task { await subject.purchase() }
        while kit.purchaseContinuation == nil { await Task.yield() }
        subject.clearAccount()
        await subject.configure(userID: other.uuidString, accessToken: "other")
        kit.purchaseContinuation?.resume(); kit.purchaseContinuation = nil
        #expect(await purchase.value == nil)
        #expect(!subject.hasPremiumAccess)
        #expect(backend.reconciled.isEmpty)
    }

    @Test func oldBackendResponseDoesNotUnlockNewAccount() async {
        let kit = FakeStoreKit(), backend = FakeSubscriptionBackend(), subject = store(kit, backend)
        backend.pauseFetch = true; backend.remote = transaction().entitlement
        let configure = Task { await subject.configure(userID: user.uuidString, accessToken: "old") }
        while backend.fetchContinuation == nil { await Task.yield() }
        subject.clearAccount()
        backend.pauseFetch = false; backend.remote = .notSubscribed
        await subject.configure(userID: other.uuidString, accessToken: "new")
        backend.fetchContinuation?.resume(); backend.fetchContinuation = nil
        await configure.value
        #expect(!subject.hasPremiumAccess)
    }

    @Test func authenticationRetriesOnlyOnce() async {
        let kit = FakeStoreKit(), backend = FakeSubscriptionBackend(), subject = store(kit, backend)
        backend.failure = SubscriptionStoreError.authenticationRequired
        var forces: [Bool] = []
        subject.tokenProvider = { _, force in forces.append(force); return force ? "fresh" : "old" }
        await subject.configure(userID: user.uuidString, accessToken: "old")
        #expect(forces == [false, true])
        #expect(backend.fetchTokens == ["old", "fresh"])
        #expect(!subject.hasPremiumAccess)
    }
}

@MainActor
private final class FakeStoreKit: StoreKitServing {
    var info: SubscriptionProductInfo? = SubscriptionProductInfo(displayPrice: "$5.99", trialDescription: "1-week free trial")
    var result: StoreKitPurchaseResult = .cancelled
    var values: [VerifiedSubscriptionTransaction] = []
    var purchaseError: Error?
    var purchasedToken: UUID?
    var finished: [UInt64] = []
    var syncCalls = 0
    var pausePurchase = false
    var purchaseContinuation: CheckedContinuation<Void, Never>?
    func loadProduct() async throws -> SubscriptionProductInfo? { info }
    func purchase(accountToken: UUID) async throws -> StoreKitPurchaseResult {
        purchasedToken = accountToken
        if pausePurchase { await withCheckedContinuation { purchaseContinuation = $0 } }
        if let purchaseError { throw purchaseError }
        return result
    }
    func sync() async throws { syncCalls += 1 }
    func currentTransactions() async throws -> [VerifiedSubscriptionTransaction] { values }
    func updates() -> AsyncStream<Result<VerifiedSubscriptionTransaction, Error>> { AsyncStream { $0.finish() } }
    func finish(transactionID: UInt64) async { finished.append(transactionID) }
}

@MainActor
private final class FakeSubscriptionBackend: SubscriptionBackendServing {
    var remote: SubscriptionEntitlement = .notSubscribed
    var failure: Error?
    var reconciled: [String] = []
    var fetchTokens: [String] = []
    var pauseFetch = false
    var fetchContinuation: CheckedContinuation<Void, Never>?
    func fetchEntitlement(accessToken: String) async throws -> SubscriptionEntitlement {
        fetchTokens.append(accessToken)
        let result = remote
        if pauseFetch { await withCheckedContinuation { fetchContinuation = $0 } }
        if let failure { throw failure }
        return result
    }
    func reconcile(signedTransaction: String, accessToken: String) async throws -> SubscriptionEntitlement {
        reconciled.append(signedTransaction)
        if let failure { throw failure }
        return remote
    }
}
