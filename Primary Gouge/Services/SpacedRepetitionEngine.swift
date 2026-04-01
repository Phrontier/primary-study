import Foundation

enum SpacedRepetitionEngine {
    static func nextState(from snapshot: CardProgressSnapshot, rating: FlashcardRating, now: Date) -> CardProgressSnapshot {
        let currentMastery = snapshot.mastery
        let currentStability = max(0.2, snapshot.stability)

        let masteryDelta: Double
        let stabilityMultiplier: Double

        switch rating {
        case .missed:
            masteryDelta = -0.24
            stabilityMultiplier = 0.5
        case .hard:
            masteryDelta = -0.04
            stabilityMultiplier = 1.15
        case .good:
            masteryDelta = 0.10
            stabilityMultiplier = 1.7
        case .easy:
            masteryDelta = 0.18
            stabilityMultiplier = 2.35
        }

        let mastery = max(0, min(1, currentMastery + masteryDelta))
        let stability = max(0.2, currentStability * stabilityMultiplier)
        let intervalHours = intervalHours(mastery: mastery, stability: stability, rating: rating)
        let nextReviewAt = Calendar.current.date(byAdding: .hour, value: Int(intervalHours.rounded()), to: now)

        return CardProgressSnapshot(
            mastery: mastery,
            stability: stability,
            nextReviewAt: nextReviewAt,
            lastReviewedAt: now
        )
    }

    private static func intervalHours(mastery: Double, stability: Double, rating: FlashcardRating) -> Double {
        let base: Double
        switch rating {
        case .missed: base = 6
        case .hard: base = 16
        case .good: base = 36
        case .easy: base = 60
        }

        return min(24 * 45, base * (1 + mastery) * stability)
    }
}
