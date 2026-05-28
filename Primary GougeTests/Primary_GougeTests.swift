//
//  Primary_GougeTests.swift
//  Primary GougeTests
//
//  Created by Conway Bolt on 3/27/26.
//

import Foundation
import Testing
@testable import Primary_Gouge

struct Primary_GougeTests {

    @MainActor
    @Test func instructorReviewCountStringsHandleSingularAndPlural() async throws {
        let single = Instructor(
            id: "single",
            name: "Single Review",
            squadron: Squadron(id: "vt-27", displayName: "VT-27"),
            capabilities: [.flight],
            publishedReviewCount: 1,
            averageChillScore: 5.0,
            averageGradingScore: 4.0
        )
        let plural = Instructor(
            id: "plural",
            name: "Plural Review",
            squadron: Squadron(id: "vt-27", displayName: "VT-27"),
            capabilities: [.flight],
            publishedReviewCount: 2,
            averageChillScore: 5.0,
            averageGradingScore: 4.0
        )

        #expect(single.reviewCountText == "1 review")
        #expect(single.publishedReviewCountText == "1 published review")
        #expect(plural.reviewCountText == "2 reviews")
        #expect(plural.publishedReviewCountText == "2 published reviews")
    }

    @MainActor
    @Test func instructorRatingScaleFormatsOutOfTenStrings() async throws {
        #expect(InstructorRatingScale.formatOutOfTen(score: 5) == "7.1/10")
        #expect(InstructorRatingScale.formatOutOfTen(average: 5.5) == "7.9/10")
        #expect(InstructorRatingScale.formatOutOfTen(average: 5.5, includeAverageSuffix: true) == "7.9/10 avg")
        #expect(InstructorRatingScale.label(for: 5, category: .gradingStyle) == "Good but Fair")
        #expect(InstructorRatingScale.label(for: 1, category: .chillFactor) == "Hammer")
    }

    @MainActor
    @Test func submissionModeFiltersSquadronsEventsAndSuggestions() async throws {
        let repository = MockInstructorReviewRepository()
        let viewModel = ReviewSubmissionViewModel()

        viewModel.instructorName = "instructor"
        viewModel.load(using: repository)

        #expect(viewModel.visibleSquadrons.map(\.displayName) == ["VT-2", "VT-3", "VT-6", "VT-27", "VT-28", "TW-4", "TW-5"])
        #expect(viewModel.visibleEvents.map(\.displayName) == ["C3101", "FAM2101", "FAM2102"])
        #expect(viewModel.suggestions.map(\.name) == ["Sim Instructor", "Flight Instructor"])

        viewModel.submissionMode = .sims

        #expect(viewModel.visibleSquadrons.map(\.displayName) == ["TW-4", "TW-5"])
        #expect(viewModel.visibleEvents.map(\.displayName) == ["C3101"])
        #expect(viewModel.suggestions.map(\.name) == ["Sim Instructor"])

        viewModel.submissionMode = .flights

        #expect(viewModel.visibleSquadrons.map(\.displayName) == ["VT-2", "VT-3", "VT-6", "VT-27", "VT-28"])
        #expect(viewModel.visibleEvents.map(\.displayName) == ["FAM2101", "FAM2102"])
        #expect(viewModel.suggestions.map(\.name) == ["Flight Instructor"])
    }

    @MainActor
    @Test func submissionModeClearsSelectionsThatNoLongerMatch() async throws {
        let repository = MockInstructorReviewRepository()
        let viewModel = ReviewSubmissionViewModel()

        viewModel.load(using: repository)
        viewModel.selectedSquadron = repository.squadrons[0]
        viewModel.selectedEvent = repository.events[0]

        viewModel.submissionMode = .flights

        #expect(viewModel.selectedSquadron == nil)
        #expect(viewModel.selectedEvent == nil)
    }

    @MainActor
    @Test func applyingSuggestionAutoSyncsSubmissionModeFromSquadron() async throws {
        let repository = MockInstructorReviewRepository()
        let viewModel = ReviewSubmissionViewModel()

        viewModel.load(using: repository)
        viewModel.applySuggestion(repository.suggestions[0])

        #expect(viewModel.instructorName == "Sim Instructor")
        #expect(viewModel.selectedSquadron?.displayName == "TW-4")
        #expect(viewModel.submissionMode == .sims)

        viewModel.applySuggestion(repository.suggestions[1])

        #expect(viewModel.instructorName == "Flight Instructor")
        #expect(viewModel.selectedSquadron?.displayName == "VT-27")
        #expect(viewModel.submissionMode == .flights)
    }

    @MainActor
    @Test func canonicalizesKnownInstructorNamesOnSubmit() async throws {
        let repository = MockInstructorReviewRepository()
        let viewModel = ReviewSubmissionViewModel()

        viewModel.load(using: repository)
        viewModel.instructorName = "Alex Garrecht"
        viewModel.selectedSquadron = repository.squadrons.first(where: { $0.displayName == "TW-4" })
        viewModel.eventName = "C3101"
        viewModel.chillScore = 5
        viewModel.gradingScore = 5
        viewModel.reviewText = String(repeating: "A", count: 60)

        viewModel.submit(using: repository)

        #expect(repository.lastSubmittedReview?.instructorName == "Garrecht, Alex")
        #expect(repository.lastSubmittedReview?.event.displayName == "C3101")
        #expect(repository.lastSubmittedReview?.event.kind == .sim)
    }

    @MainActor
    @Test func unmatchedInstructorNamesStayAsTyped() async throws {
        let repository = MockInstructorReviewRepository()
        let viewModel = ReviewSubmissionViewModel()

        viewModel.load(using: repository)
        viewModel.instructorName = "Mystery Person"
        viewModel.selectedSquadron = repository.squadrons.first(where: { $0.displayName == "VT-27" })
        viewModel.eventName = "FAM2999"
        viewModel.chillScore = 4
        viewModel.gradingScore = 4
        viewModel.reviewText = String(repeating: "B", count: 60)

        viewModel.submit(using: repository)

        #expect(repository.lastSubmittedReview?.instructorName == "Mystery Person")
        #expect(repository.lastSubmittedReview?.event.displayName == "FAM2999")
        #expect(repository.lastSubmittedReview?.event.kind == .flight)
    }

    @MainActor
    @Test func eventSuggestionsPreferConcreteFamMatchesAndAllowCustomEntry() async throws {
        let repository = MockInstructorReviewRepository()
        let viewModel = ReviewSubmissionViewModel()

        viewModel.load(using: repository)
        viewModel.submissionMode = .flights
        viewModel.selectedSquadron = repository.squadrons.first(where: { $0.displayName == "VT-27" })
        viewModel.eventName = "FAM21"

        #expect(viewModel.eventSuggestions.map(\.displayName) == ["FAM2101", "FAM2102"])
        #expect(!viewModel.eventHasExactSuggestionMatch)
        #expect(viewModel.canChooseRatings)

        viewModel.eventName = "FAM2999"
        viewModel.chillScore = 5
        viewModel.gradingScore = 5
        viewModel.reviewText = String(repeating: "C", count: 60)

        viewModel.submit(using: repository)

        #expect(repository.lastSubmittedReview?.event.displayName == "FAM2999")
        #expect(repository.lastSubmittedReview?.event.kind == .flight)
    }

    @MainActor
    @Test func eventSuggestionsExpandCategoryAliasesIntoCanonicalEvents() async throws {
        let repository = MockInstructorReviewRepository()
        let viewModel = ReviewSubmissionViewModel()

        viewModel.load(using: repository)
        viewModel.submissionMode = .flights
        viewModel.selectedSquadron = repository.squadrons.first(where: { $0.displayName == "VT-27" })
        viewModel.eventName = "fams"

        #expect(viewModel.eventSuggestions.map(\.displayName) == ["FAM2101", "FAM2102"])
    }

    @MainActor
    @Test func syllabusReferenceLoadsRepresentativeEventsAndAliases() async throws {
        let reference = InstructorReviewSeedData.syllabusReference

        #expect(reference.category(forAlias: "Forms") == .formation)
        #expect(reference.category(forAlias: "INS") == .instruments)
        #expect(reference.category(forAlias: "Navaigation") == .navigation)
        #expect(reference.category(forAlias: "Contacts") == .familiarization)

        let fam2101 = try #require(reference.event(code: "FAM2101"))
        #expect(fam2101.category == .familiarization)
        #expect(fam2101.media == "UTD")
        #expect(fam2101.eventKind == .sim)

        let fam2202 = try #require(reference.event(code: "FAM2202"))
        #expect(fam2202.media == "OFT")
        #expect(fam2202.eventKind == .sim)

        let f2101 = try #require(reference.event(code: "F2101"))
        #expect(f2101.media == "UTD/MR")
        #expect(f2101.eventKind == .sim)

        let n4101 = try #require(reference.event(code: "N4101"))
        #expect(n4101.media == "T-6B")
        #expect(n4101.eventKind == .flight)

        for code in ["I4490", "F4290", "CS4290"] {
            let event = try #require(reference.event(code: code))
            #expect(event.isCheckride)
        }

        let fam4501 = try #require(reference.event(code: "FAM4501"))
        #expect(fam4501.isSolo)
    }

    @MainActor
    @Test func syllabusReferenceProvidesCanonicalShortTitles() throws {
        let reference = try loadSyllabusReferenceFromAppContent()

        let expectedTitles: [String: String] = [
            "FAM2101": "Cockpit Familiarization",
            "FAM2102": "Ground Emergencies",
            "FAM2201": "Takeoff Emergencies",
            "FAM2202": "Systems Emergencies",
            "FAM4304": "Solo Preparation and Boundaries",
            "FAM4601": "Night Contact Fundamentals",
            "FAM4701": "Aerobatics and OCF Recovery",
            "FAM4702": "Spins and AOA Approaches",
            "FAM4703": "Flight Loads and Emergency Review",
            "FAM6101": "Course Rules, OLF Operations, and Arrival Review",
            "FAM6102": "Risk Management and VFR Judgment",
            "FAM6201": "Low-Speed Handling and Energy Management",
            "FAM6202": "Outlying Pattern Entries and Crosswind Operations",
            "FAM6203": "Day Block Maneuver Review",
            "I4102": "ILS and LOC Approaches",
            "N4101": "VFR Chart Preparation",
            "F2101": "Formation Departure Procedures",
            "CS4101": "Capstone Maneuver and EP Flight 1"
        ]

        for (code, expectedTitle) in expectedTitles {
            let event = try #require(reference.event(code: code))
            #expect(event.shortTitle == expectedTitle)
        }
    }

    @MainActor
    @Test func canonicalEventResolutionMapsLegacyCheckFlightAlias() async throws {
        let event = InstructorReviewSeedData.event(for: "FAM4401", kind: .flight)
        #expect(event.displayName == "FAM4490")
        #expect(event.kind == .flight)
        #expect(event.syllabusCategory == .familiarization)
    }

    @MainActor
    @Test func manifestUsesCanonicalSyllabusEventCodesForTargetedEvents() throws {
        let manifest = try loadStudyManifestFromAppContent()
        let reference = try loadSyllabusReferenceFromAppContent()

        let manifestEvents = manifestEventLookup(from: manifest)
        let manifestCodes = Set(manifestEvents.keys)
        let referenceCodes = Set(reference.events.map(\.code))

        #expect(referenceCodes.isSubset(of: manifestCodes))
        #expect(manifestEvents["FAM4490"] != nil)
        #expect(manifestEvents["FAM4401"] == nil)
        #expect(manifestEvents["FAM4501"] != nil)
        #expect(manifestEvents["CS4290"] != nil)
    }

    @MainActor
    @Test func manifestUsesCanonicalSyllabusShortTitlesForTargetedEvents() throws {
        let manifest = try loadStudyManifestFromAppContent()
        let reference = try loadSyllabusReferenceFromAppContent()
        let manifestEvents = manifestEventLookup(from: manifest)

        for syllabusEvent in reference.events {
            let manifestEvent = try #require(manifestEvents[syllabusEvent.code])
            #expect(manifestEvent.title == syllabusEvent.shortTitle)
            #expect(manifestEvent.title != syllabusEvent.code)
        }
    }

    @MainActor
    @Test func canonicalDiscussionItemFlashcardDecksExistForAllSyllabusEvents() throws {
        let manifest = try loadStudyManifestFromAppContent()
        let reference = try loadSyllabusReferenceFromAppContent()
        let manifestEvents = manifestEventLookup(from: manifest)

        for syllabusEvent in reference.events {
            let manifestEvent = try #require(manifestEvents[syllabusEvent.code])
            #expect(manifestEvent.flashcardDecks.first?.title == "\(syllabusEvent.code) Discussion Item Flashcards")
        }
    }

