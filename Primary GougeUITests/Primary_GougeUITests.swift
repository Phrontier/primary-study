import XCTest

final class Primary_GougeUITests: XCTestCase {
    override func setUpWithError() throws {
        continueAfterFailure = false
    }

    @MainActor
    private func tabButton(_ app: XCUIApplication, _ title: String) -> XCUIElement {
        let compactTab = app.tabBars.buttons[title]
        return compactTab.exists ? compactTab : app.buttons[title].firstMatch
    }

    @MainActor
    private func backButton(_ app: XCUIApplication) -> XCUIElement {
        let compact = app.buttons["pilot-back"]
        return compact.exists ? compact : app.navigationBars.buttons.firstMatch
    }

    @MainActor
    func testHomeA1Fidelity() throws {
        try verifyHomeA1()
    }

    @MainActor
    func testHomeA1LargerText() throws {
        try verifyHomeA1(extraArguments: ["-UIPreferredContentSizeCategoryName", "UICTContentSizeCategoryAccessibilityXXXL"])
    }

    @MainActor
    private func verifyHomeA1(extraArguments: [String] = []) throws {
        let app = XCUIApplication()
        app.launchArguments = ["--ui-testing", "--ui-testing-signed-in", "--home-a1-fixture"] + extraArguments
        app.launch()
        XCTAssertTrue(app.staticTexts["home-greeting"].waitForExistence(timeout: 15))
        XCTAssertTrue(app.staticTexts["home-eyebrow"].exists)
        XCTAssertEqual(app.navigationBars.count, 0)
        XCTAssertEqual(app.staticTexts["home-greeting"].label, "Good evening.")
        func capture(_ name: String) {
            let back = app.buttons["pilot-back"]
            if back.exists {
                let settled = XCTNSPredicateExpectation(predicate: NSPredicate { _, _ in
                    back.exists && back.frame.minX < 30
                }, object: nil)
                XCTAssertEqual(XCTWaiter.wait(for: [settled], timeout: 5), .completed)
            }
            let attachment = XCTAttachment(screenshot: app.screenshot())
            attachment.name = name
            attachment.lifetime = .keepAlways
            add(attachment)
        }
        capture("home-a1-top")
        app.swipeUp()
        app.swipeUp()
        let reference = app.buttons.matching(NSPredicate(format: "label CONTAINS 'EPs / Limits / N/W/C'")).firstMatch
        let tabTop = app.tabBars.firstMatch.frame.minY
        for _ in 0..<14 where !reference.exists || !reference.isHittable || reference.frame.maxY > tabTop - 8 { app.swipeUp() }
        XCTAssertLessThanOrEqual(reference.frame.maxY, tabTop - 8)
        capture("home-a1-bottom")
        XCTAssertTrue(reference.waitForExistence(timeout: 5))
        XCTAssertTrue(reference.isHittable)
        reference.tap()
        XCTAssertTrue(app.staticTexts["EPs, Limits, N/W/C Flashcards"].waitForExistence(timeout: 5))
        backButton(app).tap()
        // The existing reference shortcut routes through the Events tab's stack.
        tabButton(app, "Home").tap()
        for _ in 0..<16 where !app.staticTexts["home-eyebrow"].exists || !app.staticTexts["home-eyebrow"].isHittable { app.swipeDown() }
        XCTAssertTrue(app.staticTexts["home-eyebrow"].waitForExistence(timeout: 5))
        XCTAssertEqual(app.navigationBars.count, 0)
    }

    @MainActor
    func testConnectedDesignPilot() throws {
        try verifyConnectedDesignPilot()
    }

    @MainActor
    func testConnectedDesignPilotWithLargerText() throws {
        try verifyConnectedDesignPilot(extraArguments: ["-UIPreferredContentSizeCategoryName", "UICTContentSizeCategoryAccessibilityXXXL"])
    }

