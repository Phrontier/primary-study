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
        #expect(InstructorRatingScale.formatSpacedOutOfSeven(score: 5) == "5 / 7")
        #expect(InstructorRatingScale.formatSpacedOutOfSeven(score: 5, includeAverageSuffix: true) == "5 / 7 avg")
    }
}