    @MainActor
    @Test func nonEmergencyDiscussionItemFlashcardsUseTitleCaseAndPlaceholderAnswers() throws {
        let manifest = try loadStudyManifestFromAppContent()
        let manifestEvents = manifestEventLookup(from: manifest)
        let flashcardsByID = Dictionary(uniqueKeysWithValues: manifest.flashcards.map { ($0.id, $0) })

        let fam2101 = try #require(manifestEvents["FAM2101"])
        let deck = try #require(fam2101.flashcardDecks.first)
        let cards = try deck.cardIDs.map { cardID in
            try #require(flashcardsByID[cardID])
        }

        #expect(cards.map(\.prompt) == [
            "Checklist Challenge-Action Response Format",
            "Dual Concurrence/Response CRM",
            "Memorized Checklists",
            "Ground Handling Signals",
            "Safety Check/Call Prior to Cockpit Entry and Departing Aircraft",
            "Blindfold Cockpit Check"
        ])
        #expect(cards.allSatisfy { $0.answer == "Answer pending generation." })
        #expect(cards.allSatisfy { !$0.requiresVerbatim })
    }

    @MainActor
    @Test func emergencyProcedureFlashcardsInjectCanonicalEpAndCompanionNwcCards() throws {
        let manifest = try loadStudyManifestFromAppContent()
        let manifestEvents = manifestEventLookup(from: manifest)
        let flashcardsByID = Dictionary(uniqueKeysWithValues: manifest.flashcards.map { ($0.id, $0) })

        let fam2201 = try #require(manifestEvents["FAM2201"])
        let deck = try #require(fam2201.flashcardDecks.first)
        let cards = try deck.cardIDs.map { cardID in
            try #require(flashcardsByID[cardID])
        }

        #expect(Array(cards.prefix(6)).map(\.prompt) == [
            "Abort",
            "ABORT",
            "Aircraft Departs Prepared Surface",
            "Engine Failure Immediately After Takeoff (Sufficient Runway Remaining Straight Ahead)",
            "ENGINE FAILURE IMMEDIATELY AFTER TAKEOFF (SUFFICIENT RUNWAY REMAINING STRAIGHT AHEAD)",
            "Engine Failure During Flight"
        ])

        let abortEP = cards[0]
        let abortNWC = cards[1]
        #expect(abortEP.kind == .ep)
        #expect(abortEP.requiresVerbatim)
        #expect(abortNWC.requiresVerbatim)
        #expect(abortEP.companionGroupID == abortNWC.companionGroupID)
        #expect(cards.contains { $0.prompt == "UNCOMMANDED POWER CHANGES/LOSS OF\nPOWER/UNCOMMANDED PROPELLER FEATHER" })
        #expect(!cards.contains { $0.prompt == "Abort Takeoff" })
    }

    @MainActor
    @Test func emergencyProcedureAuditTracksUnresolvedItemsWithoutAliasOrCompanionFailures() throws {
        let audit = try loadSyllabusAuditReportFromAppContent()

        let aliasIssues = try #require(audit["emergencyProcedureAliasIssues"] as? [[String: Any]])
        let missingCompanions = try #require(audit["missingEmergencyProcedureCompanions"] as? [[String: Any]])
        let unresolvedItems = try #require(audit["unresolvedEmergencyProcedureItems"] as? [[String: Any]])

        #expect(aliasIssues.isEmpty)
        #expect(missingCompanions.isEmpty)
        #expect(unresolvedItems.contains {
            ($0["eventCode"] as? String) == "FAM3201" && ($0["discussionItem"] as? String) == "PEL"
        })
    }

    @MainActor
    @Test func authoredFamNotesRemainVisibleWhileOtherEventsUseSyllabusFallback() throws {
        let manifest = try loadStudyManifestFromAppContent()
        let manifestEvents = manifestEventLookup(from: manifest)

        let fam2101 = try #require(manifestEvents["FAM2101"])
        let famNotes = try #require(fam2101.studyNotes)
        #expect(famNotes.sections.count > 1)
        #expect(famNotes.sections.contains { $0.title == "Required Procedures" })

        let cs4101 = try #require(manifestEvents["CS4101"])
        let csNotes = try #require(cs4101.studyNotes)
        #expect(csNotes.summary?.contains("canonical syllabus event reference") == true)
        #expect(csNotes.sections.first?.title == "Capstone")
    }

    @MainActor
    @Test func famDiscussionAuthoringValidationPassesAndTemporaryAuditIsRemoved() throws {
        let audit = try loadSyllabusAuditReportFromAppContent()

        let discussionIssues = try #require(audit["discussionItemAuthoringIssues"] as? [[String: Any]])
        #expect(discussionIssues.isEmpty)

        let famAuditURL = appContentRoot().appendingPathComponent("FAMDiscussionItemsAudit.json")
        #expect(!FileManager.default.fileExists(atPath: famAuditURL.path))
    }

    @MainActor
    @Test func everyFamSyllabusEventHasAuthoredNotesAndNormalizedRequiredProcedures() throws {
        let manifest = try loadStudyManifestFromAppContent()
        let reference = try loadSyllabusReferenceFromAppContent()
        let manifestEvents = manifestEventLookup(from: manifest)

        let famEvents = reference.events
            .filter { $0.category == .familiarization }
            .sorted { $0.code < $1.code }

        for famEvent in famEvents {
            let manifestEvent = try #require(manifestEvents[famEvent.code])
            let notes = try #require(manifestEvent.studyNotes)
            let requiredSection = try #require(notes.sections.last)
            #expect(requiredSection.title == "Required Procedures")
            #expect(requiredSection.items.map(\.text).map(normalizedAuditText) == famEvent.discussionItems.map(normalizedAuditText))
        }
    }

    @MainActor
    @Test func representativeFamRefreshesProvideMultiSectionAuthoredNotes() throws {
        let manifest = try loadStudyManifestFromAppContent()
        let manifestEvents = manifestEventLookup(from: manifest)

        for code in ["FAM3301", "FAM3401", "FAM6101", "FAM6402"] {
            let event = try #require(manifestEvents[code])
            let notes = try #require(event.studyNotes)
            #expect(notes.sections.count >= 2)
            #expect(notes.sections.first?.items.isEmpty == false)
            #expect(notes.sections.last?.title == "Required Procedures")
        }
    }

    @MainActor
    @Test func fam3301UsesReadableGroupedDiscussionSections() throws {
        let manifest = try loadStudyManifestFromAppContent()
        let manifestEvents = manifestEventLookup(from: manifest)

        let event = try #require(manifestEvents["FAM3301"])
        let notes = try #require(event.studyNotes)
        let sectionTitles = notes.sections.compactMap(\.title)

        #expect(sectionTitles == [
            "Crosswind Operations",
            "Abort Takeoff and Maximum Braking",
            "Aircraft Departs Prepared Surface / Emergency Ground Egress",
            "Wind Shear Recovery",
            "UFCP Failure",
            "Required Procedures"
        ])
    }

    @MainActor
    @Test func fam3401UsesPerItemSectionsAndEventSpecificCopy() throws {
        let manifest = try loadStudyManifestFromAppContent()
        let manifestEvents = manifestEventLookup(from: manifest)

        let event = try #require(manifestEvents["FAM3401"])
        #expect(event.title == "Introduction to Aerobatics")
        #expect(event.summary.lowercased().contains("aerobatic"))
        #expect(!event.overview.lowercased().contains("this event ties together"))
        #expect(!event.overview.lowercased().contains("this event pulls together"))
        #expect(event.overview.lowercased().contains("first aerobatic maneuver set"))

        let notes = try #require(event.studyNotes)
        let summary = try #require(notes.summary)
        #expect(!summary.lowercased().contains("use these notes to cover every required discussion item in syllabus order"))
        #expect(summary.lowercased().contains("aerobatic"))
        #expect(notes.sections.compactMap(\.title) == [
            "AOA Approach",
            "Maneuvering Speeds",
            "Contact Unusual Attitudes",
            "Aileron Roll",
            "Loop",
            "Half Cuban Eight",
            "Immelmann",
            "Split-S",
            "Wingover",
            "Barrel Roll",
            "OCF Recovery",
            "Airborne Damaged Aircraft",
            "Combination Maneuvers",
            "HUD",
            "Required Procedures"
        ])

        let aoaSection = try #require(notes.sections.first(where: { $0.title == "AOA Approach" }))
        let aoaText = aoaSection.items.flatMap { [$0.text] + ($0.children?.map(\.text) ?? []) }.joined(separator: " ")
        #expect(aoaText.contains("10.5 units"))

        let maneuveringSpeedsSection = try #require(notes.sections.first(where: { $0.title == "Maneuvering Speeds" }))
        #expect(!maneuveringSpeedsSection.items.map(\.text).joined(separator: " ").contains("Know the limit before you need it"))

        for title in ["Aileron Roll", "Loop", "Half Cuban Eight", "Immelmann", "Split-S", "Wingover", "Barrel Roll"] {
            let section = try #require(notes.sections.first(where: { $0.title == title }))
            #expect(section.items.contains(where: { $0.text == "Entry setup:" }))
            #expect(section.items.contains(where: { $0.text == "Execution:" }))
            #expect(section.items.contains(where: { $0.text == "Maneuver complete when:" }))
        }

        let contactUASection = try #require(notes.sections.first(where: { $0.title == "Contact Unusual Attitudes" }))
        let noseHigh = try #require(contactUASection.items.first(where: { $0.text == "Nose-High:" }))
        #expect(noseHigh.children?.first?.text == "Set PCL to MAX.")
        let noseLow = try #require(contactUASection.items.first(where: { $0.text == "Nose-Low:" }))
        let noseLowChildren = noseLow.children?.map(\.text) ?? []
        #expect(noseLowChildren.first == "Roll the aircraft to the nearest horizon while simultaneously retarding PCL to IDLE.")
        #expect(noseLowChildren.dropFirst().first == "Use speed brake as required to help control the acceleration.")

        let aileronRollSection = try #require(notes.sections.first(where: { $0.title == "Aileron Roll" }))
        #expect(aileronRollSection.items.first?.text == "An aileron roll is a 360-degree roll about the longitudinal axis. The nose traces a small circle around the horizon and the maneuver finishes on the entry heading.")

        let loopSection = try #require(notes.sections.first(where: { $0.title == "Loop" }))
        let loopEntry = try #require(loopSection.items.first(where: { $0.text == "Entry setup:" }))
        let loopEntryText = ([loopEntry.text] + (loopEntry.children?.map(\.text) ?? [])).joined(separator: " ")
        #expect(loopEntryText.contains("MAX"))
        #expect(loopEntryText.contains("230 to 250 KIAS"))

        let cubanSection = try #require(notes.sections.first(where: { $0.title == "Half Cuban Eight" }))
        let cubanLead = try #require(cubanSection.items.first?.text)
        #expect(cubanLead.range(of: "followed by a pull to finish on reciprocal heading at the original altitude") != nil)
        let cubanEntry = try #require(cubanSection.items.first(where: { $0.text == "Entry setup:" }))
        let cubanEntryText = ([cubanEntry.text] + (cubanEntry.children?.map(\.text) ?? [])).joined(separator: " ")
        #expect(cubanEntryText.contains("MAX"))
        #expect(cubanEntryText.contains("230 to 250 KIAS"))
        #expect(cubanEntryText.contains("3000 feet"))

        let immelmannSection = try #require(notes.sections.first(where: { $0.title == "Immelmann" }))
        let immelmannEntry = try #require(immelmannSection.items.first(where: { $0.text == "Entry setup:" }))
        let immelmannEntryText = ([immelmannEntry.text] + (immelmannEntry.children?.map(\.text) ?? [])).joined(separator: " ")
        #expect(immelmannEntryText.contains("MAX"))
        #expect(immelmannEntryText.contains("230 to 250 KIAS"))
        let immelmannExecution = try #require(immelmannSection.items.first(where: { $0.text == "Execution:" }))
        let immelmannExecutionLead = (immelmannExecution.children ?? []).first?.text ?? ""
        #expect(immelmannExecutionLead.range(of: "4 G") != nil)

        let wingoverSection = try #require(notes.sections.first(where: { $0.title == "Wingover" }))
        let wingoverLead = try #require(wingoverSection.items.first?.text)
        #expect(wingoverLead.range(of: "two leafs") != nil)
        let wingoverEntry = try #require(wingoverSection.items.first(where: { $0.text == "Entry setup:" }))
        let wingoverEntryText = ([wingoverEntry.text] + (wingoverEntry.children?.map(\.text) ?? [])).joined(separator: " ")
        #expect(wingoverEntryText.contains("70 percent PCL"))
        #expect(wingoverEntryText.contains("200 to 220 KIAS"))

        let barrelSection = try #require(notes.sections.first(where: { $0.title == "Barrel Roll" }))
        let barrelLead = try #require(barrelSection.items.first?.text)
        #expect(barrelLead.range(of: "corkscrew path") != nil)
        let barrelEntry = try #require(barrelSection.items.first(where: { $0.text == "Entry setup:" }))
        let barrelEntryText = ([barrelEntry.text] + (barrelEntry.children?.map(\.text) ?? [])).joined(separator: " ")
        #expect(barrelEntryText.contains("80 percent PCL"))
        #expect(barrelEntryText.contains("200 to 220 KIAS"))

        let splitSSection = try #require(notes.sections.first(where: { $0.title == "Split-S" }))
        #expect(splitSSection.items.first?.text == "A Split-S combines a half roll to inverted with the second half of a loop. It reverses direction while converting altitude into airspeed and finishes in level flight.")

        let ocfSection = try #require(notes.sections.first(where: { $0.title == "OCF Recovery" }))
        let recoveryItem = try #require(ocfSection.items.first(where: { $0.text == "Recovery:" }))
        let recoveryText = ([recoveryItem.text] + (recoveryItem.children?.map(\.text) ?? [])).joined(separator: " ").lowercased()
        #expect(!recoveryText.contains("eject"))
        let criticalAltitudeItem = try #require(ocfSection.items.first(where: { $0.text == "Critical altitude reminder:" }))
        let criticalAltitudeText = (criticalAltitudeItem.children ?? []).map(\.text).joined(separator: " ")
        #expect(criticalAltitudeText.contains("6000 feet AGL"))
        let airborneDamagedSection = try #require(notes.sections.first(where: { $0.title == "Airborne Damaged Aircraft" }))
        #expect(airborneDamagedSection.items.map(\.text) == [
            "Airborne damaged aircraft procedures apply once the aircraft is still controllable but structural, control-surface, or engine damage is suspected.",
            "Immediate priorities:",
            "Controllability check:",
            "Landing considerations:"
        ])

        let hudSection = try #require(notes.sections.first(where: { $0.title == "HUD" }))
        #expect(hudSection.items.map(\.text) == [
            "Treat the HUD as a heads-up cross-check for aerobatic setup and recovery, not as the primary thing you are trying to fly off of. It should support the outside picture and help you stay oriented when the workload jumps.",
            "What to understand:",
            "How it helps:",
            "Study standard:"
        ])

        let requiredSection = try #require(notes.sections.last)
        #expect(requiredSection.items.map(\.text) == [
            "AOA Approach",
            "Maneuvering Speeds",
            "Contact Unusual Attitudes",
            "Aileron Roll",
            "Loop",
            "Half Cuban Eight",
            "Immelmann",
            "Split-S",
            "Wingover",
            "Barrel Roll",
            "OCF Recovery and Airborne Damaged Aircraft",
            "Combination Maneuvers",
            "HUD"
        ])
    }

    @MainActor
    @Test func famCheckFlightAndSoloEventsHaveAuthoredNotes() throws {
        let manifest = try loadStudyManifestFromAppContent()
        let manifestEvents = manifestEventLookup(from: manifest)

        for code in ["FAM4490", "FAM4501"] {
            let event = try #require(manifestEvents[code])
            let notes = try #require(event.studyNotes)
            #expect(!notes.sections.isEmpty)
        }

        let fam4501 = try #require(manifestEvents["FAM4501"])
        #expect(fam4501.summary == "Solo go/no-go, weather, support-agency, and execution priorities.")
        #expect(fam4501.studyNotes?.sections.first?.title == "Per the ODO/FDO Solo Brief")
    }

    @MainActor
    @Test func fam4101UsesReadablePerItemFlightSectionsWithoutLocalProcedureLeakage() throws {
        let manifest = try loadStudyManifestFromAppContent()
        let manifestEvents = manifestEventLookup(from: manifest)

        let event = try #require(manifestEvents["FAM4101"])
        #expect(event.title == "First Contact Flight")
        #expect(event.summary.lowercased().contains("first contact flight"))
        #expect(!event.overview.lowercased().contains("this is the first day familiarization flight"))

        let notes = try #require(event.studyNotes)
        let summary = try #require(notes.summary)
        #expect(summary.contains("P-A-T"))
        #expect(notes.sections.compactMap(\.title) == [
            "Ejection Seat and CFS",
            "Abnormal Starts",
            "Brake Failure",
            "Strike of Ground Object",
            "Takeoff",
            "Departure",
            "Basic Transitions",
            "Trim",
            "Turn Pattern",
            "Level Speed Change",
            "Slow Flight",
            "HUD",
            "Required Procedures"
        ])

        let departureSection = try #require(notes.sections.first(where: { $0.title == "Departure" }))
        let departureText = departureSection.items.flatMap { [$0.text] + ($0.children?.map(\.text) ?? []) }.joined(separator: " ").lowercased()
        for forbidden in ["waldron", "rusty", "high bridge", "camel humps", "pt silver", "pt sunrise", "beachline", "nueces", "oso", "shamrock", "corpus departure"] {
            #expect(!departureText.contains(forbidden))
        }
        #expect(departureText.contains("what stays local"))

        let takeoffSection = try #require(notes.sections.first(where: { $0.title == "Takeoff" }))
        let lineupItem = try #require(takeoffSection.items.first(where: { $0.text == "Lineup and before brake release:" }))
        let lineupText = ([lineupItem.text] + (lineupItem.children?.map(\.text) ?? [])).joined(separator: " ")
        #expect(lineupText.contains("30 percent"))

        let slowFlightSection = try #require(notes.sections.first(where: { $0.title == "Slow Flight" }))
        #expect(slowFlightSection.items.contains(where: { $0.text == "Common errors:" }))

        let hudSection = try #require(notes.sections.first(where: { $0.title == "HUD" }))
        #expect(hudSection.items.first?.text.contains("outside picture remains primary") == true)
    }

    @MainActor
    @Test func fam4102UsesFTIBackedPatternAndStallSections() throws {
        let manifest = try loadStudyManifestFromAppContent()
        let manifestEvents = manifestEventLookup(from: manifest)

        let event = try #require(manifestEvents["FAM4102"])
        #expect(event.title == "Stalls and Landing Pattern")
        #expect(event.summary.lowercased().contains("landing pattern"))
        #expect(event.summary.lowercased().contains("stall"))
        #expect(!event.overview.lowercased().contains("this event ties together"))

        let notes = try #require(event.studyNotes)
        #expect(notes.sections.compactMap(\.title) == [
            "Aborted Takeoff",
            "Tire Failures",
            "Power-On Stalls",
            "Power-Off Stalls",
            "Landing Pattern",
            "Landing Pattern Stalls",
            "No-Flap Landing",
            "Takeoff Flap Landing",
            "Landing Flap Landing",
            "Wave-Off",
            "Landing Irregularities",
            "Required Procedures"
        ])

        let patternSection = try #require(notes.sections.first(where: { $0.title == "Landing Pattern" }))
        let patternText = patternSection.items.flatMap { [$0.text] + ($0.children?.map(\.text) ?? []) }.joined(separator: " ")
        #expect(patternText.contains("25-30"))
        #expect(patternText.contains("45"))
        #expect(patternText.contains("120/115/110"))

        let noFlapSection = try #require(notes.sections.first(where: { $0.title == "No-Flap Landing" }))
        let noFlapText = noFlapSection.items.flatMap { [$0.text] + ($0.children?.map(\.text) ?? []) }.joined(separator: " ").lowercased()
        #expect(noFlapText.contains("delay"))
        #expect(noFlapText.contains("180"))

        let waveoffSection = try #require(notes.sections.first(where: { $0.title == "Wave-Off" }))
        let waveoffText = waveoffSection.items.flatMap { [$0.text] + ($0.children?.map(\.text) ?? []) }.joined(separator: " ").lowercased()
        #expect(waveoffText.contains("not a stall recovery"))
        #expect(waveoffText.contains("120 kias"))

        let stallSection = try #require(notes.sections.first(where: { $0.title == "Landing Pattern Stalls" }))
        #expect(stallSection.items.contains(where: { $0.text == "Approach Turn Stall:" }))
        #expect(stallSection.items.contains(where: { $0.text == "Landing Attitude Stall:" }))

        let powerOnSection = try #require(notes.sections.first(where: { $0.title == "Power-On Stalls" }))
        let powerOnText = powerOnSection.items.flatMap { [$0.text] + ($0.children?.map(\.text) ?? []) }.joined(separator: " ")
        #expect(powerOnText.contains("PCL"))

        let irregularitiesSection = try #require(notes.sections.first(where: { $0.title == "Landing Irregularities" }))
        let irregularitiesText = irregularitiesSection.items.flatMap { [$0.text] + ($0.children?.map(\.text) ?? []) }.joined(separator: " ")
        #expect(irregularitiesText.contains("Porpoising"))
        #expect(irregularitiesText.contains("Floating"))
        #expect(irregularitiesText.contains("Wing Rising After Touchdown"))

        let requiredProcedures = try #require(notes.sections.first(where: { $0.title == "Required Procedures" }))
        #expect(requiredProcedures.items.contains(where: { $0.text == "Power-On Stalls" }))
    }

    @MainActor
    @Test func fam4103GeneralizesLocalProceduresWithoutLosingArrivalLogic() throws {
        let manifest = try loadStudyManifestFromAppContent()
        let manifestEvents = manifestEventLookup(from: manifest)

        let event = try #require(manifestEvents["FAM4103"])
        #expect(event.title == "Course Rules and Arrivals")
        #expect(!event.overview.lowercased().contains("this event ties together"))
        #expect(!event.overview.lowercased().contains("shamrock"))
        #expect(!event.overview.lowercased().contains("corpus"))

        let notes = try #require(event.studyNotes)
        #expect(notes.sections.compactMap(\.title) == [
            "OLF Operations",
            "Local Course Rules",
            "Home-Field Arrival",
            "SCATSAFE Maneuver",
            "Required Procedures"
        ])

        let olfSection = try #require(notes.sections.first(where: { $0.title == "OLF Operations" }))
        let olfText = olfSection.items.flatMap { [$0.text] + ($0.children?.map(\.text) ?? []) }.joined(separator: " ").lowercased()
        #expect(olfText.contains("initial point"))
        #expect(olfText.contains("two-way communications"))

        let courseRulesSection = try #require(notes.sections.first(where: { $0.title == "Local Course Rules" }))
        let courseRulesText = courseRulesSection.items.flatMap { [$0.text] + ($0.children?.map(\.text) ?? []) }.joined(separator: " ").lowercased()
        #expect(courseRulesText.contains("published procedure"))
        #expect(courseRulesText.contains("day-of brief"))
        #expect(!courseRulesText.contains("waldron"))
        #expect(!courseRulesText.contains("rusty"))

        let arrivalSection = try #require(notes.sections.first(where: { $0.title == "Home-Field Arrival" }))
        let arrivalText = arrivalSection.items.flatMap { [$0.text] + ($0.children?.map(\.text) ?? []) }.joined(separator: " ").lowercased()
        #expect(arrivalText.contains("arrival gate"))
        #expect(arrivalText.contains("direct recovery"))
        #expect(!arrivalText.contains("shamrock"))

        let scatsafeSection = try #require(notes.sections.first(where: { $0.title == "SCATSAFE Maneuver" }))
        let scatsafeText = scatsafeSection.items.flatMap { [$0.text] + ($0.children?.map(\.text) ?? []) }.joined(separator: " ")
        #expect(scatsafeText.contains("80 KIAS"))
        #expect(scatsafeText.contains("45% torque"))
        #expect(scatsafeText.contains("Adverse Yaw"))
        #expect(scatsafeText.contains("Flap Retraction"))
    }

    @MainActor
    @Test func fam4104SeparatesCrosswindTechniqueFromRecoveryLogic() throws {
        let manifest = try loadStudyManifestFromAppContent()
        let manifestEvents = manifestEventLookup(from: manifest)

        let event = try #require(manifestEvents["FAM4104"])
        #expect(event.title == "Crosswind Operations and Recovery")
        #expect(!event.overview.lowercased().contains("this event ties together"))

        let notes = try #require(event.studyNotes)
        #expect(notes.sections.compactMap(\.title) == [
            "Crosswind Takeoff/Approach/Landing",
            "OCF",
            "Contact Unusual Attitudes",
            "Required Procedures"
        ])

        let crosswindSection = try #require(notes.sections.first(where: { $0.title == "Crosswind Takeoff/Approach/Landing" }))
        let crosswindText = crosswindSection.items.flatMap { [$0.text] + ($0.children?.map(\.text) ?? []) }.joined(separator: " ")
        #expect(crosswindText.contains("45 degrees"))
        #expect(crosswindText.contains("half the gust factor"))
        #expect(crosswindText.contains("upwind main"))

        let ocfSection = try #require(notes.sections.first(where: { $0.title == "OCF" }))
        let ocfText = ocfSection.items.flatMap { [$0.text] + ($0.children?.map(\.text) ?? []) }.joined(separator: " ")
        #expect(ocfText.contains("120-135 KIAS"))
        #expect(ocfText.contains("controls neutral"))
        #expect(ocfText.contains("6000 feet AGL"))

        let uaSection = try #require(notes.sections.first(where: { $0.title == "Contact Unusual Attitudes" }))
        #expect(uaSection.items.contains(where: { $0.text == "Nose-High:" }))
        #expect(uaSection.items.contains(where: { $0.text == "Nose-Low:" }))
        #expect(uaSection.items.contains(where: { $0.text == "Inverted:" }))
    }

    @MainActor
    @Test func fam4201BuildsEngineAndEmergencyLandingDecisionChain() throws {
        let manifest = try loadStudyManifestFromAppContent()
        let manifestEvents = manifestEventLookup(from: manifest)

        let event = try #require(manifestEvents["FAM4201"])
        #expect(event.title == "Engine and Emergency Landing Foundations")
        #expect(!event.overview.lowercased().contains("this event ties together"))

        let notes = try #require(event.studyNotes)
        #expect(notes.sections.compactMap(\.title) == [
            "NATOPS Limitations",
            "Engine System",
            "Engine Malfunctions",
            "ELP",
            "PEL",
            "Forced Landing",
            "Aldis Lamp Signals",
            "Required Procedures"
        ])

        let systemsBrief = try #require(event.systemsBrief)
        #expect(systemsBrief.headline == "Systems brief")
        #expect(systemsBrief.sections.compactMap(\.title) == [
            "How to Brief the System",
            "Engine System",
            "Air Molecule",
            "Fuel Molecule"
        ])

        let engineSection = try #require(notes.sections.first(where: { $0.title == "Engine System" }))
        let engineText = engineSection.items.flatMap { [$0.text] + ($0.children?.map(\.text) ?? []) }.joined(separator: " ")
        #expect(engineText.contains("Use the Systems brief tool"))
        #expect(engineText.contains("67% N1"))
        #expect(!engineText.contains("inertial separator"))

        let systemsText = systemsBrief.sections.flatMap { section in
            section.items.flatMap { [$0.text] + ($0.children?.map(\.text) ?? []) }
        }.joined(separator: " ")
        #expect(systemsText.contains("1100 shaft horsepower"))
        #expect(systemsText.contains("inertial separator"))
        #expect(systemsText.contains("flow divider"))
        #expect(systemsText.contains("2000 RPM"))

        let elpSection = try #require(notes.sections.first(where: { $0.title == "ELP" }))
        let elpText = elpSection.items.flatMap { [$0.text] + ($0.children?.map(\.text) ?? []) }.joined(separator: " ")
        #expect(elpText.contains("3000 feet AGL"))
        #expect(elpText.contains("120 KIAS minimum"))
        #expect(elpText.contains("ORM 3-2-1"))

        let pelSection = try #require(notes.sections.first(where: { $0.title == "PEL" }))
        let pelText = pelSection.items.flatMap { [$0.text] + ($0.children?.map(\.text) ?? []) }.joined(separator: " ")
        #expect(pelText.contains("Turn, Climb/Accelerate, Clean"))
        #expect(pelText.contains("4-6% torque"))

        let forcedLandingSection = try #require(notes.sections.first(where: { $0.title == "Forced Landing" }))
        let forcedLandingText = forcedLandingSection.items.flatMap { [$0.text] + ($0.children?.map(\.text) ?? []) }.joined(separator: " ")
        #expect(forcedLandingText.contains("125 KIAS"))
        #expect(forcedLandingText.contains("PCL OFF"))
        #expect(forcedLandingText.contains("2000 feet AGL"))

        let aldisSection = try #require(notes.sections.first(where: { $0.title == "Aldis Lamp Signals" }))
        let aldisText = aldisSection.items.flatMap { [$0.text] + ($0.children?.map(\.text) ?? []) }.joined(separator: " ")
        #expect(aldisText.contains("steady green"))
        #expect(aldisText.contains("red pyrotechnic"))
    }

    @MainActor
    @Test func fam4202SeparatesSpinHydraulicsAndCrosswindRepetition() throws {
        let manifest = try loadStudyManifestFromAppContent()
        let manifestEvents = manifestEventLookup(from: manifest)

        let event = try #require(manifestEvents["FAM4202"])
        #expect(event.title == "Hydraulics, Spins, and Crosswinds")
        #expect(!event.overview.lowercased().contains("this event ties together"))

        let notes = try #require(event.studyNotes)
        #expect(notes.sections.compactMap(\.title) == [
            "Hydraulic System",
            "Spin",
            "OCF Recovery Procedures",
            "Anti-Spin Recovery Procedures",
            "Crosswind Takeoffs/Touch-and-Goes/Full-Stop Landings",
            "Required Procedures"
        ])

        let systemsBrief = try #require(event.systemsBrief)
        #expect(systemsBrief.headline == "Systems brief")
        #expect(systemsBrief.sections.compactMap(\.title) == [
            "How to Brief the System",
            "Hydraulic Power Package",
            "Selector Manifold and Normal Services",
            "Emergency System and Accumulator Logic",
            "Indications and Traps"
        ])

        let hydraulicSection = try #require(notes.sections.first(where: { $0.title == "Hydraulic System" }))
        let hydraulicText = hydraulicSection.items.flatMap { [$0.text] + ($0.children?.map(\.text) ?? []) }.joined(separator: " ")
        #expect(hydraulicText.contains("Use the Systems brief tool"))
        #expect(hydraulicText.contains("gear, flap, or NWS decisions"))
        #expect(hydraulicText.contains("one-time"))
        #expect(!hydraulicText.contains("selector manifold routes pressure"))

        let hydraulicSystemsText = systemsBrief.sections.flatMap { section in
            section.items.flatMap { [$0.text] + ($0.children?.map(\.text) ?? []) }
        }.joined(separator: " ")
        #expect(hydraulicSystemsText.contains("5 quarts"))
        #expect(hydraulicSystemsText.contains("3000 +/- 120 PSI"))
        #expect(hydraulicSystemsText.contains("12 degrees"))
        #expect(hydraulicSystemsText.contains("one-time"))

        let spinSection = try #require(notes.sections.first(where: { $0.title == "Spin" }))
        let spinText = spinSection.items.flatMap { [$0.text] + ($0.children?.map(\.text) ?? []) }.joined(separator: " ")
        #expect(spinText.contains("13,500 feet AGL"))
        #expect(spinText.contains("150 KIAS"))
        #expect(spinText.contains("PCL to IDLE") || spinText.contains("PCL to IDLE"))

        let ocfSection = try #require(notes.sections.first(where: { $0.title == "OCF Recovery Procedures" }))
        let ocfText = ocfSection.items.flatMap { [$0.text] + ($0.children?.map(\.text) ?? []) }.joined(separator: " ")
        #expect(ocfText.contains("CONTROLS - NEUTRAL"))
        #expect(ocfText.contains("6000 feet AGL"))

        let antiSpinSection = try #require(notes.sections.first(where: { $0.title == "Anti-Spin Recovery Procedures" }))
        let antiSpinText = antiSpinSection.items.flatMap { [$0.text] + ($0.children?.map(\.text) ?? []) }.joined(separator: " ")
        #expect(antiSpinText.contains("120-135 KIAS"))
        #expect(antiSpinText.contains("full rudder opposite"))

        let crosswindSection = try #require(notes.sections.first(where: { $0.title == "Crosswind Takeoffs/Touch-and-Goes/Full-Stop Landings" }))
        let crosswindText = crosswindSection.items.flatMap { [$0.text] + ($0.children?.map(\.text) ?? []) }.joined(separator: " ")
        #expect(crosswindText.contains("45 degrees"))
        #expect(crosswindText.contains("half the gust factor"))
        #expect(crosswindText.contains("upwind main"))
    }

    @MainActor
    @Test func fam4203SplitsSystemsBriefFromRecoveryDiscussionItems() throws {
        let manifest = try loadStudyManifestFromAppContent()
        let manifestEvents = manifestEventLookup(from: manifest)

        let event = try #require(manifestEvents["FAM4203"])
        #expect(event.title == "Oil, Airstarts, and Recovery Decisions")
        #expect(!event.overview.lowercased().contains("this event ties together"))

        let notes = try #require(event.studyNotes)
        #expect(notes.sections.compactMap(\.title) == [
            "Oil and Propeller Systems",
            "Engine Air Starts",
            "Ejection Decision and Setup",
            "Visual Straight-In",
            "Required Procedures"
        ])

        let systemsBrief = try #require(event.systemsBrief)
        #expect(systemsBrief.headline == "Systems brief")
        #expect(systemsBrief.sections.compactMap(\.title) == [
            "How to Brief the System",
            "Oil System",
            "Propeller System"
        ])

        let systemsText = systemsBrief.sections.flatMap { section in
            section.items.flatMap { [$0.text] + ($0.children?.map(\.text) ?? []) }
        }.joined(separator: " ")
        #expect(systemsText.contains("18.5 quarts"))
        #expect(systemsText.contains("2000 RPM"))
        #expect(systemsText.contains("62-80% NP"))

        let airStartSection = try #require(notes.sections.first(where: { $0.title == "Engine Air Starts" }))
        let airStartText = airStartSection.items.flatMap { [$0.text] + ($0.children?.map(\.text) ?? []) }.joined(separator: " ")
        #expect(airStartText.contains("125-200 KIAS"))
        #expect(airStartText.contains("67% N1"))
        #expect(airStartText.contains("2000 feet AGL"))

        let ejectionSection = try #require(notes.sections.first(where: { $0.title == "Ejection Decision and Setup" }))
        let ejectionText = ejectionSection.items.flatMap { [$0.text] + ($0.children?.map(\.text) ?? []) }.joined(separator: " ")
        #expect(ejectionText.contains("6000 feet AGL"))
        #expect(ejectionText.contains("ORM 3-2-1"))

        let visualSection = try #require(notes.sections.first(where: { $0.title == "Visual Straight-In" }))
        let visualText = visualSection.items.flatMap { [$0.text] + ($0.children?.map(\.text) ?? []) }.joined(separator: " ")
        #expect(visualText.contains("3-5 NM"))
        #expect(visualText.contains("110/105/100 KIAS"))
        #expect(!visualText.lowercased().contains("shamrock"))
        #expect(!visualText.lowercased().contains("kngp"))
    }

    @MainActor
    @Test func fam4204UsesSystemsBriefAndGeneralizedLostCommsProcedure() throws {
        let manifest = try loadStudyManifestFromAppContent()
        let manifestEvents = manifestEventLookup(from: manifest)

        let event = try #require(manifestEvents["FAM4204"])
        #expect(event.title == "Electrical, Avionics, and Lost-Comms Recovery")
        #expect(!event.overview.lowercased().contains("this event ties together"))

        let notes = try #require(event.studyNotes)
        #expect(notes.sections.compactMap(\.title) == [
            "Electrical System",
            "Avionics Malfunctions",
            "Lost Communications",
            "Local Area Flight Procedures/SOP",
            "Required Procedures"
        ])

        let systemsBrief = try #require(event.systemsBrief)
        #expect(systemsBrief.headline == "Systems brief")
        #expect(systemsBrief.sections.compactMap(\.title) == [
            "How to Brief the System",
            "Power Sources",
            "Bus Structure and Backup Paths",
            "Failure Logic and Load Shedding"
        ])

        let systemsText = systemsBrief.sections.flatMap { section in
            section.items.flatMap { [$0.text] + ($0.children?.map(\.text) ?? []) }
        }.joined(separator: " ")
        #expect(systemsText.contains("300-amp starter-generator"))
        #expect(systemsText.contains("42-amp-hour"))
        #expect(systemsText.contains("25 volts"))
        #expect(systemsText.contains("hot battery bus"))

        let avionicsSection = try #require(notes.sections.first(where: { $0.title == "Avionics Malfunctions" }))
        let avionicsText = avionicsSection.items.flatMap { [$0.text] + ($0.children?.map(\.text) ?? []) }.joined(separator: " ")
        #expect(avionicsText.contains("BFI"))
        #expect(avionicsText.contains("REPEAT"))
        #expect(avionicsText.contains("land as soon as practical"))

        let lostCommsSection = try #require(notes.sections.first(where: { $0.title == "Lost Communications" }))
        let lostCommsText = lostCommsSection.items.flatMap { [$0.text] + ($0.children?.map(\.text) ?? []) }.joined(separator: " ")
        #expect(lostCommsText.contains("7600"))
        #expect(lostCommsText.contains("IDENT"))

        let localSection = try #require(notes.sections.first(where: { $0.title == "Local Area Flight Procedures/SOP" }))
        let localText = localSection.items.flatMap { [$0.text] + ($0.children?.map(\.text) ?? []) }.joined(separator: " ")
        #expect(localText.contains("ALDIS"))
        #expect(!localText.lowercased().contains("shamrock"))
        #expect(!localText.lowercased().contains("waldron"))
        #expect(!localText.lowercased().contains("rusty"))
        #expect(!localText.lowercased().contains("kngp"))
    }

    @MainActor
    @Test func fam4301BalancesSystemsAbortAndRecoveryJudgment() throws {
        let manifest = try loadStudyManifestFromAppContent()
        let manifestEvents = manifestEventLookup(from: manifest)

        let event = try #require(manifestEvents["FAM4301"])
        #expect(event.title == "OBOGS, Aborts, and Recovery Decisions")
        #expect(!event.overview.lowercased().contains("this event ties together"))

        let notes = try #require(event.studyNotes)
        #expect(notes.sections.compactMap(\.title) == [
            "OBOGS and Pressurization System",
            "Aborted Takeoff",
            "Lost Aircraft Procedures",
            "Discontinued Entry",
            "Airborne-Damaged Aircraft",
            "Required Procedures"
        ])

        let systemsBrief = try #require(event.systemsBrief)
        #expect(systemsBrief.headline == "Systems brief")
        #expect(systemsBrief.sections.compactMap(\.title) == [
            "How to Brief the System",
            "OBOGS",
            "Pressurization and ECS"
        ])

        let systemsText = systemsBrief.sections.flatMap { section in
            section.items.flatMap { [$0.text] + ($0.children?.map(\.text) ?? []) }
        }.joined(separator: " ")
        #expect(systemsText.contains("molecular-sieve concentrator"))
        #expect(systemsText.contains("4-minute warm-up"))
        #expect(systemsText.contains("3.6 ± 0.2 PSI"))

        let abortSection = try #require(notes.sections.first(where: { $0.title == "Aborted Takeoff" }))
        let abortText = abortSection.items.flatMap { [$0.text] + ($0.children?.map(\.text) ?? []) }.joined(separator: " ")
        #expect(abortText.contains("1500 feet or 60 KIAS"))
        #expect(abortText.contains("80 KIAS"))
        #expect(abortText.contains("parking brake"))

        let lostSection = try #require(notes.sections.first(where: { $0.title == "Lost Aircraft Procedures" }))
        let lostText = lostSection.items.flatMap { [$0.text] + ($0.children?.map(\.text) ?? []) }.joined(separator: " ")
        #expect(lostText.contains("Five Cs"))
        #expect(lostText.contains("8.8 units"))
        #expect(lostText.contains("125 ± 8 KIAS"))

        let discontinuedSection = try #require(notes.sections.first(where: { $0.title == "Discontinued Entry" }))
        let discontinuedText = discontinuedSection.items.flatMap { [$0.text] + ($0.children?.map(\.text) ?? []) }.joined(separator: " ")
        #expect(!discontinuedText.lowercased().contains("goliad"))
        #expect(!discontinuedText.lowercased().contains("shamrock"))
        #expect(!discontinuedText.lowercased().contains("ppel/p"))

        let damagedSection = try #require(notes.sections.first(where: { $0.title == "Airborne-Damaged Aircraft" }))
        let damagedText = damagedSection.items.flatMap { [$0.text] + ($0.children?.map(\.text) ?? []) }.joined(separator: " ")
        #expect(damagedText.contains("6500 feet AGL"))
        #expect(damagedText.contains("90 KIAS"))
        #expect(damagedText.contains("PEL"))
    }

    @MainActor
    @Test func fam4302SplitsFuelSystemsFromLandingAndCriticalActionPrep() throws {
        let manifest = try loadStudyManifestFromAppContent()
        let manifestEvents = manifestEventLookup(from: manifest)

        let event = try #require(manifestEvents["FAM4302"])
        #expect(event.title == "Fuel System and Full-Stop Landings")
        #expect(!event.overview.lowercased().contains("this event ties together"))

        let notes = try #require(event.studyNotes)
        #expect(notes.sections.compactMap(\.title) == [
            "Fuel System",
            "Full-Stop Landings",
            "Heavy-Weight Landing Considerations",
            "Any Critical Action Emergency Procedure",
            "Required Procedures"
        ])

        let systemsBrief = try #require(event.systemsBrief)
        #expect(systemsBrief.headline == "Systems brief")
        #expect(systemsBrief.sections.compactMap(\.title) == [
            "How to Brief the System",
            "Fuel Supply and Tanks",
            "Fuel Quantity and Balancing",
            "Engine Feed and Backup Paths",
            "Indications and Brief Traps"
        ])

        let fuelSection = try #require(notes.sections.first(where: { $0.title == "Fuel System" }))
        let fuelText = fuelSection.items.flatMap { [$0.text] + ($0.children?.map(\.text) ?? []) }.joined(separator: " ")
        #expect(fuelText.contains("Use the Systems brief tool"))
        #expect(fuelText.contains("150 pounds per side"))
        #expect(!fuelText.contains("14 fuel nozzles"))

        let systemsText = systemsBrief.sections.flatMap { section in
            section.items.flatMap { [$0.text] + ($0.children?.map(\.text) ?? []) }
        }.joined(separator: " ")
        #expect(systemsText.contains("1100 pounds"))
        #expect(systemsText.contains("1200 pounds"))
        #expect(systemsText.contains("flip-flop valve"))
        #expect(systemsText.contains("14 fuel nozzles"))

        let fullStopSection = try #require(notes.sections.first(where: { $0.title == "Full-Stop Landings" }))
        let fullStopText = fullStopSection.items.flatMap { [$0.text] + ($0.children?.map(\.text) ?? []) }.joined(separator: " ")
        #expect(fullStopText.contains("5-10 feet AGL"))
        #expect(fullStopText.contains("below 80 KIAS"))
        #expect(fullStopText.contains("NWS"))

        let heavySection = try #require(notes.sections.first(where: { $0.title == "Heavy-Weight Landing Considerations" }))
        let heavyText = heavySection.items.flatMap { [$0.text] + ($0.children?.map(\.text) ?? []) }.joined(separator: " ")
        #expect(heavyText.contains("3-5 KIAS"))
        #expect(heavyText.contains("amber donut"))
        #expect(heavyText.contains("longer ground roll"))

        let epSection = try #require(notes.sections.first(where: { $0.title == "Any Critical Action Emergency Procedure" }))
        let epText = epSection.items.flatMap { [$0.text] + ($0.children?.map(\.text) ?? []) }.joined(separator: " ")
        #expect(epText.contains("dedicated EP and N/W/C references"))
        #expect(epText.contains("Engine Failure Immediately After Takeoff"))
        #expect(epText.contains("PMU OFF Air-Start"))
    }

    @MainActor
    @Test func fam4303GeneralizesLandingAbnormalRecoveryWithoutLocalLeakage() throws {
        let manifest = try loadStudyManifestFromAppContent()
        let manifestEvents = manifestEventLookup(from: manifest)

        let event = try #require(manifestEvents["FAM4303"])
        #expect(event.title == "Landing and Configuration Emergencies")
        #expect(!event.overview.lowercased().contains("this event ties together"))

        let notes = try #require(event.studyNotes)
        #expect(notes.sections.compactMap(\.title) == [
            "Hard Landings",
            "Gear Emergencies",
            "Flap Failures",
            "Emergency Orbit Pattern",
            "Any Critical Action Emergency Procedures",
            "Required Procedures"
        ])

        let hardLandingSection = try #require(notes.sections.first(where: { $0.title == "Hard Landings" }))
        let hardLandingText = hardLandingSection.items.flatMap { [$0.text] + ($0.children?.map(\.text) ?? []) }.joined(separator: " ")
        #expect(hardLandingText.contains("6900 pounds"))
        #expect(hardLandingText.contains("600 FPM"))
        #expect(hardLandingText.contains("110 KIAS"))
        #expect(hardLandingText.contains("do not raise the gear"))

        let gearSection = try #require(notes.sections.first(where: { $0.title == "Gear Emergencies" }))
        let gearText = gearSection.items.flatMap { [$0.text] + ($0.children?.map(\.text) ?? []) }.joined(separator: " ")
        #expect(gearText.contains("150 KIAS"))
        #expect(gearText.contains("1800 PSI"))
        #expect(gearText.contains("LDGGR CONT"))
        #expect(gearText.contains("one-way decision"))

        let flapSection = try #require(notes.sections.first(where: { $0.title == "Flap Failures" }))
        let flapText = flapSection.items.flatMap { [$0.text] + ($0.children?.map(\.text) ?? []) }.joined(separator: " ")
        #expect(flapText.contains("speed brake"))
        #expect(flapText.contains("straight-in approach"))

        let orbitSection = try #require(notes.sections.first(where: { $0.title == "Emergency Orbit Pattern" }))
        let orbitText = orbitSection.items.flatMap { [$0.text] + ($0.children?.map(\.text) ?? []) }.joined(separator: " ")
        #expect(orbitText.contains("120 KIAS"))
        #expect(orbitText.contains("gear down and flaps up"))
        #expect(orbitText.contains("day-of SOP"))
        #expect(!orbitText.lowercased().contains("kngp"))
        #expect(!orbitText.lowercased().contains("goliad"))
        #expect(!orbitText.lowercased().contains("waldron"))
        #expect(!orbitText.lowercased().contains("cabaniss"))

        let epSection = try #require(notes.sections.first(where: { $0.title == "Any Critical Action Emergency Procedures" }))
        let epText = epSection.items.flatMap { [$0.text] + ($0.children?.map(\.text) ?? []) }.joined(separator: " ")
        #expect(epText.contains("dedicated EP and N/W/C references"))
        #expect(epText.contains("Abort Takeoff"))
        #expect(epText.contains("PMU OFF Air-Start"))
    }

    @MainActor
    @Test func fam4304TurnsSoloPrepIntoTransferableDecisionMaking() throws {
        let manifest = try loadStudyManifestFromAppContent()
        let manifestEvents = manifestEventLookup(from: manifest)

        let event = try #require(manifestEvents["FAM4304"])
        #expect(event.title == "Solo Preparation and Boundaries")
        #expect(!event.overview.lowercased().contains("this event ties together"))
        #expect(event.overview.lowercased().contains("solo preparation"))
        #expect(event.overview.lowercased().contains("published procedure"))
        #expect(event.overview.lowercased().contains("day-of brief"))

        let notes = try #require(event.studyNotes)
        #expect(notes.sections.compactMap(\.title) == [
            "Securing Rear Cockpit for Solo",
            "Unauthorized Solo Maneuvers",
            "Unintentional Instrument Flight",
            "Local Course Rules",
            "Any Previously Discussed Maneuver or Procedure",
            "Required Procedures"
        ])

        let securingSection = try #require(notes.sections.first(where: { $0.title == "Securing Rear Cockpit for Solo" }))
        let securingText = securingSection.items.flatMap { [$0.text] + ($0.children?.map(\.text) ?? []) }.joined(separator: " ")
        #expect(securingText.contains("ISS mode selector"))
        #expect(securingText.contains("SOLO"))
        #expect(securingText.contains("full aft stick"))

        let unauthorizedSection = try #require(notes.sections.first(where: { $0.title == "Unauthorized Solo Maneuvers" }))
        let unauthorizedText = unauthorizedSection.items.flatMap { [$0.text] + ($0.children?.map(\.text) ?? []) }.joined(separator: " ")
        #expect(unauthorizedText.contains("spins"))
        #expect(unauthorizedText.contains("stalls"))
        #expect(unauthorizedText.contains("PPELs"))

        let imcSection = try #require(notes.sections.first(where: { $0.title == "Unintentional Instrument Flight" }))
        let imcText = imcSection.items.flatMap { [$0.text] + ($0.children?.map(\.text) ?? []) }.joined(separator: " ")
        #expect(imcText.contains("MEF + 1000 feet"))
        #expect(imcText.contains("7700"))

        let courseRulesSection = try #require(notes.sections.first(where: { $0.title == "Local Course Rules" }))
        let courseRulesText = courseRulesSection.items.flatMap { [$0.text] + ($0.children?.map(\.text) ?? []) }.joined(separator: " ").lowercased()
        #expect(courseRulesText.contains("published procedure"))
        #expect(courseRulesText.contains("day-of brief"))
        for forbidden in ["corpus", "kngp", "shamrock", "goliad", "zombie"] {
            #expect(!courseRulesText.contains(forbidden))
        }

        let reviewSection = try #require(notes.sections.first(where: { $0.title == "Any Previously Discussed Maneuver or Procedure" }))
        let reviewText = reviewSection.items.flatMap { [$0.text] + ($0.children?.map(\.text) ?? []) }.joined(separator: " ")
        #expect(reviewText.contains("cumulative review"))
        #expect(reviewText.contains("wave off"))
        #expect(reviewText.contains("PEL"))
    }

    @MainActor
    @Test func fam4490BuildsCumulativeCheckFlightReviewWithoutLocalLeakage() throws {
        let manifest = try loadStudyManifestFromAppContent()
        let manifestEvents = manifestEventLookup(from: manifest)

        let event = try #require(manifestEvents["FAM4490"])
        #expect(event.title == "Familiarization Check Flight")
        #expect(!event.overview.lowercased().contains("this event ties together"))
        #expect(event.overview.lowercased().contains("cumulative"))
        #expect(event.summary.lowercased().contains("emergency-decision"))

        let notes = try #require(event.studyNotes)
        #expect(notes.sections.compactMap(\.title) == [
            "Any Previously Discussed Items",
            "Unauthorized Solo Maneuvers",
            "Lost Aircraft Procedures",
            "Unintentional Instrument Flight",
            "Local Course Rules",
            "Maneuvers",
            "Emergency Procedures",
            "Required Procedures"
        ])

        let anyItemsSection = try #require(notes.sections.first(where: { $0.title == "Any Previously Discussed Items" }))
        let anyItemsText = anyItemsSection.items.flatMap { [$0.text] + ($0.children?.map(\.text) ?? []) }.joined(separator: " ")
        #expect(anyItemsText.contains("challenge-action-response"))
        #expect(anyItemsText.contains("FAM2101 through FAM4304"))

        let lostSection = try #require(notes.sections.first(where: { $0.title == "Lost Aircraft Procedures" }))
        let lostText = lostSection.items.flatMap { [$0.text] + ($0.children?.map(\.text) ?? []) }.joined(separator: " ")
        #expect(lostText.contains("Five Cs"))
        #expect(lostText.contains("125 +/- 8 KIAS"))

        let imcSection = try #require(notes.sections.first(where: { $0.title == "Unintentional Instrument Flight" }))
        let imcText = imcSection.items.flatMap { [$0.text] + ($0.children?.map(\.text) ?? []) }.joined(separator: " ")
        #expect(imcText.contains("MEF + 1000 feet"))
        #expect(imcText.contains("7700"))

        let courseRulesSection = try #require(notes.sections.first(where: { $0.title == "Local Course Rules" }))
        let courseRulesText = courseRulesSection.items.flatMap { [$0.text] + ($0.children?.map(\.text) ?? []) }.joined(separator: " ").lowercased()
        #expect(courseRulesText.contains("published procedure"))
        #expect(courseRulesText.contains("day-of brief"))
        for forbidden in ["shamrock", "rusty", "waldron", "kngp", "corpus"] {
            #expect(!courseRulesText.contains(forbidden))
        }

        let maneuverSection = try #require(notes.sections.first(where: { $0.title == "Maneuvers" }))
        let maneuverText = maneuverSection.items.flatMap { [$0.text] + ($0.children?.map(\.text) ?? []) }.joined(separator: " ")
        #expect(maneuverText.contains("crosswind operations"))
        #expect(maneuverText.contains("setup numbers"))

        let emergencySection = try #require(notes.sections.first(where: { $0.title == "Emergency Procedures" }))
        let emergencyText = emergencySection.items.flatMap { [$0.text] + ($0.children?.map(\.text) ?? []) }.joined(separator: " ")
        #expect(emergencyText.contains("PMU OFF air-start"))
        #expect(emergencyText.contains("PEL"))
        #expect(emergencyText.contains("eject"))
    }

    @MainActor
    @Test func fam4501KeepsSoloBriefConservativeAndDayOfBriefDriven() throws {
        let manifest = try loadStudyManifestFromAppContent()
        let manifestEvents = manifestEventLookup(from: manifest)

        let event = try #require(manifestEvents["FAM4501"])
        #expect(event.title == "Familiarization Solo Flight")
        #expect(!event.overview.lowercased().contains("this event ties together"))
        #expect(event.summary == "Solo go/no-go, weather, support-agency, and execution priorities.")

        let notes = try #require(event.studyNotes)
        #expect(notes.sections.compactMap(\.title) == [
            "Per the ODO/FDO Solo Brief",
            "Required Procedures"
        ])

        let soloBriefSection = try #require(notes.sections.first(where: { $0.title == "Per the ODO/FDO Solo Brief" }))
        let soloBriefText = soloBriefSection.items.flatMap { [$0.text] + ($0.children?.map(\.text) ?? []) }.joined(separator: " ")
        #expect(soloBriefText.contains("go/no-go"))
        #expect(soloBriefText.contains("current published procedure"))
        #expect(soloBriefText.contains("day-of ODO/FDO solo brief still remains required"))
        #expect(soloBriefText.contains("rear-cockpit securing"))
        #expect(soloBriefText.contains("lose radios"))
        for forbidden in ["shamrock", "rusty", "waldron", "kngp", "corpus"] {
            #expect(!soloBriefText.lowercased().contains(forbidden))
        }
    }

    @MainActor
    @Test func fam4601CombinesNightTechniqueLightingAndElectricalPriorities() throws {
        let manifest = try loadStudyManifestFromAppContent()
        let manifestEvents = manifestEventLookup(from: manifest)

        let event = try #require(manifestEvents["FAM4601"])
        #expect(event.title == "Night Contact Fundamentals")
        #expect(!event.overview.lowercased().contains("this event ties together"))
        #expect(event.summary.lowercased().contains("night"))
        #expect(event.summary.lowercased().contains("electrical"))

        let notes = try #require(event.studyNotes)
        #expect(notes.sections.compactMap(\.title) == [
            "Night Flying Considerations",
            "Night VFR Chart Interpretation",
            "Airport Night Lighting",
            "Aircraft and Cockpit Lighting",
            "Applicable Night Emergencies",
            "Local Night SOP",
            "Electrical System Malfunctions",
            "Required Procedures"
        ])

        let nightSection = try #require(notes.sections.first(where: { $0.title == "Night Flying Considerations" }))
        let nightText = nightSection.items.flatMap { [$0.text] + ($0.children?.map(\.text) ?? []) }.joined(separator: " ")
        #expect(nightText.contains("30 minutes"))
        #expect(nightText.contains("10 seconds"))
        #expect(nightText.contains("off-center"))

        let chartSection = try #require(notes.sections.first(where: { $0.title == "Night VFR Chart Interpretation" }))
        let chartText = chartSection.items.flatMap { [$0.text] + ($0.children?.map(\.text) ?? []) }.joined(separator: " ")
        #expect(chartText.contains("MEF"))
        #expect(chartText.contains("pilot-controlled lighting"))

        let lightingSection = try #require(notes.sections.first(where: { $0.title == "Airport Night Lighting" }))
        let lightingText = lightingSection.items.flatMap { [$0.text] + ($0.children?.map(\.text) ?? []) }.joined(separator: " ")
        #expect(lightingText.contains("blue"))
        #expect(lightingText.contains("green"))
        #expect(lightingText.contains("REIL"))

        let emergenciesSection = try #require(notes.sections.first(where: { $0.title == "Applicable Night Emergencies" }))
        let emergenciesText = emergenciesSection.items.flatMap { [$0.text] + ($0.children?.map(\.text) ?? []) }.joined(separator: " ")
        #expect(emergenciesText.contains("2000 feet AGL"))
        #expect(emergenciesText.contains("eject"))

        let localSection = try #require(notes.sections.first(where: { $0.title == "Local Night SOP" }))
        let localText = localSection.items.flatMap { [$0.text] + ($0.children?.map(\.text) ?? []) }.joined(separator: " ").lowercased()
        #expect(localText.contains("published procedure"))
        #expect(localText.contains("day-of brief"))
        for forbidden in ["corpus", "kngp", "waldron", "rusty", "goliad"] {
            #expect(!localText.contains(forbidden))
        }

        let electricalSection = try #require(notes.sections.first(where: { $0.title == "Electrical System Malfunctions" }))
        let electricalText = electricalSection.items.flatMap { [$0.text] + ($0.children?.map(\.text) ?? []) }.joined(separator: " ")
        #expect(electricalText.contains("Systems brief"))
        #expect(electricalText.contains("battery-endurance"))

        let systemsBrief = try #require(event.systemsBrief)
        #expect(systemsBrief.headline == "Systems brief")
        #expect(systemsBrief.sections.compactMap(\.title) == [
            "How to Brief the System",
            "Power Sources and Backup Paths",
            "Bus Failures and Night Capability Loss",
            "Battery Endurance and Recovery Priorities"
        ])

        let systemsText = systemsBrief.sections.flatMap { section in
            section.items.flatMap { [$0.text] + ($0.children?.map(\.text) ?? []) }
        }.joined(separator: " ")
        #expect(systemsText.contains("300-amp starter-generator"))
        #expect(systemsText.contains("42-amp-hour"))
        #expect(systemsText.contains("5-amp-hour"))
        #expect(systemsText.contains("30 minutes"))
    }

    @MainActor
    @Test func fam4701SplitsAerobaticManeuversWithoutLosingOCFLogic() throws {
        let manifest = try loadStudyManifestFromAppContent()
        let manifestEvents = manifestEventLookup(from: manifest)

        let event = try #require(manifestEvents["FAM4701"])
        #expect(event.title == "Aerobatics and OCF Recovery")
        #expect(!event.overview.lowercased().contains("this event ties together"))
        #expect(event.summary.lowercased().contains("aerobatic"))
        #expect(event.summary.lowercased().contains("ocf"))

        let notes = try #require(event.studyNotes)
        #expect(notes.sections.compactMap(\.title) == [
            "OCF Recovery Procedures",
            "Contact Unusual Attitudes",
            "Aileron Roll",
            "Loop",
            "Half Cuban Eight",
            "Immelmann",
            "Split-S",
            "Wingover",
            "Barrel Roll",
            "Combination Maneuver",
            "Inverted Flight",
            "Required Procedures"
        ])

        let ocfSection = try #require(notes.sections.first(where: { $0.title == "OCF Recovery Procedures" }))
        let ocfText = ocfSection.items.flatMap { [$0.text] + ($0.children?.map(\.text) ?? []) }.joined(separator: " ")
        #expect(ocfText.contains("120 to 135 KIAS"))
        #expect(ocfText.contains("controls physically neutral"))
        #expect(ocfText.contains("6000 feet AGL"))
        let ocfRecoveryItem = try #require(ocfSection.items.first(where: { $0.text == "Recovery:" }))
        let ocfRecoveryText = (ocfRecoveryItem.children ?? []).map(\.text).joined(separator: " ").lowercased()
        #expect(!ocfRecoveryText.contains("eject"))

        let uaSection = try #require(notes.sections.first(where: { $0.title == "Contact Unusual Attitudes" }))
        #expect(uaSection.items.contains(where: { $0.text == "Nose-High:" }))
        #expect(uaSection.items.contains(where: { $0.text == "Nose-Low:" }))
        #expect(uaSection.items.contains(where: { $0.text == "Inverted:" }))

        for title in ["Aileron Roll", "Loop", "Half Cuban Eight", "Immelmann", "Split-S", "Wingover", "Barrel Roll", "Combination Maneuver", "Inverted Flight"] {
            let section = try #require(notes.sections.first(where: { $0.title == title }))
            #expect(section.items.contains(where: { $0.text == "Entry setup:" }))
            #expect(section.items.contains(where: { $0.text == "Execution:" }))
            #expect(section.items.contains(where: { $0.text == "Maneuver complete when:" }))
        }

        let loopSection = try #require(notes.sections.first(where: { $0.title == "Loop" }))
        let loopText = loopSection.items.flatMap { [$0.text] + ($0.children?.map(\.text) ?? []) }.joined(separator: " ")
        #expect(loopText.contains("230 to 250 KIAS"))
        #expect(loopText.contains("4 G"))
        #expect(loopText.contains("180 KIAS"))

        let wingoverSection = try #require(notes.sections.first(where: { $0.title == "Wingover" }))
        let wingoverText = wingoverSection.items.flatMap { [$0.text] + ($0.children?.map(\.text) ?? []) }.joined(separator: " ")
        #expect(wingoverText.contains("70 percent PCL"))
        #expect(wingoverText.contains("45 degrees nose high"))
        #expect(wingoverText.contains("90 degrees of bank"))

        let invertedSection = try #require(notes.sections.first(where: { $0.title == "Inverted Flight" }))
        let invertedText = invertedSection.items.flatMap { [$0.text] + ($0.children?.map(\.text) ?? []) }.joined(separator: " ")
        #expect(invertedText.contains("60 seconds"))
        #expect(invertedText.contains("oil pressure"))

        let requiredSection = try #require(notes.sections.last)
        #expect(requiredSection.items.map(\.text) == [
            "OCF Recovery Procedures",
            "Contact Unusual Attitudes",
            "All Aerobatic Maneuvers"
        ])
    }

    @MainActor
    @Test func fam4702SeparatesSpinBranchesFromAcceleratedStallAndAOAWork() throws {
        let manifest = try loadStudyManifestFromAppContent()
        let manifestEvents = manifestEventLookup(from: manifest)

        let event = try #require(manifestEvents["FAM4702"])
        #expect(event.title == "Spins and AOA Approaches")
        #expect(!event.overview.lowercased().contains("this event ties together"))
        #expect(event.summary.lowercased().contains("spin"))
        #expect(event.summary.lowercased().contains("aoa"))

        let notes = try #require(event.studyNotes)
        #expect(notes.sections.compactMap(\.title) == [
            "Spin",
            "Inverted Spin",
            "Progressive Spin",
            "Accelerated Stall",
            "AOA Approach",
            "Required Procedures"
        ])

        let spinSection = try #require(notes.sections.first(where: { $0.title == "Spin" }))
        let spinText = spinSection.items.flatMap { [$0.text] + ($0.children?.map(\.text) ?? []) }.joined(separator: " ")
        #expect(spinText.contains("13,500 feet AGL") || spinText.contains("13,500"))
        #expect(spinText.contains("22,000 feet PA") || spinText.contains("22,000"))
        #expect(spinText.contains("10,000 feet PA") || spinText.contains("10,000"))
        #expect(spinText.contains("PCL to IDLE"))
        #expect(spinText.contains("full rudder"))
        #expect(spinText.contains("oil pressure"))

        let invertedSection = try #require(notes.sections.first(where: { $0.title == "Inverted Spin" }))
        let invertedText = invertedSection.items.flatMap { [$0.text] + ($0.children?.map(\.text) ?? []) }.joined(separator: " ")
        #expect(invertedText.contains("prohibited"))
        #expect(invertedText.contains("40 KIAS"))
        #expect(invertedText.contains("minus 1.5 G"))

        let progressiveSection = try #require(notes.sections.first(where: { $0.title == "Progressive Spin" }))
        let progressiveText = progressiveSection.items.flatMap { [$0.text] + ($0.children?.map(\.text) ?? []) }.joined(separator: " ")
        #expect(progressiveText.contains("reversing rudder"))
        #expect(progressiveText.contains("175 KIAS"))

        let acceleratedSection = try #require(notes.sections.first(where: { $0.title == "Accelerated Stall" }))
        let acceleratedText = acceleratedSection.items.flatMap { [$0.text] + ($0.children?.map(\.text) ?? []) }.joined(separator: " ")
        #expect(acceleratedText.contains("2 G"))
        #expect(acceleratedText.contains("90 degrees of bank"))
        #expect(acceleratedText.contains("Reduce AOA"))

        let aoaSection = try #require(notes.sections.first(where: { $0.title == "AOA Approach" }))
        let aoaText = aoaSection.items.flatMap { [$0.text] + ($0.children?.map(\.text) ?? []) }.joined(separator: " ")
        #expect(aoaText.contains("10.5 units"))
        #expect(aoaText.contains("15 to 20 percent"))
        #expect(aoaText.contains("25 to 30 percent"))
        #expect(aoaText.contains("450 feet AGL"))
        #expect(aoaText.contains("1200 to 1500 feet"))

        let requiredSection = try #require(notes.sections.last)
        #expect(requiredSection.items.map(\.text) == [
            "Spin",
            "Inverted Spin",
            "Progressive Spin",
            "Accelerated Stall",
            "AOA Approach"
        ])
    }

    @MainActor
    @Test func fam4703RebuildsFlightLoadsAndEmergencyReviewFromCleanSource() throws {
        let manifest = try loadStudyManifestFromAppContent()
        let manifestEvents = manifestEventLookup(from: manifest)

        let event = try #require(manifestEvents["FAM4703"])
        #expect(event.title == "Flight Loads and Emergency Review")
        #expect(!event.overview.lowercased().contains("this event ties together"))
        #expect(event.summary.lowercased().contains("vn"))
        #expect(event.summary.lowercased().contains("emergency"))

        let notes = try #require(event.studyNotes)
        #expect(notes.sections.compactMap(\.title) == [
            "T-6B Vn Diagram",
            "Maneuvering Speed",
            "Acceleration Limitations",
            "Any Emergency Procedure",
            "Required Procedures"
        ])

        let vnSection = try #require(notes.sections.first(where: { $0.title == "T-6B Vn Diagram" }))
        let vnText = vnSection.items.flatMap { [$0.text] + ($0.children?.map(\.text) ?? []) }.joined(separator: " ")
        #expect(!vnText.contains("Dates of issue"))
        #expect(!vnText.contains("Page No. Change No."))
        #expect(vnText.contains("200 KIAS"))
        #expect(vnText.contains("5 G"))

        let maneuveringSection = try #require(notes.sections.first(where: { $0.title == "Maneuvering Speed" }))
        let maneuveringText = maneuveringSection.items.flatMap { [$0.text] + ($0.children?.map(\.text) ?? []) }.joined(separator: " ")
        #expect(maneuveringText.contains("VO is 227 KIAS"))
        #expect(maneuveringText.contains("150 KIAS"))
        #expect(maneuveringText.contains("one axis"))

        let accelerationSection = try #require(notes.sections.first(where: { $0.title == "Acceleration Limitations" }))
        let accelerationText = accelerationSection.items.flatMap { [$0.text] + ($0.children?.map(\.text) ?? []) }.joined(separator: " ")
        #expect(accelerationText.contains("multi-axis"))
        #expect(accelerationText.contains("nose-low"))
        #expect(accelerationText.contains("Reduce AOA") == false)

        let epSection = try #require(notes.sections.first(where: { $0.title == "Any Emergency Procedure" }))
        let epText = epSection.items.flatMap { [$0.text] + ($0.children?.map(\.text) ?? []) }.joined(separator: " ")
        #expect(epText.contains("recognition cue"))
        #expect(epText.contains("PMU OFF Air-Start"))
        #expect(epText.contains("ejection"))

        let requiredSection = try #require(notes.sections.last)
        #expect(requiredSection.items.map(\.text) == [
            "T-6B Vn Diagram",
            "Maneuvering Speed",
            "Acceleration Limitations",
            "Any Emergency Procedure"
        ])
    }

    @MainActor
    @Test func fam6101GeneralizesCourseRulesAndArrivalReview() throws {
        let manifest = try loadStudyManifestFromAppContent()
        let manifestEvents = manifestEventLookup(from: manifest)

        let event = try #require(manifestEvents["FAM6101"])
        #expect(event.title == "Course Rules, OLF Operations, and Arrival Review")
        #expect(!event.overview.lowercased().contains("this event pulls together"))
        #expect(event.summary.lowercased().contains("course rules"))
        #expect(event.summary.lowercased().contains("sectional"))

        let notes = try #require(event.studyNotes)
        #expect(notes.sections.compactMap(\.title) == [
            "Local Course Rules",
            "OLF Arrival and Departure",
            "Home-Field Arrival",
            "Local VFR Sectional Review",
            "Required Procedures"
        ])

        let combinedText = notes.sections.flatMap { section in
            section.items.flatMap { [$0.text] + ($0.children?.map(\.text) ?? []) }
        }.joined(separator: " ").lowercased()
        for forbidden in ["waldron", "goliad", "aransas", "ingleside", "shamrock", "rusty", "camel humps", "berclair", "port royal", "kngp", "kngt", "krkp", "ktfp", "oso", "woodsboro"] {
            #expect(!combinedText.contains(forbidden))
        }

        let courseRulesSection = try #require(notes.sections.first(where: { $0.title == "Local Course Rules" }))
        let courseRulesText = courseRulesSection.items.flatMap { [$0.text] + ($0.children?.map(\.text) ?? []) }.joined(separator: " ")
        #expect(courseRulesText.contains("published procedure"))
        #expect(courseRulesText.contains("day-of brief"))

        let olfSection = try #require(notes.sections.first(where: { $0.title == "OLF Arrival and Departure" }))
        let olfText = olfSection.items.flatMap { [$0.text] + ($0.children?.map(\.text) ?? []) }.joined(separator: " ")
        #expect(olfText.contains("discontinued entry"))
        #expect(olfText.contains("number one"))

        let homeFieldSection = try #require(notes.sections.first(where: { $0.title == "Home-Field Arrival" }))
        let homeFieldText = homeFieldSection.items.flatMap { [$0.text] + ($0.children?.map(\.text) ?? []) }.joined(separator: " ")
        #expect(homeFieldText.contains("arrival gate"))
        #expect(homeFieldText.contains("direct recovery"))

        let sectionalSection = try #require(notes.sections.first(where: { $0.title == "Local VFR Sectional Review" }))
        let sectionalText = sectionalSection.items.flatMap { [$0.text] + ($0.children?.map(\.text) ?? []) }.joined(separator: " ")
        #expect(sectionalText.contains("MEF"))
        #expect(sectionalText.contains("special-use"))
    }

    @MainActor
    @Test func fam6102TurnsIntoRiskManagementAndVfrJudgmentReview() throws {
        let manifest = try loadStudyManifestFromAppContent()
        let manifestEvents = manifestEventLookup(from: manifest)

        let event = try #require(manifestEvents["FAM6102"])
        #expect(event.title == "Risk Management and VFR Judgment")
        #expect(!event.overview.lowercased().contains("this event pulls together"))
        #expect(event.summary.lowercased().contains("imsafe"))
        #expect(event.summary.lowercased().contains("cloud"))

        let notes = try #require(event.studyNotes)
        #expect(notes.sections.compactMap(\.title) == [
            "“IMSAFE” Checklist",
            "CRM",
            "See & Avoid Principle",
            "Cloud Clearances",
            "Local VFR Sectional Review",
            "Required Procedures"
        ])

        let combinedText = notes.sections.flatMap { section in
            section.items.flatMap { [$0.text] + ($0.children?.map(\.text) ?? []) }
        }.joined(separator: " ").lowercased()
        for forbidden in ["shamrock", "aransas", "waldron", "camel humps", "kngp", "krkp", "pt"] {
            #expect(!combinedText.contains(forbidden))
        }

        let imsafeSection = try #require(notes.sections.first(where: { $0.title == "“IMSAFE” Checklist" }))
        let imsafeText = imsafeSection.items.flatMap { [$0.text] + ($0.children?.map(\.text) ?? []) }.joined(separator: " ")
        #expect(imsafeText.contains("Illness"))
        #expect(imsafeText.contains("duty chain"))

        let crmSection = try #require(notes.sections.first(where: { $0.title == "CRM" }))
        let crmText = crmSection.items.flatMap { [$0.text] + ($0.children?.map(\.text) ?? []) }.joined(separator: " ")
        #expect(crmText.contains("Decision making"))
        #expect(crmText.contains("Assertiveness"))
        #expect(crmText.contains("Situational awareness"))

        let seeAvoidSection = try #require(notes.sections.first(where: { $0.title == "See & Avoid Principle" }))
        let seeAvoidText = seeAvoidSection.items.flatMap { [$0.text] + ($0.children?.map(\.text) ?? []) }.joined(separator: " ")
        #expect(seeAvoidText.contains("five miles"))
        #expect(seeAvoidText.contains("60 degrees"))
        #expect(seeAvoidText.contains("TCAS"))

        let cloudSection = try #require(notes.sections.first(where: { $0.title == "Cloud Clearances" }))
        let cloudText = cloudSection.items.flatMap { [$0.text] + ($0.children?.map(\.text) ?? []) }.joined(separator: " ")
        #expect(cloudText.contains("VFR weather minimums"))
        #expect(cloudText.contains("unit restrictions"))

        let sectionalSection = try #require(notes.sections.first(where: { $0.title == "Local VFR Sectional Review" }))
        let sectionalText = sectionalSection.items.flatMap { [$0.text] + ($0.children?.map(\.text) ?? []) }.joined(separator: " ")
        #expect(sectionalText.contains("sectional legend"))
        #expect(sectionalText.contains("MEF"))
        #expect(sectionalText.contains("divert"))
    }

    @MainActor
    @Test func fam6201TurnsIntoLowSpeedHandlingAndEnergyManagementReview() throws {
        let manifest = try loadStudyManifestFromAppContent()
        let manifestEvents = manifestEventLookup(from: manifest)

        let event = try #require(manifestEvents["FAM6201"])
        #expect(event.title == "Low-Speed Handling and Energy Management")
        #expect(!event.overview.lowercased().contains("this event pulls together"))
        #expect(event.summary.lowercased().contains("slow flight"))
        #expect(event.summary.lowercased().contains("slip"))

        let notes = try #require(event.studyNotes)
        #expect(notes.sections.compactMap(\.title) == [
            "Three Cs",
            "Slow Flight",
            "SCATSAFE Maneuver",
            "Energy Management",
            "Slip",
            "Required Procedures"
        ])

        let threeCsSection = try #require(notes.sections.first(where: { $0.title == "Three Cs" }))
        let threeCsText = threeCsSection.items.flatMap { [$0.text] + ($0.children?.map(\.text) ?? []) }.joined(separator: " ")
        #expect(threeCsText.contains("Pre-Stalling, Spinning, and Aerobatic Checklist"))
        #expect(threeCsText.contains("6000 feet AGL"))

        let slowFlightSection = try #require(notes.sections.first(where: { $0.title == "Slow Flight" }))
        let slowFlightText = slowFlightSection.items.flatMap { [$0.text] + ($0.children?.map(\.text) ?? []) }.joined(separator: " ")
        #expect(slowFlightText.contains("85 KIAS"))
        #expect(slowFlightText.contains("45 percent torque"))
        #expect(slowFlightText.contains("stick shaker"))

        let scatsafeSection = try #require(notes.sections.first(where: { $0.title == "SCATSAFE Maneuver" }))
        let scatsafeText = scatsafeSection.items.flatMap { [$0.text] + ($0.children?.map(\.text) ?? []) }.joined(separator: " ")
        #expect(scatsafeText.contains("80 KIAS"))
        #expect(scatsafeText.contains("15 units AOA"))
        #expect(scatsafeText.contains("adverse yaw"))

        let energySection = try #require(notes.sections.first(where: { $0.title == "Energy Management" }))
        let energyText = energySection.items.flatMap { [$0.text] + ($0.children?.map(\.text) ?? []) }.joined(separator: " ")
        #expect(energyText.contains("1000 feet"))
        #expect(energyText.contains("180 to 200 KIAS"))

        let slipSection = try #require(notes.sections.first(where: { $0.title == "Slip" }))
        let slipText = slipSection.items.flatMap { [$0.text] + ($0.children?.map(\.text) ?? []) }.joined(separator: " ")
        #expect(slipText.contains("125 KIAS"))
        #expect(slipText.contains("200 to 300 feet"))
        #expect(slipText.contains("low-fuel light"))
    }

    @MainActor
    @Test func fam6202TurnsIntoOutlyingPatternAndCrosswindReview() throws {
        let manifest = try loadStudyManifestFromAppContent()
        let manifestEvents = manifestEventLookup(from: manifest)

        let event = try #require(manifestEvents["FAM6202"])
        #expect(event.title == "Outlying Pattern Entries and Crosswind Operations")
        #expect(!event.overview.lowercased().contains("this event pulls together"))
        #expect(event.summary.lowercased().contains("crosswind"))
        #expect(event.summary.lowercased().contains("wave-off"))

        let notes = try #require(event.studyNotes)
        #expect(notes.sections.compactMap(\.title) == [
            "OLF Entry",
            "OLF/RDO Communication",
            "Crosswind Takeoff and Landings",
            "Wave-Off",
            "Required Procedures"
        ])

        let combinedText = notes.sections.flatMap { section in
            section.items.flatMap { [$0.text] + ($0.children?.map(\.text) ?? []) }
        }.joined(separator: " ").lowercased()
        for forbidden in ["goliad", "waldron", "aransas", "ingleside", "corpus", "shamrock", "shrimp ponds", "camel humps", "woodsboro", "berclair", "port royal", "kngt", "krkp", "ktfp", "kngp"] {
            #expect(!combinedText.contains(forbidden))
        }

        let olfEntrySection = try #require(notes.sections.first(where: { $0.title == "OLF Entry" }))
        let olfEntryText = olfEntrySection.items.flatMap { [$0.text] + ($0.children?.map(\.text) ?? []) }.joined(separator: " ")
        #expect(olfEntryText.contains("extended runway centerline"))
        #expect(olfEntryText.contains("two-way communications"))

        let communicationSection = try #require(notes.sections.first(where: { $0.title == "OLF/RDO Communication" }))
        let communicationText = communicationSection.items.flatMap { [$0.text] + ($0.children?.map(\.text) ?? []) }.joined(separator: " ")
        #expect(communicationText.contains("initial call"))
        #expect(communicationText.contains("wave-off"))

        let crosswindSection = try #require(notes.sections.first(where: { $0.title == "Crosswind Takeoff and Landings" }))
        let crosswindText = crosswindSection.items.flatMap { [$0.text] + ($0.children?.map(\.text) ?? []) }.joined(separator: " ")
        #expect(crosswindText.contains("wing-low"))
        #expect(crosswindText.contains("upwind main"))
        #expect(crosswindText.contains("do not level the wings"))

        let waveoffSection = try #require(notes.sections.first(where: { $0.title == "Wave-Off" }))
        let waveoffText = waveoffSection.items.flatMap { [$0.text] + ($0.children?.map(\.text) ?? []) }.joined(separator: " ")
        #expect(waveoffText.contains("120 KIAS"))
        #expect(waveoffText.contains("45 degrees of bank"))
        #expect(waveoffText.contains("Do not change your mind"))
    }

    @MainActor
    @Test func fam6203TurnsIntoDayBlockManeuverReview() throws {
        let manifest = try loadStudyManifestFromAppContent()
        let manifestEvents = manifestEventLookup(from: manifest)

        let event = try #require(manifestEvents["FAM6203"])
        #expect(event.title == "Day Block Maneuver Review")
        #expect(!event.overview.lowercased().contains("this event pulls together"))
        #expect(event.summary.lowercased().contains("block"))
        #expect(event.summary.lowercased().contains("energy"))

        let notes = try #require(event.studyNotes)
        #expect(notes.sections.compactMap(\.title) == [
            "Review Strategy",
            "Low-Speed Handling Review",
            "Pattern and Crosswind Review",
            "Energy and Recovery Review",
            "Required Procedures"
        ])

        let combinedText = notes.sections.flatMap { section in
            section.items.flatMap { [$0.text] + ($0.children?.map(\.text) ?? []) }
        }.joined(separator: " ").lowercased()
        for forbidden in ["goliad", "waldron", "aransas", "ingleside", "corpus", "rusty", "camel humps", "shrimp ponds"] {
            #expect(!combinedText.contains(forbidden))
        }

        let lowSpeedSection = try #require(notes.sections.first(where: { $0.title == "Low-Speed Handling Review" }))
        let lowSpeedText = lowSpeedSection.items.flatMap { [$0.text] + ($0.children?.map(\.text) ?? []) }.joined(separator: " ")
        #expect(lowSpeedText.contains("Three Cs"))
        #expect(lowSpeedText.contains("SCATSAFE"))
        #expect(lowSpeedText.contains("Slip"))

        let patternSection = try #require(notes.sections.first(where: { $0.title == "Pattern and Crosswind Review" }))
        let patternText = patternSection.items.flatMap { [$0.text] + ($0.children?.map(\.text) ?? []) }.joined(separator: " ")
        #expect(patternText.contains("two-way communications"))
        #expect(patternText.contains("Wave-off"))

        let energySection = try #require(notes.sections.first(where: { $0.title == "Energy and Recovery Review" }))
        let energyText = energySection.items.flatMap { [$0.text] + ($0.children?.map(\.text) ?? []) }.joined(separator: " ")
        #expect(energyText.contains("trim"))
        #expect(energyText.contains("reset"))
    }

    @MainActor
    @Test func submittingAndDismissingReportUpdatesOpenReports() async throws {
        let repository = MockInstructorReviewRepository()

        try repository.submitReport(
            InstructorGougeReportSubmission(
                targetKind: .instructor,
                instructorID: "inst-1",
                reviewID: nil,
                instructorName: "Garrecht, Alex",
                squadron: Squadron(id: "tw-4", displayName: "TW-4"),
                eventName: nil,
                eventKind: nil,
                reviewText: nil,
                reasonTitle: InstructorInfoReportReason.incorrectName.title,
                note: "Name formatting looks wrong."
            )
        )

        #expect(repository.fetchOpenReports().count == 1)
        #expect(repository.fetchOpenReports().first?.reasonTitle == "Incorrect Name")

        if let reportID = repository.fetchOpenReports().first?.id {
            try await repository.dismissReport(id: reportID)
        }

        #expect(repository.fetchOpenReports().isEmpty)
    }

    @MainActor
    @Test func rejectingReportedReviewClearsLinkedReports() async throws {
        let repository = MockInstructorReviewRepository()

        try repository.submitReport(
            InstructorGougeReportSubmission(
                targetKind: .review,
                instructorID: "inst-1",
                reviewID: "review-1",
                instructorName: "Garrecht, Alex",
                squadron: Squadron(id: "tw-4", displayName: "TW-4"),
                eventName: "C3101",
                eventKind: .sim,
                reviewText: "Bad review text",
                reasonTitle: "Review Report",
                note: "This should be rejected."
            )
        )

        #expect(repository.fetchOpenReports().count == 1)

        try await repository.rejectReview(id: "review-1")

        #expect(repository.fetchOpenReports().isEmpty)
    }

    @MainActor
    @Test func reviewReportsUseGenericReasonAndStoreRequiredComment() async throws {
        let repository = MockInstructorReviewRepository()

        try repository.submitReport(
            InstructorGougeReportSubmission(
                targetKind: .review,
                instructorID: "inst-2",
                reviewID: "review-2",
                instructorName: "Abordo",
                squadron: Squadron(id: "vt-27", displayName: "VT-27"),
                eventName: "I4201/4202",
                eventKind: .flight,
                reviewText: "Questionable details",
                reasonTitle: "Review Report",
                note: "This review needs another look."
            )
        )

        #expect(repository.fetchOpenReports().first?.reasonTitle == "Review Report")
        #expect(repository.fetchOpenReports().first?.note == "This review needs another look.")
    }

    @MainActor
    @Test func localRepositoryPromotesQueuedSubmissionIntoPublishedReviewAfterSync() async throws {
        let tempURL = FileManager.default.temporaryDirectory.appendingPathComponent("instructor-reviews-\(UUID().uuidString).json")
        let repository = LocalInstructorReviewRepository(persistenceURL: tempURL)
        let squadron = Squadron(id: "vt-27", displayName: "VT-27")
        let event = InstructorReviewEvent(id: "fam2101", displayName: "FAM2101", kind: .flight, syllabusCategory: .familiarization)

        try repository.enqueueReviewSubmission(
            InstructorReviewSubmission(
                instructorName: "Offline Pilot",
                squadron: squadron,
                event: event,
                chillScore: 5,
                gradingScore: 4,
                reviewText: String(repeating: "Great ", count: 12)
            ),
            clientID: "client-1"
        )

        let queued = repository.fetchQueuedReviewUploads()
        #expect(queued.count == 1)
        #expect(queued.first?.syncState == .queuedUpload)

        if let queuedID = queued.first?.id {
            repository.markReviewUploaded(localID: queuedID, remoteID: queuedID, syncedAt: .now)
            repository.applySubmissionStatuses(
                [RemoteSubmissionStatusSnapshot(id: queuedID, status: .approved, updatedAt: .now)],
                syncedAt: .now
            )
            repository.upsertPublishedReviews(
                [
                    InstructorReviewRecord(
                        id: queuedID,
                        remoteID: queuedID,
                        instructorName: "Offline Pilot",
                        squadronID: "vt-27",
                        eventName: "FAM2101",
                        eventKind: .flight,
                        chillScore: 5,
                        gradingScore: 4,
                        reviewText: String(repeating: "Great ", count: 12),
                        submittedAt: .now,
                        status: .approved,
                        origin: .remote,
                        syncState: .synced,
                        lastModifiedAt: .now,
                        lastSyncedAt: .now,
                        submitterClientID: "client-1"
                    )
                ],
                syncedAt: .now
            )
        }

        #expect(repository.fetchPendingReviews().isEmpty)
        #expect(repository.fetchInstructorSummaries(searchText: "Offline").first?.publishedReviewCount == 1)
    }

    @MainActor
    @Test func localRepositoryResolvesOpenReportsWhenRemoteStatusClosesThem() async throws {
        let tempURL = FileManager.default.temporaryDirectory.appendingPathComponent("instructor-reports-\(UUID().uuidString).json")
        let repository = LocalInstructorReviewRepository(persistenceURL: tempURL)

        try repository.enqueueReport(
            InstructorGougeReportSubmission(
                targetKind: .review,
                instructorID: "inst-1",
                reviewID: "review-1",
                instructorName: "Garrecht, Alex",
                squadron: Squadron(id: "tw-4", displayName: "TW-4"),
                eventName: "C3101",
                eventKind: .sim,
                reviewText: "Needs moderation",
                reasonTitle: "Review Report",
                note: "Contains details that should be reviewed."
            ),
            clientID: "client-1"
        )

        let queued = repository.fetchQueuedReportUploads()
        #expect(queued.count == 1)

        if let queuedID = queued.first?.id {
            repository.markReportUploaded(localID: queuedID, remoteID: queuedID, syncedAt: .now)
            repository.applyReportStatuses(
                [RemoteReportStatusSnapshot(id: queuedID, status: .resolved, updatedAt: .now)],
                syncedAt: .now
            )
        }

        #expect(repository.fetchOpenReports().isEmpty)
    }

    @MainActor
    private func loadStudyManifestFromAppContent() throws -> StudyManifest {
        let url = appContentRoot().appendingPathComponent("StudyManifest.json")
        let data = try Data(contentsOf: url)
        return try JSONDecoder().decode(StudyManifest.self, from: data)
    }

    @MainActor
    private func loadSyllabusReferenceFromAppContent() throws -> SyllabusEventReference {
        let url = appContentRoot().appendingPathComponent("SyllabusEventReference.json")
        let data = try Data(contentsOf: url)
        let decoder = JSONDecoder()
        decoder.dateDecodingStrategy = .iso8601
        return try decoder.decode(SyllabusEventReference.self, from: data)
    }

    @MainActor
    private func loadSyllabusAuditReportFromAppContent() throws -> [String: Any] {
        let url = appContentRoot().appendingPathComponent("SyllabusEventAuditReport.json")
        let data = try Data(contentsOf: url)
        let object = try JSONSerialization.jsonObject(with: data)
        return try #require(object as? [String: Any])
    }

    private func appContentRoot() -> URL {
        URL(fileURLWithPath: #filePath)
            .deletingLastPathComponent()
            .deletingLastPathComponent()
            .appendingPathComponent("Primary Gouge/AppContent", isDirectory: true)
    }

    private func manifestEventLookup(from manifest: StudyManifest) -> [String: Event] {
        Dictionary(
            uniqueKeysWithValues: manifest.phases
                .flatMap(\.categories)
                .flatMap(\.events)
                .map { ($0.code, $0) }
        )
    }

    private func normalizedAuditText(_ value: String) -> String {
        value
            .folding(options: [.diacriticInsensitive, .caseInsensitive], locale: .current)
            .replacingOccurrences(of: "[^a-z0-9]+", with: " ", options: .regularExpression)
            .trimmingCharacters(in: .whitespacesAndNewlines)
            .lowercased()
    }
}