    @MainActor
    private func verifyConnectedDesignPilot(extraArguments: [String] = []) throws {
        let app = XCUIApplication()
        app.launchArguments = ["--ui-testing", "--ui-testing-signed-in"] + extraArguments
        app.launch()
        XCTAssertTrue(tabButton(app, "Home").waitForExistence(timeout: 15))
        func capture(_ name: String) {
            let back = app.buttons["pilot-back"]
            if back.exists {
                let settled = XCTNSPredicateExpectation(predicate: NSPredicate { _, _ in
                    back.exists && back.frame.minX < 30
                }, object: nil)
                XCTAssertEqual(XCTWaiter.wait(for: [settled], timeout: 5), .completed)
            }
            let attachment = XCTAttachment(screenshot: app.screenshot())
            attachment.name = name
            attachment.lifetime = .keepAlways
            add(attachment)
        }
        func tapContaining(_ title: String) {
            let button = app.buttons.matching(NSPredicate(format: "label CONTAINS[c] %@", title)).firstMatch
            XCTAssertTrue(button.waitForExistence(timeout: 10), title)
            for _ in 0..<4 where !button.isHittable { app.swipeUp() }
            button.tap()
        }
        capture("pilot-home")
        tabButton(app, "Events").tap()
        capture("pilot-events")
        tapContaining("Contacts")
        tapContaining("Sims")
        capture("pilot-event-list")
        tapContaining("FAM2101")
        XCTAssertTrue(app.staticTexts["Cockpit Familiarization"].waitForExistence(timeout: 10))
        capture("pilot-event-detail")
        app.coordinate(withNormalizedOffset: CGVector(dx: 0.01, dy: 0.5)).press(forDuration: 0.05,
            thenDragTo: app.coordinate(withNormalizedOffset: CGVector(dx: 0.85, dy: 0.5)))
        XCTAssertTrue(app.staticTexts["pilot-title-Sims"].waitForExistence(timeout: 5))
        tapContaining("FAM2101")
        tapContaining("Discussion Items")
        let expanded = app.buttons.matching(NSPredicate(format: "value == 'Expanded'")).firstMatch
        XCTAssertTrue(expanded.waitForExistence(timeout: 10))
        capture("pilot-discussion-expanded")
        expanded.tap()
        XCTAssertTrue(app.buttons.matching(NSPredicate(format: "value == 'Collapsed'")).firstMatch.exists)
        capture("pilot-discussion-collapsed")
        backButton(app).tap()
        tapContaining("Flashcards")
        capture("pilot-deck")
        tapContaining("Study Full Deck")
        XCTAssertTrue(app.staticTexts["Card 1 of 7"].waitForExistence(timeout: 10))
        capture("pilot-question")
        tapContaining("Question:")
        for _ in 0..<16 where !app.buttons["Good"].exists || !app.buttons["Good"].isHittable { app.swipeUp() }
        XCTAssertTrue(app.buttons["Good"].waitForExistence(timeout: 5))
        capture("pilot-answer")
        let tabTop = app.tabBars.firstMatch.frame.minY
        for _ in 0..<16 where app.buttons["Good"].frame.maxY > tabTop - 8 { app.swipeUp() }
        for label in ["Missed", "Hard", "Good", "Easy"] {
            XCTAssertTrue(app.buttons[label].isHittable)
            XCTAssertLessThanOrEqual(app.buttons[label].frame.maxY, tabTop - 8)
        }
        capture("pilot-answer-controls")
        app.buttons["Good"].tap()
        XCTAssertTrue(app.staticTexts["Card 2 of 7"].waitForExistence(timeout: 5))
        XCTAssertFalse(app.buttons["Good"].exists)
        backButton(app).tap()
        tabButton(app, "Home").tap()
        XCTAssertTrue(app.staticTexts["flashcards reviewed today"].waitForExistence(timeout: 5))
        capture("pilot-home-with-history")
    }

    @MainActor
    func testRemainingSelectedScreens() throws { try verifyRemainingScreens() }

    @MainActor
    func testRemainingSelectedScreensLargerText() throws {
        try verifyRemainingScreens(extra: ["-UIPreferredContentSizeCategoryName", "UICTContentSizeCategoryAccessibilityXXXL"])
    }

