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
    }

    @MainActor
    @Test func submissionModeFiltersSquadronsEventsAndSuggestions() async throws {
        let repository = MockInstructorReviewRepository()
        let viewModel = ReviewSubmissionViewModel()

        viewModel.instructorName = "instructor"
        viewModel.load(using: repository)

        #expect(viewModel.visibleSquadrons.map(\.displayName) == ["TW-4", "TW-5", "VT-27", "VT-28"])
        #expect(viewModel.visibleEvents.map(\.displayName) == ["C3101", "FAM"])
        #expect(viewModel.suggestions.map(\.name) == ["Sim Instructor", "Flight Instructor"])

        viewModel.submissionMode = .sims

        #expect(viewModel.visibleSquadrons.map(\.displayName) == ["TW-4", "TW-5"])
        #expect(viewModel.visibleEvents.map(\.displayName) == ["C3101"])
        #expect(viewModel.suggestions.map(\.name) == ["Sim Instructor"])

        viewModel.submissionMode = .flights

        #expect(viewModel.visibleSquadrons.map(\.displayName) == ["VT-27", "VT-28"])
        #expect(viewModel.visibleEvents.map(\.displayName) == ["FAM"])
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
}

@MainActor
private final class MockInstructorReviewRepository: InstructorReviewRepository {
    let squadrons: [Squadron] = [
        Squadron(id: "tw-4", displayName: "TW-4"),
        Squadron(id: "tw-5", displayName: "TW-5"),
        Squadron(id: "vt-27", displayName: "VT-27"),
        Squadron(id: "vt-28", displayName: "VT-28")
    ]

    let events: [InstructorReviewEvent] = [
        InstructorReviewEvent(id: "c3101", displayName: "C3101", kind: .sim),
        InstructorReviewEvent(id: "fam", displayName: "FAM", kind: .flight)
    ]

    let suggestions: [InstructorNameSuggestion] = [
        InstructorNameSuggestion(id: "sim-instructor", name: "Sim Instructor", squadron: Squadron(id: "tw-4", displayName: "TW-4")),
        InstructorNameSuggestion(id: "flight-instructor", name: "Flight Instructor", squadron: Squadron(id: "vt-27", displayName: "VT-27"))
    ]

    func seedIfNeeded() throws {}
    func fetchInstructorSummaries(searchText: String) -> [Instructor] { [] }
    func fetchInstructor(id: String) -> Instructor? { nil }
    func fetchPublishedReviews(for instructorID: String) -> [InstructorReview] { [] }
    func fetchPendingReviews() -> [InstructorReview] { [] }

    func fetchInstructorSuggestions(matching query: String) -> [InstructorNameSuggestion] {
        suggestions.filter {
            query.isEmpty || $0.name.localizedCaseInsensitiveContains(query)
        }
    }

    func fetchSquadrons() -> [Squadron] { squadrons }
    func fetchEvents() -> [InstructorReviewEvent] { events }
    func submitReview(_ submission: InstructorReviewSubmission) throws {}
    func approveReview(id: String) throws {}
    func rejectReview(id: String) throws {}
}
