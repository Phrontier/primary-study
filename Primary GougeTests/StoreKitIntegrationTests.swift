import XCTest
import StoreKitTest
@testable import Primary_Gouge

@MainActor
final class StoreKitIntegrationTests: XCTestCase {
    func testRealStoreKitPurchaseRenewalRestoreExpiryAndRefund() async throws {
        executionTimeAllowance = 60
        let session = try SKTestSession(configurationFileNamed: "Configuration")
        session.resetToDefaultState()
        session.disableDialogs = true
        session.clearTransactions()
        defer { session.clearTransactions(); session.resetToDefaultState() }
        let user = UUID()
        let client = StoreKitClient()
        let info = try await client.loadProduct()
        XCTAssertNotNil(info)
        XCTAssertNotNil(info?.trialDescription)
        guard case .purchased(let purchase) = try await client.purchase(accountToken: user) else {
            XCTFail("StoreKit did not complete the local purchase"); return
        }
        XCTAssertEqual(purchase.accountToken, user)
        XCTAssertTrue(purchase.entitlement.hasPremiumAccess)
        XCTAssertFalse(purchase.signedTransaction.isEmpty)
        await client.finish(transactionID: purchase.id)

        let restored = StoreKitClient()
        _ = try await restored.loadProduct()
        let restoredValues = try await restored.currentTransactions()
        XCTAssertTrue(restoredValues.contains { $0.accountToken == user && $0.entitlement.hasPremiumAccess })

        let first = try XCTUnwrap(session.allTransactions().first)
        try session.disableAutoRenewForTransaction(identifier: first.identifier)
        try await assertEventually(client) { $0.accountToken == user && $0.entitlement.willAutoRenew == false && $0.entitlement.hasPremiumAccess }
        try session.forceRenewalOfSubscription(productIdentifier: SubscriptionStore.premiumMonthlyProductID)
        try await assertEventually(client) { $0.id != purchase.id && $0.accountToken == user && $0.entitlement.hasPremiumAccess }
        try session.expireSubscription(productIdentifier: SubscriptionStore.premiumMonthlyProductID)
        try await assertEventually(client) { $0.entitlement.phase == .expired && !$0.entitlement.hasPremiumAccess }

        session.clearTransactions()
        _ = try await client.loadProduct()
        guard case .purchased(let second) = try await client.purchase(accountToken: user) else {
            XCTFail("Second StoreKit purchase failed"); return
        }
        let secondTestTransaction = try XCTUnwrap(session.allTransactions().first)
        try session.refundTransaction(identifier: secondTestTransaction.identifier)
        try await assertEventually(client) { $0.id == second.id && $0.entitlement.phase == .expired && !$0.entitlement.hasPremiumAccess }
    }

    private func assertEventually(_ client: StoreKitClient, matching predicate: (VerifiedSubscriptionTransaction) -> Bool) async throws {
        for _ in 0..<30 {
            if try await client.currentTransactions().contains(where: predicate) { return }
            try await Task.sleep(for: .milliseconds(100))
        }
        XCTFail("StoreKit did not reach the expected subscription state within three seconds")
    }
}