    @MainActor
    private func verifyRemainingScreens(extra: [String] = []) throws {
        let app = XCUIApplication()
        app.launchArguments = ["--ui-testing", "--ui-testing-signed-in"] + extra
        app.launch()
        func capture(_ name: String) {
            let attachment = XCTAttachment(screenshot: app.screenshot()); attachment.name = name; attachment.lifetime = .keepAlways; add(attachment)
        }
        XCTAssertTrue(tabButton(app, "Instructors").waitForExistence(timeout: 15))
        tabButton(app, "Instructors").tap()
        XCTAssertTrue(app.buttons["Submit Instructor Review"].waitForExistence(timeout: 10))
        capture("remaining-instructors")
        let row = app.buttons.matching(NSPredicate(format: "identifier BEGINSWITH 'selected-instructor-'")).firstMatch
        XCTAssertTrue(row.waitForExistence(timeout: 10))
        for _ in 0..<8 where !row.isHittable { app.swipeUp() }
        row.tap()
        XCTAssertTrue(app.staticTexts["At a glance"].waitForExistence(timeout: 10))
        capture("remaining-instructor-detail")
        let report = app.buttons["Report review"].firstMatch
        for _ in 0..<16 where !report.exists || !report.isHittable { app.swipeUp() }
        XCTAssertTrue(report.exists)
        capture("remaining-instructor-reviews")
        backButton(app).tap()
        tabButton(app, "More").tap()
        let premium = app.buttons.matching(NSPredicate(format: "label CONTAINS[c] 'Premium' AND label CONTAINS[c] 'active'")).firstMatch
        XCTAssertTrue(premium.waitForExistence(timeout: 10))
        capture("remaining-more")
        premium.tap()
        XCTAssertTrue(app.staticTexts["Premium Is Active"].waitForExistence(timeout: 10))
        capture("remaining-premium-active")
        app.buttons["Close Premium offer"].tap()
        capture("remaining-more-return")
        let settings = app.buttons.matching(NSPredicate(format: "label CONTAINS[c] 'Settings'")).firstMatch
        XCTAssertTrue(settings.waitForExistence(timeout: 10))
        for _ in 0..<8 where !settings.isHittable { app.swipeUp() }
        settings.tap()
        XCTAssertTrue(app.staticTexts["Current focus topics"].waitForExistence(timeout: 10))
        capture("remaining-settings")
    }

    @MainActor
    func testSelectedOnboardingAndPremium() throws { try verifyOnboardingAndPremium() }

    @MainActor
    func testSelectedOnboardingAndPremiumLargerText() throws {
        try verifyOnboardingAndPremium(extra: ["-UIPreferredContentSizeCategoryName", "UICTContentSizeCategoryAccessibilityXXXL"])
    }

    @MainActor
    private func verifyOnboardingAndPremium(extra: [String] = []) throws {
        let app = XCUIApplication()
        func capture(_ name: String) {
            let attachment = XCTAttachment(screenshot: app.screenshot()); attachment.name = name; attachment.lifetime = .keepAlways; add(attachment)
        }
        app.launchArguments = ["--ui-testing", "--ui-testing-signed-out"] + extra
        app.launch()
        let signup = app.buttons["Sign Up with Email"]
        XCTAssertTrue(signup.waitForExistence(timeout: 10))
        capture("remaining-welcome")
        for _ in 0..<12 where !signup.isHittable { app.swipeUp() }
        signup.tap()
        XCTAssertTrue(app.textFields["account-field-email"].waitForExistence(timeout: 10))
        capture("remaining-create-account")
        app.terminate()
        app.launchArguments = ["--ui-testing", "--ui-testing-signed-in", "--ui-testing-training-setup"] + extra
        app.launch()
        XCTAssertTrue(app.staticTexts["Not sure yet? Start with Echo."].waitForExistence(timeout: 10))
        capture("remaining-training-setup")
        let setupContinue = app.buttons["Continue"]
        for _ in 0..<16 where !setupContinue.isHittable { app.swipeUp() }
        XCTAssertTrue(setupContinue.isHittable)
        capture("remaining-training-setup-bottom")
        app.terminate()
        app.launchArguments = ["--ui-testing", "--ui-testing-free-account", "--premium-fidelity-fixture"] + extra
        app.launch()
        XCTAssertTrue(tabButton(app, "More").waitForExistence(timeout: 15))
        tabButton(app, "More").tap()
        let premium = app.buttons.matching(NSPredicate(format: "label CONTAINS[c] 'Premium' AND label CONTAINS[c] 'options'")).firstMatch
        XCTAssertTrue(premium.waitForExistence(timeout: 10))
        capture("remaining-more-free")
        for _ in 0..<12 where !premium.isHittable { app.swipeUp() }
        premium.tap()
        XCTAssertTrue(app.staticTexts["Day 5"].waitForExistence(timeout: 10))
        capture("remaining-premium-trial")
        let restore = app.buttons["Restore purchases"]
        for _ in 0..<20 where !restore.exists || !restore.isHittable { app.swipeUp() }
        XCTAssertTrue(restore.isHittable)
        capture("remaining-premium-offer")
        // The display-only fixture never calls StoreKit, even when its CTA is tapped.
        app.buttons["Continue"].tap()
        let skip = app.buttons["Continue without reminders"]
        XCTAssertTrue(skip.waitForExistence(timeout: 10))
        capture("remaining-premium-reminder")
        for _ in 0..<16 where !skip.isHittable { app.swipeUp() }
        skip.tap()
        XCTAssertTrue(app.staticTexts["Day 5"].waitForExistence(timeout: 5))
    }

