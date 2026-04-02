import Foundation

private enum HomeQuestionBank {
    static func build(from quizBank: QuizBank, topics: [StudyTopicDefinition]) -> [HomeQuestionDefinition] {
        let candidates = quizBank.questions.compactMap { question -> (HomeQuestionDefinition, Int)? in
            let category = quizBank.category(id: question.categoryID)
            let topicIDs = HomeTopicMatcher.topicIDs(
                matching: [question.prompt, question.correctChoice?.text ?? "", question.reference ?? "", category?.title ?? ""] + question.tags + question.choices.map(\.text),
                topics: topics
            )
            guard !topicIDs.isEmpty else { return nil }

            let isUniversal = true

            let difficulty: HomeQuestionDifficulty
            if question.format == .trueFalse {
                difficulty = .foundational
            } else if question.explanation.count > 110 {
                difficulty = .advanced
            } else {
                difficulty = .moderate
            }

            var score = 0
            if question.format == .trueFalse { score += 1 }
            if question.reference?.hasPrefix("3-") == true || question.reference?.hasPrefix("5-") == true { score += 3 }
            score += topicIDs.filter { ["eps", "limits", "nwc", "landing-pattern", "instrument-comms"].contains($0) }.count * 2

            let question = HomeQuestionDefinition(
                id: "home-q-\(question.id)",
                sourceQuestionID: question.id,
                categoryID: question.categoryID,
                prompt: question.prompt,
                choices: question.choices,
                correctChoiceID: question.correctChoiceID,
                answer: "Correct answer: \(question.correctChoice?.text ?? "Unavailable")\n\n\(question.explanation)",
                topicIDs: topicIDs,
                difficulty: difficulty,
                isUniversal: isUniversal
            )
            return (question, score)
        }

        let ranked = candidates
            .sorted { lhs, rhs in
                if lhs.1 == rhs.1 {
                    return lhs.0.prompt.localizedCaseInsensitiveCompare(rhs.0.prompt) == .orderedAscending
                }
                return lhs.1 > rhs.1
            }
            .map(\.0)

        var seenPrompts = Set<String>()
        var uniqueQuestions: [HomeQuestionDefinition] = []

        for question in ranked {
            let key = HomeTopicMatcher.normalized(question.prompt)
            if seenPrompts.insert(key).inserted {
                uniqueQuestions.append(question)
            }
            if uniqueQuestions.count == 150 {
                break
            }
        }

        return uniqueQuestions
    }
}

private enum HomeTopicMatcher {
    static func normalized(_ value: String) -> String {
        value
            .trimmingCharacters(in: .whitespacesAndNewlines)
            .folding(options: [.diacriticInsensitive, .caseInsensitive], locale: .current)
            .lowercased()
    }

    static func topicIDs(for card: FlashcardDefinition, topics: [StudyTopicDefinition]) -> [String] {
        let values = card.tags + [card.prompt, card.answer]
        return topicIDs(matching: values, topics: topics)
    }

    static func topicIDs(matching values: [String], topics: [StudyTopicDefinition]) -> [String] {
        let haystack = normalized(values.joined(separator: " "))
        guard !haystack.isEmpty else { return [] }

        return topics.compactMap { topic in
            let matchedTagCount = topic.linkedTagValues.reduce(into: 0) { partialResult, tag in
                if haystack.contains(normalized(tag)) {
                    partialResult += 1
                }
            }
            return matchedTagCount > 0 ? topic.id : nil
        }
    }
}

private struct HomeTopicWeakness {
    let topic: StudyTopicDefinition
    let score: Double
    let detail: String
    let destination: SearchDestination?
    let urgency: HomeTopicUrgency
    let ratingColor: HomeTopicRatingColor?
}