@MainActor
private final class MockInstructorReviewRepository: InstructorReviewRepository {
    let squadrons: [Squadron] = [
        Squadron(id: "vt-2", displayName: "VT-2"),
        Squadron(id: "vt-3", displayName: "VT-3"),
        Squadron(id: "vt-6", displayName: "VT-6"),
        Squadron(id: "tw-4", displayName: "TW-4"),
        Squadron(id: "tw-5", displayName: "TW-5"),
        Squadron(id: "vt-27", displayName: "VT-27"),
        Squadron(id: "vt-28", displayName: "VT-28")
    ]

    let events: [InstructorReviewEvent] = [
        InstructorReviewEvent(id: "c3101", displayName: "C3101", kind: .sim, syllabusCategory: .capstone),
        InstructorReviewEvent(id: "fam2101", displayName: "FAM2101", kind: .flight, syllabusCategory: .familiarization),
        InstructorReviewEvent(id: "fam2102", displayName: "FAM2102", kind: .flight, syllabusCategory: .familiarization)
    ]

    let suggestions: [InstructorNameSuggestion] = [
        InstructorNameSuggestion(id: "sim-instructor", name: "Sim Instructor", squadron: Squadron(id: "tw-4", displayName: "TW-4")),
        InstructorNameSuggestion(id: "flight-instructor", name: "Flight Instructor", squadron: Squadron(id: "vt-27", displayName: "VT-27")),
        InstructorNameSuggestion(id: "garrecht-alex", name: "Garrecht, Alex", squadron: Squadron(id: "tw-4", displayName: "TW-4"))
    ]