    @MainActor
    func testDesignRolloutFlows() throws { try verifyDesignRolloutFlows() }

    @MainActor
    func testDesignRolloutFlowsLargerText() throws {
        try verifyDesignRolloutFlows(extra: ["-UIPreferredContentSizeCategoryName", "UICTContentSizeCategoryAccessibilityXXXL"])
    }

    @MainActor
    private func verifyDesignRolloutFlows(extra: [String] = []) throws {
        let app = XCUIApplication()
        app.launchArguments = ["--ui-testing", "--ui-testing-signed-in"] + extra
        app.launch()
        func capture(_ name: String) {
            let image = XCTAttachment(screenshot: app.screenshot())
            image.name = "rollout-" + name; image.lifetime = .keepAlways; add(image)
        }
        func tap(_ title: String) {
            let item = app.buttons.matching(NSPredicate(format: "label CONTAINS[c] %@", title)).firstMatch
            for _ in 0..<14 {
                if item.exists && item.isHittable { break }
                app.swipeUp()
            }
            XCTAssertTrue(item.waitForExistence(timeout: 5), title)
            XCTAssertTrue(item.isHittable, title)
            item.tap()
        }
        XCTAssertTrue(tabButton(app, "Events").waitForExistence(timeout: 15))
        tabButton(app, "Events").tap(); tap("General Library")
        XCTAssertTrue(app.staticTexts["Focused Memory Work"].waitForExistence(timeout: 10))
        capture("library"); backButton(app).tap()
        tabButton(app, "Search").tap()
        let field = app.textFields.firstMatch
        XCTAssertTrue(field.waitForExistence(timeout: 10))
        field.tap(); field.typeText("FAM2101\n")
        capture("search")
        tabButton(app, "More").tap()
        for title in ["Profile", "Notifications", "FAQ", "Request a Feature", "My Instructor Reviews", "Flashcard Performance Stats", "Recent Briefs", "Recent Flashcard Sets", "Version"] {
            // Return to the top of More between destinations, preserving native navigation.
            for _ in 0..<5 { app.swipeDown() }
            tap(title)
            capture(title.lowercased().replacingOccurrences(of: " ", with: "-"))
            backButton(app).tap()
        }
        for _ in 0..<5 { app.swipeDown() }
        tap("Quiz Mode")
        XCTAssertTrue(app.staticTexts["Choose Your Question Set"].waitForExistence(timeout: 10))
        capture("quiz-setup")
        tap("Start Quiz")
        XCTAssertTrue(app.staticTexts["Select the best answer"].waitForExistence(timeout: 10) || app.staticTexts["True or False"].exists)
        capture("quiz-question")
    }

    @MainActor
    func testDesignQuizSetup() throws { try verifyDesignQuizSetup() }

    @MainActor
    func testDesignQuizSetupLargerText() throws {
        try verifyDesignQuizSetup(extra: ["-UIPreferredContentSizeCategoryName", "UICTContentSizeCategoryAccessibilityXXXL"])
    }

