import XCTest

final class Primary_GougeUITests: XCTestCase {
    override func setUpWithError() throws {
        continueAfterFailure = false
    }

    @MainActor
    func testSignedOutLaunchRequiresAccount() throws {
        let app = XCUIApplication()
        app.launchArguments = ["--ui-testing", "--ui-testing-signed-out"]
        app.launch()

        XCTAssertTrue(app.descendants(matching: .any)["account-sign-in-screen"].waitForExistence(timeout: 10))
        XCTAssertTrue(app.staticTexts["Primary Gouge"].exists)
        XCTAssertTrue(app.buttons["Sign up with Email"].exists)
        XCTAssertTrue(app.buttons.matching(NSPredicate(format: "label CONTAINS[c] 'Apple'")).firstMatch.exists)
    }

    @MainActor
    func testAppReviewAccountCanReachPremiumAndCoreContent() throws {
        let app = XCUIApplication()
        app.launchArguments = ["--ui-testing", "--ui-testing-signed-in"]
        app.launch()

        XCTAssertTrue(app.tabBars.buttons["Events"].waitForExistence(timeout: 15))
        app.tabBars.buttons["Events"].tap()
        XCTAssertTrue(app.staticTexts["Start your next event"].waitForExistence(timeout: 10))

        app.tabBars.buttons["More"].tap()
        let premiumCard = app.buttons.matching(NSPredicate(format: "label CONTAINS[c] 'Premium' AND label CONTAINS[c] 'active'")).firstMatch
        XCTAssertTrue(premiumCard.waitForExistence(timeout: 10))
        premiumCard.tap()

        XCTAssertTrue(app.descendants(matching: .any)["premium-status"].waitForExistence(timeout: 10))
        XCTAssertTrue(app.staticTexts["Premium is active"].exists)
    }

    @MainActor
    func testFreeAccountCanUseFreeTierAndSeesPremiumLocks() throws {
        let app = XCUIApplication()
        app.launchArguments = ["--ui-testing", "--ui-testing-free-account"]
        app.launch()

        XCTAssertTrue(app.tabBars.buttons["Home"].waitForExistence(timeout: 15))
        XCTAssertTrue(app.staticTexts["EPs / Limits / N/W/C"].exists)
        XCTAssertTrue(app.staticTexts["Question of the day"].waitForExistence(timeout: 10))

        let emergencyReference = app.buttons.matching(NSPredicate(format: "label CONTAINS[c] 'EPs / Limits / N/W/C'")).firstMatch
        XCTAssertTrue(emergencyReference.exists)
        emergencyReference.tap()
        XCTAssertTrue(app.staticTexts["EPs, Limits, N/W/C Flashcards"].waitForExistence(timeout: 10))
        XCTAssertFalse(app.descendants(matching: .any)["premium-content-gate"].exists)

        app.tabBars.buttons["Events"].tap()
        XCTAssertTrue(app.staticTexts["Start your next event"].waitForExistence(timeout: 10))
        app.buttons["Contacts"].tap()
        app.buttons["Sims"].tap()

        let fam2101 = app.buttons.matching(NSPredicate(format: "label CONTAINS[c] 'FAM2101'")).firstMatch
        XCTAssertTrue(fam2101.waitForExistence(timeout: 10))
        fam2101.tap()
        XCTAssertTrue(app.staticTexts["Cockpit Familiarization"].waitForExistence(timeout: 10))
        XCTAssertFalse(app.descendants(matching: .any)["premium-content-gate"].exists)

        app.navigationBars.buttons.firstMatch.tap()
        let fam2102 = app.buttons.matching(NSPredicate(format: "label CONTAINS[c] 'FAM2102'")).firstMatch
        XCTAssertTrue(fam2102.waitForExistence(timeout: 10))
        fam2102.tap()
        XCTAssertTrue(app.staticTexts["Ground Emergencies"].waitForExistence(timeout: 10))
        XCTAssertFalse(app.descendants(matching: .any)["premium-content-gate"].exists)

        app.navigationBars.buttons.firstMatch.tap()
        app.navigationBars.buttons.firstMatch.tap()
        app.buttons["Ground School"].tap()
        XCTAssertTrue(app.staticTexts["Familiarization Flight Orientation"].waitForExistence(timeout: 10))
        XCTAssertFalse(app.descendants(matching: .any)["premium-content-gate"].exists)

        app.navigationBars.buttons.firstMatch.tap()
        app.buttons["Sims"].tap()
        let fam2103 = app.buttons.matching(NSPredicate(format: "label CONTAINS[c] 'FAM2103' AND label CONTAINS[c] 'Premium locked'")).firstMatch
        XCTAssertTrue(fam2103.waitForExistence(timeout: 10))
        fam2103.tap()
        XCTAssertTrue(app.descendants(matching: .any)["premium-content-gate"].waitForExistence(timeout: 10))
        XCTAssertTrue(app.staticTexts.matching(NSPredicate(format: "label CONTAINS[c] 'Unlock FAM2103'")).firstMatch.exists)

        app.tabBars.buttons["Instructors"].tap()
        XCTAssertFalse(app.descendants(matching: .any)["premium-content-gate"].exists)
    }

