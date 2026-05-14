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
    @Test func everyFamSyllabusEventHasAuthoredNotesAndExactRequiredProcedures() throws {
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
            #expect(requiredSection.items.map(\.text) == famEvent.discussionItems)
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
    @Test func famCheckFlightAndSoloEventsHaveAuthoredNotes() throws {
        let manifest = try loadStudyManifestFromAppContent()
        let manifestEvents = manifestEventLookup(from: manifest)

        for code in ["FAM4490", "FAM4501"] {
            let event = try #require(manifestEvents[code])
            let notes = try #require(event.studyNotes)
            #expect(!notes.sections.isEmpty)
        }
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