    @MainActor
    private func verifyDesignQuizSetup(extra: [String] = []) throws {
        let app = XCUIApplication()
        app.launchArguments = ["--ui-testing", "--ui-testing-signed-in"] + extra
        app.launch()
        XCTAssertTrue(tabButton(app, "More").waitForExistence(timeout: 15)); tabButton(app, "More").tap()
        let quiz = app.buttons.matching(NSPredicate(format: "label CONTAINS[c] 'Quiz Mode'")).firstMatch
        for _ in 0..<12 where !quiz.exists || !quiz.isHittable { app.swipeUp() }
        XCTAssertTrue(quiz.isHittable); quiz.tap()
        XCTAssertTrue(app.staticTexts["Choose Your Question Set"].waitForExistence(timeout: 10))
        let setup = XCTAttachment(screenshot: app.screenshot()); setup.name = "rollout-quiz-setup"; setup.lifetime = .keepAlways; add(setup)
        let start = app.buttons.matching(NSPredicate(format: "label CONTAINS[c] 'Start Quiz'")).firstMatch
        for _ in 0..<18 where !start.exists || !start.isHittable { app.swipeUp() }
        XCTAssertTrue(start.isHittable); start.tap()
        XCTAssertTrue(app.staticTexts["Select the best answer"].waitForExistence(timeout: 10) || app.staticTexts["True or False"].exists)
        let question = XCTAttachment(screenshot: app.screenshot()); question.name = "rollout-quiz-question"; question.lifetime = .keepAlways; add(question)
        XCTAssertTrue(app.buttons["Back to quiz setup"].exists)
    }

    @MainActor
    func testDesignResourceAndPracticeFlows() throws {
        let app = XCUIApplication()
        app.launchArguments = ["--ui-testing", "--ui-testing-signed-in"]
        app.launch()
        func capture(_ name: String) {
            let shot = XCTAttachment(screenshot: app.screenshot()); shot.name = "rollout-" + name; shot.lifetime = .keepAlways; add(shot)
        }
        func tap(_ title: String) {
            let item = app.buttons.matching(NSPredicate(format: "label CONTAINS[c] %@", title)).firstMatch
            for _ in 0..<16 where !item.exists || !item.isHittable { app.swipeUp() }
            XCTAssertTrue(item.isHittable, title); item.tap()
        }
        XCTAssertTrue(tabButton(app, "Events").waitForExistence(timeout: 15))
        tabButton(app, "Events").tap(); tap("Contacts"); tap("Ground School")
        XCTAssertTrue(app.staticTexts["Core Materials"].waitForExistence(timeout: 10))
        capture("ground-school")
        tap("Contact 1")
        XCTAssertTrue(app.staticTexts["Choose Your Run"].waitForExistence(timeout: 10))
        capture("practice-setup"); tap("Full Test")
        XCTAssertTrue(app.staticTexts["Select the best answer"].waitForExistence(timeout: 10))
        capture("practice-question"); tap("Forgetful")
        XCTAssertTrue(app.staticTexts["Incorrect"].waitForExistence(timeout: 10))
        capture("practice-answer"); backButton(app).tap()
        for _ in 0..<10 { app.swipeDown() }
        tap("EP NWCs")
        XCTAssertTrue(app.navigationBars["EP NWCs"].waitForExistence(timeout: 10))
        XCTAssertFalse(app.staticTexts["Document Unavailable"].exists)
        // Quick Look renders asynchronously after the navigation title appears.
        XCTAssertTrue(app.buttons["Page Label"].waitForExistence(timeout: 15))
        capture("source-document")
        backButton(app).tap(); backButton(app).tap(); backButton(app).tap()
        tap("General Library"); tap("Hand Signals")
        XCTAssertTrue(app.staticTexts["Available to Download"].waitForExistence(timeout: 10))
        capture("video-download")
    }