    @MainActor
    func testFreeAccountSearchAndMoreCannotBypassPremium() throws {
        let app = XCUIApplication()
        app.launchArguments = ["--ui-testing", "--ui-testing-free-account"]
        app.launch()

        XCTAssertTrue(app.tabBars.buttons["Search"].waitForExistence(timeout: 15))
        app.tabBars.buttons["Search"].tap()
        let searchField = app.textFields.firstMatch
        XCTAssertTrue(searchField.waitForExistence(timeout: 10))
        searchField.tap()
        searchField.typeText("FAM2103")

        let lockedSearchResult = app.buttons.matching(
            NSPredicate(format: "label CONTAINS[c] 'FAM2103' AND label CONTAINS[c] 'Premium locked'")
        ).firstMatch
        XCTAssertTrue(lockedSearchResult.waitForExistence(timeout: 10))
        lockedSearchResult.tap()
        XCTAssertTrue(app.descendants(matching: .any)["premium-content-gate"].waitForExistence(timeout: 10))

        app.tabBars.buttons["More"].tap()
        XCTAssertTrue(app.buttons.matching(NSPredicate(format: "label CONTAINS[c] 'Profile'")).firstMatch.waitForExistence(timeout: 10))
        let quizMode = app.buttons.matching(
            NSPredicate(format: "label CONTAINS[c] 'Quiz Mode' AND label CONTAINS[c] 'Premium locked'")
        ).firstMatch
        XCTAssertTrue(quizMode.waitForExistence(timeout: 10))
        quizMode.tap()
        XCTAssertTrue(app.descendants(matching: .any)["premium-content-gate"].waitForExistence(timeout: 10))
    }

