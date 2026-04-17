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
    @Test func instructorRatingScaleFormatsOutOfSevenStrings() async throws {
        #expect(InstructorRatingScale.formatOutOfSeven(score: 5) == "5/7")
        #expect(InstructorRatingScale.formatOutOfSeven(average: 5.5) == "5.5/7")
        #expect(InstructorRatingScale.formatOutOfSeven(average: 5.5, includeAverageSuffix: true) == "5.5/7 avg")
        #expect(InstructorRatingScale.label(for: 5, category: .gradingStyle) == "Good but Fair")
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
            try repository.dismissReport(id: reportID)
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

        try repository.rejectReview(id: "review-1")

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
        InstructorReviewEvent(id: "c3101", displayName: "C3101", kind: .sim),
        InstructorReviewEvent(id: "fam2101", displayName: "FAM2101", kind: .flight),
        InstructorReviewEvent(id: "fam2102", displayName: "FAM2102", kind: .flight)
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
                submittedAt: .now
            )
        )
    }
    func dismissReport(id: String) throws {
        openReports.removeAll { $0.id == id }
    }
    func approveReview(id: String) throws {}
    func rejectReview(id: String) throws {
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
