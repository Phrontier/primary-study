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
    let recentBriefsSubtitle: String
    let recentBriefCount: Int
    let recentFlashcardSetsSubtitle: String
    let recentDeckCount: Int
    let versionSubtitle: String
    let stats: MoreStatsSnapshot
    let recentBriefs: [MoreRecentBriefItem]
    let recentDecks: [MoreRecentDeckItem]
}

struct MoreStatsSnapshot {
    let studiedCardCount: Int
    let dueCardCount: Int
    let quizSessionCount: Int
    let averageQuizScore: Int?
    let weakAreaSignals: [QuizWeakAreaSignal]

    var hasContent: Bool {
        studiedCardCount > 0 || dueCardCount > 0 || quizSessionCount > 0
    }
}

struct MoreRecentBriefItem: Identifiable, Hashable {
    let id: String
    let resourceID: String
    let title: String
    let context: String
    let summary: String
    let lastOpenedAt: Date
}

enum MoreRecentDeckDestination: Hashable {
    case eventDeck(phaseID: String, eventID: String, deckID: String)
    case libraryDeck(id: String)
}

struct MoreRecentDeckItem: Identifiable, Hashable {
    let id: String
    let deckTitle: String
    let context: String
    let summary: String
    let lastOpenedAt: Date
    let destination: MoreRecentDeckDestination
}

extension StudyAppModel {
    var moreHubSnapshot: MoreHubSnapshot {
        let identityTitle = "Primary Gouge"
        let recentActivities = progressStore?.recentActivities() ?? []
        let preferences = progressStore?.homePreferences() ?? HomePreferencesRecord()
        let cardRecords = progressStore?.allCardProgressRecords() ?? []
        let quizHistory = quizStore?.history() ?? []
        let studiedCardCount = cardRecords.filter { $0.lastReviewedAt != nil }.count
        let dueCardCount = cardRecords.filter { progress(for: $0.cardID).isDue }.count
        let recentBriefs = moreRecentBriefItems(from: recentActivities)
        let recentDecks = moreRecentDeckItems(from: recentActivities)
        let currentFocusLine = moreCurrentFocusLine(recentActivities: recentActivities, preferences: preferences)
        let recentQuizCount = quizHistory.count

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

        let recentBriefsSubtitle: String
        if !recentBriefs.isEmpty {
            recentBriefsSubtitle = "\(recentBriefs.count) recent \(recentBriefs.count == 1 ? "brief" : "briefs")"
        } else {
            recentBriefsSubtitle = "Your recently opened references"
        }

        let recentFlashcardSetsSubtitle: String
        if !recentDecks.isEmpty {
            recentFlashcardSetsSubtitle = "\(recentDecks.count) recent \(recentDecks.count == 1 ? "deck" : "decks")"
        } else {
            recentFlashcardSetsSubtitle = "Your recently opened decks"
        }

        let recentAverageQuizScore: Int?
        if !quizHistory.isEmpty {
            let samples = quizHistory.prefix(5)
            let total = samples.reduce(0) { $0 + $1.percentageScore }
            recentAverageQuizScore = Int((Double(total) / Double(samples.count)).rounded())
        } else {
            recentAverageQuizScore = nil
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
            recentBriefsSubtitle: recentBriefsSubtitle,
            recentBriefCount: recentBriefs.count,
            recentFlashcardSetsSubtitle: recentFlashcardSetsSubtitle,
            recentDeckCount: recentDecks.count,
            versionSubtitle: MoreHubSnapshot.versionString(),
            stats: MoreStatsSnapshot(
                studiedCardCount: studiedCardCount,
                dueCardCount: dueCardCount,
                quizSessionCount: recentQuizCount,
                averageQuizScore: recentAverageQuizScore,
                weakAreaSignals: quizStore?.weakAreaSignals(limit: 3) ?? []
            ),
            recentBriefs: recentBriefs,
            recentDecks: recentDecks
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

    private func moreRecentBriefItems(from activities: [StudyActivityRecord], limit: Int = 10) -> [MoreRecentBriefItem] {
        var seenResourceIDs = Set<String>()
        var items: [MoreRecentBriefItem] = []

        for activity in activities {
            guard case let .sharedResource(id) = activity.destination else { continue }
            guard seenResourceIDs.insert(id).inserted else { continue }
            guard let resource = sharedResource(id: id) else { continue }

            items.append(
                MoreRecentBriefItem(
                    id: id,
                    resourceID: id,
                    title: moreResourceDisplayTitle(resource),
                    context: moreResourceContextLabel(resource),
                    summary: resource.summary,
                    lastOpenedAt: activity.lastInteractedAt
                )
            )

            if items.count == limit {
                break
            }
        }

        return items
    }

    private func moreRecentDeckItems(from activities: [StudyActivityRecord], limit: Int = 10) -> [MoreRecentDeckItem] {
        var seenDestinations = Set<String>()
        var items: [MoreRecentDeckItem] = []

        for activity in activities {
            switch activity.destination {
            case let .eventDeck(phaseID, eventID, deckID):
                let key = "event-\(phaseID)-\(eventID)-\(deckID)"
                guard seenDestinations.insert(key).inserted else { continue }
                guard let context = eventDeckContext(phaseID: phaseID, eventID: eventID, deckID: deckID) else { continue }

                items.append(
                    MoreRecentDeckItem(
                        id: key,
                        deckTitle: context.1.title,
                        context: context.0.code,
                        summary: context.1.summary,
                        lastOpenedAt: activity.lastInteractedAt,
                        destination: .eventDeck(phaseID: phaseID, eventID: eventID, deckID: deckID)
                    )
                )
            case let .libraryDeck(id):
                let key = "library-\(id)"
                guard seenDestinations.insert(key).inserted else { continue }
                guard let hub = libraryHub(id: id) else { continue }

                items.append(
                    MoreRecentDeckItem(
                        id: key,
                        deckTitle: hub.deck.title,
                        context: "General Library",
                        summary: hub.summary,
                        lastOpenedAt: activity.lastInteractedAt,
                        destination: .libraryDeck(id: id)
                    )
                )
            default:
                continue
            }

            if items.count == limit {
                break
            }
        }

        return items
    }

    private func moreResourceContextLabel(_ resource: SharedResource) -> String {
        if resource.placement == .generalLibrary {
            return "General Library"
        }

        if let phaseID = resource.phaseIDs.first,
           let phase = phase(id: phaseID) {
            return phase.title
        }

        return resource.librarySection.displayName
    }

    private func moreResourceDisplayTitle(_ resource: SharedResource) -> String {
        switch resource.id {
        case "ep-limits-key":
            return "EP / Limits Key"
        case "ep-nwcs-admin":
            return "EP N/W/C"
        default:
            return resource.title
        }
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
