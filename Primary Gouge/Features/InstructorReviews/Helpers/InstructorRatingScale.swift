import Foundation
import SwiftUI

enum InstructorRatingCategory: String, Hashable {
    case chillFactor
    case gradingStyle

    var displayName: String {
        switch self {
        case .chillFactor:
            return "Chill Factor"
        case .gradingStyle:
            return "Grading Style"
        }
    }
}

enum InstructorRatingColorToken: String, CaseIterable, Hashable {
    case critical
    case danger
    case warning
    case balanced
    case encouraging
    case success
    case elite

    var color: Color {
        switch self {
        case .critical:
            return AppTheme.color(0xD93A2F)
        case .danger:
            return AppTheme.color(0xE46B2E)
        case .warning:
            return AppTheme.color(0xD59A2A)
        case .balanced:
            return AppTheme.color(0xA69C3D)
        case .encouraging:
            return AppTheme.color(0x78BF58)
        case .success:
            return AppTheme.color(0x3FAE4C)
        case .elite:
            return AppTheme.color(0x1D8F3E)
        }
    }
}

enum InstructorRatingScale {
    static let validScores = 1...7

    static func label(for score: Int, category: InstructorRatingCategory) -> String {
        let score = clamped(score)

        switch category {
        case .chillFactor:
            switch score {
            case 7: return "Chillmaster"
            case 6: return "Super Chill"
            case 5: return "Pretty Chill"
            case 4: return "Neutral"
            case 3: return "Serious"
            case 2: return "Intense"
            default: return "Nightmare Fuel"
            }
        case .gradingStyle:
            switch score {
            case 7: return "Santa Claus"
            case 6: return "Easy Grader"
            case 5: return "Generous but Fair"
            case 4: return "Fair"
            case 3: return "Tough but Fair"
            case 2: return "Harsh"
            default: return "MIF Monster"
            }
        }
    }

    static func colorToken(for score: Int) -> InstructorRatingColorToken {
        switch clamped(score) {
        case 7:
            return .elite
        case 6:
            return .success
        case 5:
            return .encouraging
        case 4:
            return .balanced
        case 3:
            return .warning
        case 2:
            return .danger
        default:
            return .critical
        }
    }

    static func color(for score: Int) -> Color {
        colorToken(for: score).color
    }

    static func roundedScore(for average: Double) -> Int {
        clamped(Int(average.rounded()))
    }

    static func label(forAverage average: Double, category: InstructorRatingCategory) -> String {
        label(for: roundedScore(for: average), category: category)
    }

    static func format(average: Double) -> String {
        String(format: "%.1f", average)
    }

    static func formatOutOfSeven(average: Double, includeAverageSuffix: Bool = false) -> String {
        let base = "\(format(average: average))/7"
        return includeAverageSuffix ? "\(base) avg" : base
    }

    static func formatOutOfSeven(score: Int) -> String {
        "\(clamped(score))/7"
    }

    static func formatSpacedOutOfSeven(score: Int, includeAverageSuffix: Bool = false) -> String {
        let base = "\(clamped(score)) / 7"
        return includeAverageSuffix ? "\(base) avg" : base
    }

    static func clamped(_ score: Int) -> Int {
        min(max(score, validScores.lowerBound), validScores.upperBound)
    }
}

extension Instructor {
    var chillRoundedScore: Int {
        InstructorRatingScale.roundedScore(for: averageChillScore)
    }

    var gradingRoundedScore: Int {
        InstructorRatingScale.roundedScore(for: averageGradingScore)
    }

    var chillLabel: String {
        InstructorRatingScale.label(for: chillRoundedScore, category: .chillFactor)
    }

    var gradingLabel: String {
        InstructorRatingScale.label(for: gradingRoundedScore, category: .gradingStyle)
    }

    var chillAverageText: String {
        InstructorRatingScale.format(average: averageChillScore)
    }

    var gradingAverageText: String {
        InstructorRatingScale.format(average: averageGradingScore)
    }

    var chillAverageOutOfSevenText: String {
        InstructorRatingScale.formatOutOfSeven(average: averageChillScore, includeAverageSuffix: true)
    }

    var gradingAverageOutOfSevenText: String {
        InstructorRatingScale.formatOutOfSeven(average: averageGradingScore, includeAverageSuffix: true)
    }
}