extension StudyAppModel {
    func buildHomeScreenSnapshot(now: Date = .now) -> HomeScreenSnapshot {
        let preferences = progressStore?.homePreferences() ?? HomePreferencesRecord()
        let focusTopics = pinnedFocusTopics(from: preferences)
        let suggestedTopics = suggestedFocusTopics(from: preferences)
        let continueStudying = continueStudyingSnapshot(now: now)
        let reviewDue = reviewDueSnapshots(now: now)
        let weakAreas = weakAreaSnapshots()
        let questionOfDay = questionOfDaySnapshot(now: now)
        let streak = studyStreak(now: now)

        let statusLine: String
        if !reviewDue.isEmpty {
            statusLine = reviewDue.count == 1 ? "1 review overdue" : "\(reviewDue.count) reviews overdue"
        } else if !weakAreas.isEmpty {
            statusLine = weakAreas.count == 1 ? "1 weak area worth revisiting" : "\(weakAreas.count) weak areas worth revisiting"
        } else if streak > 0 {
            statusLine = streak == 1 ? "1-day study streak" : "\(streak)-day study streak"
        } else {
            statusLine = "Ready to study"
        }

        let personalizedLine = personalizedIntroLine(
            reviewDue: reviewDue,
            weakAreas: weakAreas,
            currentFocus: focusTopics,
            continueStudying: continueStudying
        )

        return HomeScreenSnapshot(
            greeting: greeting(for: now),
            statusLine: statusLine,
            personalizedLine: personalizedLine,
            continueStudying: continueStudying,
            currentFocus: HomeCurrentFocusSnapshot(pinnedTopics: focusTopics, suggestedTopics: suggestedTopics),
            reviewDue: reviewDue,
            weakAreas: weakAreas,
            questionOfDay: questionOfDay,
            studyStreak: streak
        )
    }

    private func personalizedIntroLine(
        reviewDue: [HomeTopicActionSnapshot],
        weakAreas: [HomeTopicActionSnapshot],
        currentFocus: [HomeFocusTopicSnapshot],
        continueStudying: HomeContinueStudyingSnapshot
    ) -> String {
        if let review = reviewDue.first {
            return "You may want to review \(review.title) today."
        }

        if let weakArea = weakAreas.first {
            return "You may want to revisit \(weakArea.title) today."
        }

        if let focus = currentFocus.first {
            return "Keep focusing on \(focus.title) today."
        }

        if !continueStudying.isFallback {
            let title = continueStudying.title
                .replacingOccurrences(of: "Last studied: ", with: "")
                .replacingOccurrences(of: "Last reviewed: ", with: "")
                .replacingOccurrences(of: "Last opened: ", with: "")
                .replacingOccurrences(of: "Last watched: ", with: "")
            return "Pick up where you left off in \(title)."
        }

        return "You're in a good place to keep building today."
    }

    func topicIDs(for event: Event) -> [String] {
        let values = event.tags + [event.code, event.title, event.summary, event.overview]
        return HomeTopicMatcher.topicIDs(matching: values, topics: studyTopics)
    }

    func topicIDs(for deck: FlashcardDeck, event: Event?) -> [String] {
        let cardLookup = Dictionary(uniqueKeysWithValues: studyManifest.flashcards.map { ($0.id, $0) })
        let cardValues = deck.cardIDs.compactMap { cardLookup[$0] }.flatMap { $0.tags + [$0.prompt, $0.answer] }
        let eventValues = event.map { $0.tags + [$0.code, $0.title, $0.summary] } ?? []
        return HomeTopicMatcher.topicIDs(
            matching: [deck.title, deck.summary] + cardValues + eventValues,
            topics: studyTopics
        )
    }

    func topicIDs(for bank: QuestionBank, event: Event) -> [String] {
        let questionValues = bank.questions.flatMap { [$0.prompt, $0.answer, $0.explanation ?? ""] }
        return HomeTopicMatcher.topicIDs(
            matching: [bank.title, bank.summary] + event.tags + [event.code, event.title] + questionValues,
            topics: studyTopics
        )
    }

    func topicIDs(for resource: SharedResource) -> [String] {
        let resourceMatched = studyTopics
            .filter { $0.linkedResourceIDs.contains(resource.id) }
            .map(\.id)

        let tagMatched = HomeTopicMatcher.topicIDs(
            matching: resource.tags + resource.topicIDs + [resource.title, resource.summary],
            topics: studyTopics
        )

        return Array(Set(resourceMatched + tagMatched)).sorted()
    }

    func topicIDs(for video: VideoAsset) -> [String] {
        HomeTopicMatcher.topicIDs(matching: video.tags + [video.title, video.summary], topics: studyTopics)
    }

