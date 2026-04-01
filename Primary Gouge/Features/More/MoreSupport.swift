import Foundation

struct MoreHubSnapshot {
    let avatarInitials: String
    let identityTitle: String
    let currentFocusLine: String
    let quizSubtitle: String
    let flashcardStatsSubtitle: String
    let flashcardStudiedCount: Int
    let flashcardDueCount: Int
    let recentQuizCount: Int
    let savedBriefsSubtitle: String
    let recentBriefCount: Int
    let savedFlashcardSetsSubtitle: String
    let recentDeckCount: Int
    let versionSubtitle: String
}

extension StudyAppModel {
    var moreHubSnapshot: MoreHubSnapshot {
        let identityTitle = "Primary Gouge"
        let recentActivities = progressStore?.recentActivities() ?? []
        let preferences = progressStore?.homePreferences() ?? HomePreferencesRecord()
        let cardRecords = progressStore?.allCardProgressRecords() ?? []
        let recentQuizCount = quizStore?.history().count ?? 0
        let studiedCardCount = cardRecords.filter { $0.lastReviewedAt != nil }.count
        let dueCardCount = cardRecords.filter { progress(for: $0.cardID).isDue }.count

        let recentBriefCount = Set(recentActivities.compactMap { activity -> String? in
            guard case let .sharedResource(id) = activity.destination else { return nil }
            return id
        }).count

        let recentDeckCount = Set(recentActivities.compactMap { activity -> String? in
            switch activity.destination {
            case let .eventDeck(_, _, deckID):
                return deckID
            case let .libraryDeck(id):
                return id
            default:
                return nil
            }
        }).count

        let currentFocusLine = moreCurrentFocusLine(recentActivities: recentActivities, preferences: preferences)

        let quizSubtitle: String
        if recentQuizCount > 0 {
            quizSubtitle = "\(recentQuizCount) recent \(recentQuizCount == 1 ? "session" : "sessions")"
        } else {
            quizSubtitle = "Objective testing and missed-question review"
        }

        let flashcardStatsSubtitle: String
        if studiedCardCount > 0 {
            flashcardStatsSubtitle = "\(studiedCardCount) cards studied • \(dueCardCount) due now"
        } else if recentQuizCount > 0 {
            flashcardStatsSubtitle = "\(recentQuizCount) quiz \(recentQuizCount == 1 ? "session" : "sessions") logged"
        } else {
            flashcardStatsSubtitle = "Track card mastery and quiz trends"
        }

        let savedBriefsSubtitle: String
        if recentBriefCount > 0 {
            savedBriefsSubtitle = "\(recentBriefCount) recent \(recentBriefCount == 1 ? "reference" : "references")"
        } else {
            savedBriefsSubtitle = "Keep high-use references close"
        }

        let savedFlashcardSetsSubtitle: String
        if recentDeckCount > 0 {
            savedFlashcardSetsSubtitle = "\(recentDeckCount) recent \(recentDeckCount == 1 ? "deck" : "decks")"
        } else {
            savedFlashcardSetsSubtitle = "Keep high-use decks close"
        }

        return MoreHubSnapshot(
            avatarInitials: MoreHubSnapshot.initials(from: identityTitle),
            identityTitle: identityTitle,
            currentFocusLine: currentFocusLine,
            quizSubtitle: quizSubtitle,
            flashcardStatsSubtitle: flashcardStatsSubtitle,
            flashcardStudiedCount: studiedCardCount,
            flashcardDueCount: dueCardCount,
            recentQuizCount: recentQuizCount,
            savedBriefsSubtitle: savedBriefsSubtitle,
            recentBriefCount: recentBriefCount,
            savedFlashcardSetsSubtitle: savedFlashcardSetsSubtitle,
            recentDeckCount: recentDeckCount,
            versionSubtitle: MoreHubSnapshot.versionString()
        )
    }

    private func moreCurrentFocusLine(
        recentActivities: [StudyActivityRecord],
        preferences: HomePreferencesRecord
    ) -> String {
        if let phaseTitle = moreRecentStageTitle(from: recentActivities) {
            return "Current focus: \(phaseTitle)"
        }

        let pinnedTopics = preferences.pinnedTopicIDs
            .compactMap { topicID in
                studyTopics.first(where: { $0.id == topicID })?.shortTitle
            }

        if !pinnedTopics.isEmpty {
            return "Pinned: \(pinnedTopics.prefix(3).joined(separator: ", "))"
        }

        return "Primary study setup"
    }

    private func moreRecentStageTitle(from activities: [StudyActivityRecord]) -> String? {
        for activity in activities {
            switch activity.destination {
            case let .event(phaseID, _), let .eventDeck(phaseID, _, _):
                if let phase = phase(id: phaseID) {
                    return phase.title
                }
            case let .sharedResource(id):
                if let resource = sharedResource(id: id),
                   let phaseID = resource.phaseIDs.first,
                   let phase = phase(id: phaseID) {
                    return phase.title
                }
            case .libraryDeck:
                return "General Library"
            case .video, .questionOfDay:
                continue
            }
        }

        return nil
    }
}

private extension MoreHubSnapshot {
    static func initials(from title: String) -> String {
        let parts = title
            .split(separator: " ")
            .prefix(2)

        let letters = parts.compactMap { $0.first?.uppercased() }
        return letters.isEmpty ? "PG" : letters.joined()
    }

    static func versionString(bundle: Bundle = .main) -> String {
        let marketingVersion = bundle.object(forInfoDictionaryKey: "CFBundleShortVersionString") as? String
        let buildNumber = bundle.object(forInfoDictionaryKey: "CFBundleVersion") as? String

        switch (marketingVersion, buildNumber) {
        case let (version?, build?) where version != build:
            return "Version \(version) (\(build))"
        case let (version?, _):
            return "Version \(version)"
        case let (_, build?):
            return "Build \(build)"
        default:
            return "Version unavailable"
        }
    }
}