    @MainActor
    func testMoreArticlesAndFeatureRequestCharacterGuidance() throws {
        let app = XCUIApplication()
        app.launchArguments = ["--ui-testing", "--ui-testing-signed-in"]
        app.launch()

        XCTAssertTrue(app.tabBars.buttons["More"].waitForExistence(timeout: 15))
        app.tabBars.buttons["More"].tap()

        let faq = app.buttons.matching(NSPredicate(format: "label CONTAINS[c] 'FAQ'")).firstMatch
        XCTAssertTrue(faq.waitForExistence(timeout: 10))
        faq.tap()
        XCTAssertTrue(app.descendants(matching: .any)["more-article-faq"].waitForExistence(timeout: 10))
        XCTAssertTrue(app.staticTexts["How does Quiz Mode work?"].exists)
        app.navigationBars.buttons.firstMatch.tap()

        let privacy = app.buttons.matching(NSPredicate(format: "label CONTAINS[c] 'Privacy'")).firstMatch
        XCTAssertTrue(privacy.waitForExistence(timeout: 10))
        privacy.tap()
        XCTAssertTrue(app.descendants(matching: .any)["more-article-privacy"].waitForExistence(timeout: 10))
        XCTAssertTrue(app.staticTexts["What the app stores locally"].exists)
        app.navigationBars.buttons.firstMatch.tap()

        let terms = app.buttons.matching(NSPredicate(format: "label CONTAINS[c] 'Terms'")).firstMatch
        XCTAssertTrue(terms.waitForExistence(timeout: 10))
        terms.tap()
        XCTAssertTrue(app.descendants(matching: .any)["more-article-terms"].waitForExistence(timeout: 10))
        XCTAssertTrue(app.staticTexts["Use of the app"].exists)
        app.navigationBars.buttons.firstMatch.tap()

        let changelog = app.buttons.matching(NSPredicate(format: "label CONTAINS[c] 'Changelog'")).firstMatch
        XCTAssertTrue(changelog.waitForExistence(timeout: 10))
        changelog.tap()
        XCTAssertTrue(app.descendants(matching: .any)["more-article-changelog"].waitForExistence(timeout: 10))
        XCTAssertTrue(app.staticTexts["More Utility Release"].exists)
        app.navigationBars.buttons.firstMatch.tap()

        let featureRequest = app.buttons.matching(NSPredicate(format: "label CONTAINS[c] 'Request a Feature'")).firstMatch
        XCTAssertTrue(featureRequest.waitForExistence(timeout: 10))
        featureRequest.tap()

        let summaryGuidance = app.descendants(matching: .any)["community-summary-character-guidance"]
        let detailsGuidance = app.descendants(matching: .any)["community-details-character-guidance"]
        XCTAssertTrue(summaryGuidance.waitForExistence(timeout: 10))
        XCTAssertTrue(detailsGuidance.exists)
        XCTAssertTrue((summaryGuidance.value as? String)?.contains("4 characters to go") == true)

        let summaryField = app.textFields.firstMatch
        XCTAssertTrue(summaryField.exists)
        summaryField.tap()
        summaryField.typeText("abcd")
        XCTAssertTrue((summaryGuidance.value as? String)?.contains("Minimum met") == true)
    }

    @MainActor
    func testPasswordCreationShowsLiveMinimumGuidance() throws {
        let app = XCUIApplication()
        app.launchArguments = ["--ui-testing", "--ui-testing-signed-out"]
        app.launch()

        XCTAssertTrue(app.buttons["Sign up with Email"].waitForExistence(timeout: 10))
        app.buttons["Sign up with Email"].tap()

        let passwordField = app.secureTextFields["account-field-password"]
        XCTAssertTrue(passwordField.waitForExistence(timeout: 10))
        passwordField.tap()
        passwordField.typeText(String(repeating: "a", count: 9))

        let guidance = app.descendants(matching: .any)["password-create-character-guidance"]
        XCTAssertTrue(guidance.waitForExistence(timeout: 10))
        XCTAssertTrue((guidance.value as? String)?.contains("characters to go") == true)

        passwordField.typeText("a")
        XCTAssertTrue((guidance.value as? String)?.contains("Minimum met") == true)
    }

    @MainActor
    func testPasswordResetShowsLiveMinimumGuidance() throws {
        let app = XCUIApplication()
        app.launchArguments = ["--ui-testing", "--ui-testing-signed-out", "--ui-testing-reset-confirm"]
        app.launch()

        let passwordField = app.secureTextFields["account-field-new-password"]
        XCTAssertTrue(passwordField.waitForExistence(timeout: 10))
        passwordField.tap()
        passwordField.typeText(String(repeating: "a", count: 9))

        let guidance = app.descendants(matching: .any)["password-reset-character-guidance"]
        XCTAssertTrue(guidance.waitForExistence(timeout: 10))
        XCTAssertTrue((guidance.value as? String)?.contains("characters to go") == true)

        passwordField.typeText("a")
        XCTAssertTrue((guidance.value as? String)?.contains("Minimum met") == true)
    }
}