    func phase(containingEventID eventID: String) -> Phase? {
        studyManifest.phases.first { phase in
            phase.categories.contains { category in
                category.events.contains { $0.id == eventID }
            }
        }
    }

    func libraryHub(containingDeckID deckID: String) -> LibraryStudyHub? {
        studyManifest.libraryStudyHubs.first { $0.deck.id == deckID }
    }

    private func greeting(for now: Date) -> String {
        let hour = Calendar.current.component(.hour, from: now)
        switch hour {
        case 0..<5: return "Good evening"
        case 5..<12: return "Good morning"
        case 12..<17: return "Good afternoon"
        default: return "Good evening"
        }
    }

    private func pinnedFocusTopics(from preferences: HomePreferencesRecord) -> [HomeFocusTopicSnapshot] {
        let topicLookup = Dictionary(uniqueKeysWithValues: studyTopics.map { ($0.id, $0) })
        return preferences.pinnedTopicIDs.compactMap { id in
            guard let topic = topicLookup[id] else { return nil }
            return HomeFocusTopicSnapshot(
                id: topic.id,
                title: topic.shortTitle,
                iconName: topic.iconName,
                destination: destination(for: topic)
            )
        }
    }

    private func suggestedFocusTopics(from preferences: HomePreferencesRecord) -> [HomeFocusTopicSnapshot] {
        guard preferences.pinnedTopicIDs.isEmpty else { return [] }

        return studyTopics
            .filter(\.isUserFocusable)
            .prefix(4)
            .map { topic in
                HomeFocusTopicSnapshot(
                    id: topic.id,
                    title: topic.shortTitle,
                    iconName: topic.iconName,
                    destination: destination(for: topic)
                )
            }
    }

    private func continueStudyingSnapshot(now: Date) -> HomeContinueStudyingSnapshot {
        guard let activity = progressStore?.recentActivities().first(where: { $0.kind != .questionOfDay }),
              let destination = destination(for: activity.destination) else {
            return .empty
        }

        let formatter = RelativeDateTimeFormatter()
        formatter.unitsStyle = .full
        let relative = formatter.localizedString(for: activity.lastInteractedAt, relativeTo: now)

        let title: String
        switch activity.kind {
        case .event:
            title = "Last opened: \(activity.title)"
        case .flashcardDeck, .flashcardSession:
            title = "Last studied: \(activity.title)"
        case .practiceTest:
            title = "Last reviewed: \(activity.title)"
        case .sharedResource:
            title = "Last opened: \(activity.title)"
        case .video:
            title = "Last watched: \(activity.title)"
        case .questionOfDay:
            title = "Last studied: \(activity.title)"
        }

        return HomeContinueStudyingSnapshot(
            title: title,
            subtitle: activity.subtitle,
            detail: "Last active \(relative).",
            actionTitle: "Resume",
            destination: destination,
            isFallback: false
        )
    }

    private func reviewDueSnapshots(now: Date) -> [HomeTopicActionSnapshot] {
        studyTopics
            .filter(\.isReviewTopic)
            .compactMap { topic in
                guard let lastReviewedAt = lastMeaningfulReviewDate(for: topic) else { return nil }
                let days = max(0, Calendar.current.dateComponents([.day], from: Calendar.current.startOfDay(for: lastReviewedAt), to: Calendar.current.startOfDay(for: now)).day ?? 0)
                guard days >= 4 else { return nil }

                let urgency: HomeTopicUrgency = days >= 8 ? .alert : .warning
                return HomeTopicActionSnapshot(
                    id: topic.id,
                    title: topic.title,
                    detail: "\(topic.shortTitle) not reviewed in \(days) day\(days == 1 ? "" : "s")",
                    actionTitle: "Review",
                    iconName: topic.iconName,
                    destination: destination(for: topic),
                    urgency: urgency,
                    ratingColor: nil
                )
            }
            .sorted {
                detailDayCount($0.detail) > detailDayCount($1.detail)
            }
            .prefix(4)
            .map { $0 }
    }