    private(set) var lastSubmittedReview: InstructorReviewSubmission?
    private var openReports: [InstructorGougeReport] = []

    func seedIfNeeded() throws {}
    func fetchInstructorSummaries(searchText: String) -> [Instructor] { [] }
    func fetchInstructor(id: String) -> Instructor? { nil }
    func fetchPublishedReviews(for instructorID: String) -> [InstructorReview] { [] }
    func fetchPendingReviews() -> [InstructorReview] { [] }
    func fetchOpenReports() -> [InstructorGougeReport] { openReports }

    func fetchInstructorSuggestions(matching query: String) -> [InstructorNameSuggestion] {
        let trimmedQuery = query.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !trimmedQuery.isEmpty else { return suggestions }

        let normalizedQuery = normalized(trimmedQuery)
        let queryTokens = normalizedTokens(trimmedQuery)
        return suggestions.filter {
            normalized($0.name).contains(normalizedQuery) || normalizedTokens($0.name) == queryTokens
        }
    }

    func fetchSquadrons() -> [Squadron] { squadrons.submissionSorted() }
    func fetchEvents() -> [InstructorReviewEvent] { events }
    func submitReview(_ submission: InstructorReviewSubmission) throws { lastSubmittedReview = submission }
    func submitReport(_ submission: InstructorGougeReportSubmission) throws {
        openReports.append(
            InstructorGougeReport(
                id: UUID().uuidString,
                targetKind: submission.targetKind,
                instructorID: submission.instructorID,
                reviewID: submission.reviewID,
                instructorName: submission.instructorName,
                squadron: submission.squadron,
                eventName: submission.eventName,
                eventKind: submission.eventKind,
                reviewText: submission.reviewText,
                reasonTitle: submission.reasonTitle,
                note: submission.note,
                submittedAt: .now,
                status: .open,
                origin: .localSubmission,
                syncState: .localOnly,
                submitterClientID: nil
            )
        )
    }
    func dismissReport(id: String) async throws {
        openReports.removeAll { $0.id == id }
    }
    func approveReview(id: String) async throws {}
    func rejectReview(id: String) async throws {
        openReports.removeAll { $0.reviewID == id }
    }

    private func normalized(_ value: String) -> String {
        value
            .trimmingCharacters(in: .whitespacesAndNewlines)
            .folding(options: [.diacriticInsensitive, .caseInsensitive], locale: .current)
            .lowercased()
    }

    private func normalizedTokens(_ value: String) -> [String] {
        value
            .folding(options: [.diacriticInsensitive, .caseInsensitive], locale: .current)
            .components(separatedBy: CharacterSet.alphanumerics.inverted)
            .filter { !$0.isEmpty }
            .map { $0.lowercased() }
            .sorted()
    }
}