    @MainActor
    func testDesignReviewForms() throws {
        let app = XCUIApplication()
        app.launchArguments = ["--ui-testing", "--ui-testing-signed-in"]
        app.launch()
        func capture(_ name: String) {
            let shot = XCTAttachment(screenshot: app.screenshot()); shot.name = "rollout-" + name; shot.lifetime = .keepAlways; add(shot)
        }
        XCTAssertTrue(tabButton(app, "Instructors").waitForExistence(timeout: 15))
        tabButton(app, "Instructors").tap()
        app.buttons["Submit Instructor Review"].tap()
        XCTAssertTrue(app.textFields["Start typing an instructor"].waitForExistence(timeout: 10))
        capture("review-form")
        let squadron = app.buttons.matching(NSPredicate(format: "label BEGINSWITH[c] 'SQUADRON'")).firstMatch
        XCTAssertTrue(squadron.isEnabled); squadron.tap()
        XCTAssertTrue(app.navigationBars["Select Squadron"].waitForExistence(timeout: 5))
        let vt = app.buttons.matching(NSPredicate(format: "label CONTAINS[c] 'VT-27'")).firstMatch
        XCTAssertTrue(vt.waitForExistence(timeout: 5)); vt.tap()
        let event = app.textFields["Type an event"]
        XCTAssertTrue(event.waitForExistence(timeout: 5)); event.tap(); event.typeText("FAM2101")
        let scroll = app.scrollViews["design-content-scroll"]
        XCTAssertTrue(scroll.exists)
        // Start above the keyboard: a full-view swipe starts inside the keyboard on iOS 27.
        app.coordinate(withNormalizedOffset: CGVector(dx: 0.5, dy: 0.45))
            .press(forDuration: 0.05, thenDragTo: app.coordinate(withNormalizedOffset: CGVector(dx: 0.5, dy: 0.2)))
        scroll.swipeUp()
        let chill = app.buttons.matching(NSPredicate(format: "label CONTAINS[c] 'CHILL FACTOR'")).firstMatch
        for _ in 0..<12 {
            if chill.exists && chill.isHittable { break }
            if chill.exists && chill.frame.minY < 140 { scroll.swipeDown() } else { scroll.swipeUp() }
        }
        XCTAssertTrue(chill.isEnabled); XCTAssertTrue(chill.isHittable); chill.tap()
        XCTAssertTrue(app.navigationBars["Select Chill Factor"].waitForExistence(timeout: 5))
        capture("review-score-selector")
        app.navigationBars["Select Chill Factor"].buttons["Close"].tap()
    }

    @MainActor
    func testDesignPatternGallery() throws {
        let app = XCUIApplication()
        app.launchArguments = ["--ui-testing", "--ui-testing-signed-in", "--design-pattern-gallery"]
        app.launch()
        XCTAssertTrue(app.staticTexts["Open destinations"].waitForExistence(timeout: 15))
        let top = XCTAttachment(screenshot: app.screenshot()); top.name = "rollout-pattern-top"; top.lifetime = .keepAlways; add(top)
        app.swipeUp(); app.swipeUp()
        XCTAssertTrue(app.staticTexts["No reviews yet"].exists)
        let bottom = XCTAttachment(screenshot: app.screenshot()); bottom.name = "rollout-pattern-states"; bottom.lifetime = .keepAlways; add(bottom)
    }

    @MainActor
    func testSignedOutLaunchRequiresAccount() throws {
        let app = XCUIApplication()
        app.launchArguments = ["--ui-testing", "--ui-testing-signed-out"]
        app.launch()

        XCTAssertTrue(app.descendants(matching: .any)["account-sign-in-screen"].waitForExistence(timeout: 10))
        XCTAssertTrue(app.staticTexts["Prepare for\nwhat’s next."].exists)
        XCTAssertFalse(app.tabBars.firstMatch.exists)
        XCTAssertTrue(app.buttons["Sign Up with Email"].exists)
        XCTAssertTrue(app.buttons.matching(NSPredicate(format: "label CONTAINS[c] 'Apple'")).firstMatch.exists)
    }

    @MainActor
    func testAppReviewAccountCanReachPremiumAndCoreContent() throws {
        let app = XCUIApplication()
        app.launchArguments = ["--ui-testing", "--ui-testing-signed-in"]
        app.launch()

        XCTAssertTrue(tabButton(app, "Events").waitForExistence(timeout: 15))
        tabButton(app, "Events").tap()
        XCTAssertTrue(app.staticTexts["Choose your phase"].waitForExistence(timeout: 10))

        tabButton(app, "More").tap()
        let premiumCard = app.buttons.matching(NSPredicate(format: "label CONTAINS[c] 'Premium' AND label CONTAINS[c] 'active'")).firstMatch
        XCTAssertTrue(premiumCard.waitForExistence(timeout: 10))
        premiumCard.tap()

        XCTAssertTrue(app.descendants(matching: .any)["premium-status"].waitForExistence(timeout: 10))
        XCTAssertTrue(app.staticTexts["Premium Is Active"].exists)
    }