    private func weakAreaSnapshots() -> [HomeTopicActionSnapshot] {
        buildWeaknesses()
            .sorted { lhs, rhs in
                if lhs.score == rhs.score {
                    return lhs.topic.title.localizedCaseInsensitiveCompare(rhs.topic.title) == .orderedAscending
                }
                return lhs.score > rhs.score
            }
            .prefix(3)
            .map { weakness in
                HomeTopicActionSnapshot(
                    id: weakness.topic.id,
                    title: weakness.topic.title,
                    detail: weakness.detail,
                    actionTitle: weakness.topic.id == "maneuvers" ? "Practice" : "Review",
                    iconName: weakness.topic.iconName,
                    destination: weakness.destination,
                    urgency: weakness.urgency,
                    ratingColor: weakness.ratingColor
                )
            }
    }

    private func questionOfDaySnapshot(now: Date) -> HomeQuestionOfDaySnapshot {
        let bank = HomeQuestionBank.build(from: quizBank, topics: studyTopics)
        guard !bank.isEmpty else { return .empty }

        let dayIndex = Calendar.current.ordinality(of: .day, in: .era, for: now) ?? 0
        let question = bank[dayIndex % bank.count]
        let progress = progressStore?.dailyQuestionProgress(for: question.id)

        return HomeQuestionOfDaySnapshot(
            question: question,
            selectedChoiceID: progress?.selectedChoiceID,
            wasCorrect: progress?.wasCorrect
        )
    }

    private func studyStreak(now: Date) -> Int {
        let calendar = Calendar.current
        let days = Set(
            (progressStore?.recentActivities() ?? [])
                .map { calendar.startOfDay(for: $0.lastInteractedAt) }
        )

        guard !days.isEmpty else { return 0 }

        var streak = 0
        var currentDay = calendar.startOfDay(for: now)

        while days.contains(currentDay) {
            streak += 1
            guard let previous = calendar.date(byAdding: .day, value: -1, to: currentDay) else { break }
            currentDay = previous
        }

        return streak
    }

    private func buildWeaknesses() -> [HomeTopicWeakness] {
        let topicLookup = Dictionary(uniqueKeysWithValues: studyTopics.filter(\.isWeakAreaTopic).map { ($0.id, $0) })
        var scores: [String: Double] = [:]
        var details: [String: [String]] = [:]
        var ratingSignals: [String: (rating: HomeTopicRatingColor, reviewedAt: Date)] = [:]

        let flashcardsByID = Dictionary(uniqueKeysWithValues: studyManifest.flashcards.map { ($0.id, $0) })

        for record in progressStore?.allCardProgressRecords() ?? [] {
            guard let card = flashcardsByID[record.cardID] else { continue }
            let matchedTopicIDs = HomeTopicMatcher.topicIDs(for: card, topics: studyTopics)
            guard !matchedTopicIDs.isEmpty else { continue }

            let cardScore = Double(record.missedCount * 3 + record.hardCount * 2) + max(0, 1.0 - record.mastery)
            guard cardScore > 0 else { continue }

            for topicID in matchedTopicIDs {
                scores[topicID, default: 0] += cardScore
            }

            guard
                let lastRating = record.lastRating,
                let lastReviewedAt = record.lastReviewedAt
            else { continue }

            let ratingColor = colorSignal(for: lastRating)
            for topicID in matchedTopicIDs {
                if let existing = ratingSignals[topicID], existing.reviewedAt >= lastReviewedAt {
                    continue
                }
                ratingSignals[topicID] = (ratingColor, lastReviewedAt)
            }
        }

        for attempt in progressStore?.allTestAttempts() ?? [] {
            guard !attempt.topicIDs.isEmpty else { continue }
            let attemptScore = Double(max(1, attempt.missedQuestionIDs.count)) * 1.5
            guard attemptScore > 0 else { continue }
            for topicID in attempt.topicIDs {
                scores[topicID, default: 0] += attemptScore
                details[topicID, default: []].append("\(attempt.missedQuestionIDs.count) missed quiz item\(attempt.missedQuestionIDs.count == 1 ? "" : "s")")
            }
        }

        for session in progressStore?.recentSessions() ?? [] where session.outcome == .abandoned {
            for topicID in session.topicIDs {
                scores[topicID, default: 0] += 1.2
                details[topicID, default: []].append("recent session abandoned")
            }
        }

        let questionLookup = Dictionary(
            uniqueKeysWithValues: HomeQuestionBank.build(from: quizBank, topics: studyTopics).map { ($0.id, $0) }
        )

        for progress in progressStore?.allDailyQuestionProgressRecords() ?? [] where progress.wasCorrect == false {
            guard let question = questionLookup[progress.questionID] else { continue }
            for topicID in question.topicIDs {
                scores[topicID, default: 0] += 1
                details[topicID, default: []].append("Question of the Day missed")
            }
        }

        return scores.compactMap { topicID, score in
            guard let topic = topicLookup[topicID], score >= 2 else { return nil }

            let detail = details[topicID]?.first
                ?? defaultWeaknessDetail(for: topic)
            let urgency: HomeTopicUrgency = score >= 6 ? .alert : .warning
            return HomeTopicWeakness(
                topic: topic,
                score: score,
                detail: detail,
                destination: destination(for: topic),
                urgency: urgency,
                ratingColor: ratingSignals[topicID]?.rating
            )
        }
    }

