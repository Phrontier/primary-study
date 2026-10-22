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
            return StudyDesign.color(0xB13748, 0xFF968E)
        case .danger:
            return StudyDesign.color(0xB75925, 0xFFB181)
        case .warning:
            return StudyDesign.color(0x916014, 0xF0CA79)
        case .balanced:
            return StudyDesign.color(0x766526, 0xDDD38B)
        case .encouraging:
            return StudyDesign.color(0x4F7939, 0xB9DC8D)
        case .success:
            return StudyDesign.color(0x2F7E42, 0x8DDD9A)
        case .elite:
            return StudyDesign.color(0x236744, 0x77D7A5)
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
            default: return "Hammer"
            }
        case .gradingStyle:
            switch score {
            case 7: return "Santa Claus"
            case 6: return "Easy Grader"
            case 5: return "Good but Fair"
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

    static func tenScaleValue(for rawValue: Double) -> Double {
        let clampedValue = min(max(rawValue, 0), Double(validScores.upperBound))
        return clampedValue / Double(validScores.upperBound) * 10
    }

    static func formatOutOfTen(average: Double, includeAverageSuffix: Bool = false) -> String {
        let base = "\(format(average: tenScaleValue(for: average)))/10"
        return includeAverageSuffix ? "\(base) avg" : base
    }

    static func formatOutOfTen(score: Int) -> String {
        "\(format(average: tenScaleValue(for: Double(clamped(score)))))/10"
    }

    static func formatSpacedOutOfTen(score: Int, includeAverageSuffix: Bool = false) -> String {
        let base = "\(format(average: tenScaleValue(for: Double(clamped(score))))) / 10"
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

    var chillAverageOutOfTenText: String {
        InstructorRatingScale.formatOutOfTen(average: averageChillScore, includeAverageSuffix: true)
    }

    var gradingAverageOutOfTenText: String {
        InstructorRatingScale.formatOutOfTen(average: averageGradingScore, includeAverageSuffix: true)
    }
}