    @MainActor
    func testFreeAccountCanUseFreeTierAndSeesPremiumLocks() throws {
        let app = XCUIApplication()
        app.launchArguments = ["--ui-testing", "--ui-testing-free-account"]
        app.launch()

        XCTAssertTrue(tabButton(app, "Home").waitForExistence(timeout: 15))
        XCTAssertTrue(app.staticTexts["EPs / Limits / N/W/C"].exists)
        XCTAssertTrue(app.staticTexts["Question of the day"].waitForExistence(timeout: 10))

        let emergencyReference = app.buttons.matching(NSPredicate(format: "label CONTAINS[c] 'EPs / Limits / N/W/C'")).firstMatch
        XCTAssertTrue(emergencyReference.exists)
        emergencyReference.tap()
        XCTAssertTrue(app.staticTexts["EPs, Limits, N/W/C Flashcards"].waitForExistence(timeout: 10))
        XCTAssertFalse(app.descendants(matching: .any)["premium-content-gate"].exists)

        tabButton(app, "Events").tap()
        XCTAssertTrue(app.staticTexts["Choose your phase"].waitForExistence(timeout: 10))
        app.buttons["Contacts"].tap()
        app.buttons["Sims"].tap()

        let fam2101 = app.buttons.matching(NSPredicate(format: "label CONTAINS[c] 'FAM2101'")).firstMatch
        XCTAssertTrue(fam2101.waitForExistence(timeout: 10))
        fam2101.tap()
        XCTAssertTrue(app.staticTexts["Cockpit Familiarization"].waitForExistence(timeout: 10))
        XCTAssertFalse(app.descendants(matching: .any)["premium-content-gate"].exists)

        backButton(app).tap()
        let fam2102 = app.buttons.matching(NSPredicate(format: "label CONTAINS[c] 'FAM2102'")).firstMatch
        XCTAssertTrue(fam2102.waitForExistence(timeout: 10))
        fam2102.tap()
        XCTAssertTrue(app.staticTexts["Ground Emergencies"].waitForExistence(timeout: 10))
        XCTAssertFalse(app.descendants(matching: .any)["premium-content-gate"].exists)

        backButton(app).tap()
        backButton(app).tap()
        app.buttons["Ground School"].tap()
        XCTAssertTrue(app.staticTexts["Familiarization Flight Orientation"].waitForExistence(timeout: 10))
        XCTAssertFalse(app.descendants(matching: .any)["premium-content-gate"].exists)

        backButton(app).tap()
        app.buttons["Sims"].tap()
        let fam2103 = app.buttons.matching(NSPredicate(format: "label CONTAINS[c] 'FAM2103' AND label CONTAINS[c] 'Premium locked'")).firstMatch
        XCTAssertTrue(fam2103.waitForExistence(timeout: 10))
        fam2103.tap()
        XCTAssertTrue(app.descendants(matching: .any)["premium-content-gate"].waitForExistence(timeout: 10))
        XCTAssertTrue(app.staticTexts.matching(NSPredicate(format: "label CONTAINS[c] 'Unlock FAM2103'")).firstMatch.exists)

        app.buttons["Close Premium offer"].tap()
        tabButton(app, "Instructors").tap()
        XCTAssertFalse(app.descendants(matching: .any)["premium-content-gate"].exists)
    }