    private func colorSignal(for rating: FlashcardRating) -> HomeTopicRatingColor {
        switch rating {
        case .missed:
            return .missed
        case .hard:
            return .hard
        case .good:
            return .good
        case .easy:
            return .easy
        }
    }

    private func defaultWeaknessDetail(for topic: StudyTopicDefinition) -> String {
        switch topic.id {
        case "instrument-comms":
            return "Recent responses suggest instrument comms need another pass"
        case "lost-sight":
            return "Recent performance signals point back to lost sight procedures"
        case "landing-pattern":
            return "Pattern knowledge is slipping relative to the rest of your study set"
        case "systems":
            return "Systems answers have been less consistent than your core memory work"
        case "maneuvers":
            return "Maneuver knowledge has been tougher than your recent average"
        default:
            return "\(topic.shortTitle) has been harder than the rest of your recent study"
        }
    }

    private func lastMeaningfulReviewDate(for topic: StudyTopicDefinition) -> Date? {
        let flashcardsByID = Dictionary(uniqueKeysWithValues: studyManifest.flashcards.map { ($0.id, $0) })

        let cardDates = (progressStore?.allCardProgressRecords() ?? []).compactMap { record -> Date? in
            guard let card = flashcardsByID[record.cardID] else { return nil }
            let matched = HomeTopicMatcher.topicIDs(for: card, topics: [topic])
            return matched.isEmpty ? nil : record.lastReviewedAt
        }

        let attemptDates = (progressStore?.allTestAttempts() ?? [])
            .filter { $0.topicIDs.contains(topic.id) }
            .map(\.takenAt)

        let activityDates = (progressStore?.recentActivities() ?? []).compactMap { activity -> Date? in
            guard activity.topicIDs.contains(topic.id) else { return nil }
            switch activity.kind {
            case .flashcardDeck, .flashcardSession, .practiceTest, .sharedResource, .questionOfDay, .event:
                return activity.lastInteractedAt
            case .video:
                return nil
            }
        }

        return (cardDates + attemptDates + activityDates).max()
    }

    private func destination(for topic: StudyTopicDefinition) -> SearchDestination? {
        if let libraryHubID = topic.linkedLibraryHubIDs.first {
            return .libraryDeck(id: libraryHubID)
        }
        if let resourceID = topic.linkedResourceIDs.first {
            return .sharedResource(id: resourceID)
        }
        if let phaseID = topic.preferredDestinationPhaseID {
            return .phase(id: phaseID)
        }
        return nil
    }

    private func destination(for activity: StudyActivityDestination) -> SearchDestination? {
        switch activity {
        case let .event(phaseID, eventID):
            return .event(phaseID: phaseID, eventID: eventID)
        case let .eventDeck(phaseID, eventID, deckID):
            return .eventDeck(phaseID: phaseID, eventID: eventID, deckID: deckID)
        case let .libraryDeck(id):
            return .libraryDeck(id: id)
        case let .sharedResource(id):
            return .sharedResource(id: id)
        case let .video(id):
            return .video(id: id)
        case .questionOfDay:
            return nil
        }
    }

    private func detailDayCount(_ detail: String) -> Int {
        detail.split(separator: " ").compactMap { Int($0) }.first ?? 0
    }
}