    @MainActor
    func testFreeAccountSearchAndMoreCannotBypassPremium() throws {
        let app = XCUIApplication()
        app.launchArguments = ["--ui-testing", "--ui-testing-free-account"]
        app.launch()

        XCTAssertTrue(tabButton(app, "Search").waitForExistence(timeout: 15))
        tabButton(app, "Search").tap()
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

        app.buttons["Close Premium offer"].tap()
        tabButton(app, "More").tap()
        XCTAssertFalse(app.buttons.matching(NSPredicate(format: "label CONTAINS[c] 'Moderation'")).firstMatch.exists)
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

        XCTAssertTrue(tabButton(app, "More").waitForExistence(timeout: 15))
        tabButton(app, "More").tap()

        let faq = app.buttons.matching(NSPredicate(format: "label CONTAINS[c] 'FAQ'")).firstMatch
        XCTAssertTrue(faq.waitForExistence(timeout: 10))
        faq.tap()
        XCTAssertTrue(app.descendants(matching: .any)["more-article-faq"].waitForExistence(timeout: 10))
        XCTAssertTrue(app.staticTexts["How Does Quiz Mode Work?"].exists)
        backButton(app).tap()

        let privacy = app.buttons.matching(NSPredicate(format: "label CONTAINS[c] 'Privacy'")).firstMatch
        XCTAssertTrue(privacy.waitForExistence(timeout: 10))
        privacy.tap()
        XCTAssertTrue(app.descendants(matching: .any)["more-article-privacy"].waitForExistence(timeout: 10))
        XCTAssertTrue(app.staticTexts["What the App Stores Locally"].exists)
        backButton(app).tap()

        let terms = app.buttons.matching(NSPredicate(format: "label CONTAINS[c] 'Terms'")).firstMatch
        XCTAssertTrue(terms.waitForExistence(timeout: 10))
        terms.tap()
        XCTAssertTrue(app.descendants(matching: .any)["more-article-terms"].waitForExistence(timeout: 10))
        XCTAssertTrue(app.staticTexts["Use of the App"].exists)
        backButton(app).tap()

        let changelog = app.buttons.matching(NSPredicate(format: "label CONTAINS[c] 'Changelog'")).firstMatch
        XCTAssertTrue(changelog.waitForExistence(timeout: 10))
        changelog.tap()
        XCTAssertTrue(app.descendants(matching: .any)["more-article-changelog"].waitForExistence(timeout: 10))
        XCTAssertTrue(app.staticTexts["More Utility Release"].exists)
        backButton(app).tap()

        let featureRequest = app.buttons.matching(NSPredicate(format: "label CONTAINS[c] 'Request a Feature'")).firstMatch
        XCTAssertTrue(featureRequest.waitForExistence(timeout: 10))
        featureRequest.tap()

        let summaryGuidance = app.descendants(matching: .any)["community-summary-character-guidance"]
        let detailsGuidance = app.descendants(matching: .any)["community-details-character-guidance"]
        XCTAssertTrue(summaryGuidance.waitForExistence(timeout: 10))
        XCTAssertTrue(detailsGuidance.exists)
        let summaryField = app.textFields.firstMatch
        XCTAssertTrue(summaryField.exists)
        summaryField.tap()
        // Drafts intentionally survive launches. Clear this fixture through the UI.
        if let saved = summaryField.value as? String, saved != "Short summary" {
            summaryField.typeText(String(repeating: XCUIKeyboardKey.delete.rawValue, count: saved.count))
        }
        XCTAssertTrue((summaryGuidance.value as? String)?.contains("4 characters to go") == true)
        summaryField.typeText("abcd")
        XCTAssertTrue((summaryGuidance.value as? String)?.contains("Minimum met") == true)
    }

    @MainActor
    func testModeratorCanReachModerationFromMore() throws {
        let app = XCUIApplication()
        app.launchArguments = ["--ui-testing", "--ui-testing-moderator"]
        app.launch()

        XCTAssertTrue(tabButton(app, "More").waitForExistence(timeout: 15))
        tabButton(app, "More").tap()

        let moderation = app.buttons.matching(
            NSPredicate(format: "label CONTAINS[c] 'Moderation'")
        ).firstMatch
        XCTAssertTrue(moderation.waitForExistence(timeout: 10))
        moderation.tap()

        XCTAssertTrue(app.staticTexts["Review Queue"].waitForExistence(timeout: 10))
        XCTAssertTrue(app.staticTexts["Role Active"].exists)
    }

    @MainActor
    func testPasswordCreationShowsLiveMinimumGuidance() throws {
        let app = XCUIApplication()
        app.launchArguments = ["--ui-testing", "--ui-testing-signed-out"]
        app.launch()

        XCTAssertTrue(app.buttons["Sign Up with Email"].waitForExistence(timeout: 10))
        app.buttons["Sign Up with Email"].tap()

        let passwordField = app.secureTextFields["account-field-password"]
        XCTAssertTrue(passwordField.waitForExistence(timeout: 10))
        passwordField.tap()
        passwordField.typeText(String(repeating: "a", count: 9))

        let guidance = app.descendants(matching: .any)["password-create-character-guidance"]
        XCTAssertTrue(guidance.waitForExistence(timeout: 10))
        XCTAssertTrue((guidance.value as? String)?.contains("characters to go") == true)

        passwordField.typeText("a")
        XCTAssertTrue(guidance.waitForExistence(timeout: 3))
        XCTAssertTrue(NSPredicate(format: "value CONTAINS %@", "Minimum met").evaluate(with: guidance))
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
        XCTAssertTrue(guidance.waitForExistence(timeout: 3))
        XCTAssertTrue(NSPredicate(format: "value CONTAINS %@", "Minimum met").evaluate(with: guidance))
    }
}
