import SwiftUI

struct FlashcardDeckView: View {
    let deck: FlashcardDeck
    let event: Event?
    let contextLabel: String
    let availableFilters: [FlashcardFilterToken]

    @EnvironmentObject private var appModel: StudyAppModel
    @State private var selectedFilters: Set<FlashcardFilterToken>

    init(event: Event, deck: FlashcardDeck) {
        self.deck = deck
        self.event = event
        self.contextLabel = event.code
        self.availableFilters = []
        self._selectedFilters = State(initialValue: [])
    }

    init(hub: LibraryStudyHub) {
        self.deck = hub.deck
        self.event = nil
        self.contextLabel = "General Library"
        self.availableFilters = hub.availableFilters
        self._selectedFilters = State(initialValue: Set(hub.availableFilters))
    }

    private var activeFilters: Set<FlashcardFilterToken> {
        availableFilters.isEmpty ? [] : selectedFilters
    }

    var body: some View {
        let performance = appModel.deckPerformance(for: deck, filters: activeFilters)
        let snapshots = appModel.cardSnapshots(in: deck, filters: activeFilters)

        AppScrollScreen {
            HeroCard(
                eyebrow: contextLabel,
                title: deck.title,
                subtitle: nil
            ) {
                FlashcardPerformanceBar(snapshot: performance)

                reviewActionRow
            }

            if !availableFilters.isEmpty {
                VStack(alignment: .leading, spacing: 12) {
                    SectionHeader(
                        eyebrow: "Filter",
                        title: "Study focus",
                        subtitle: nil
                    )

                    SectionContainer {
                        FilterChipGroup(
                            options: availableFilters,
                            selectedOptions: selectedFilters,
                            title: { $0.displayName },
                            tint: { _ in AppTheme.accent },
                            action: toggle(_:)
                        )
                    }
                }
            }

            if !snapshots.isEmpty {
                VStack(alignment: .leading, spacing: 12) {
                    SectionHeader(
                        eyebrow: "Deck",
                        title: "All cards",
                        subtitle: nil
                    )

                    LazyVStack(spacing: 12) {
                        ForEach(snapshots, id: \.card.id) { item in
                            NavigationLink {
                                FlashcardDetailView(
                                    event: event,
                                    deck: deck,
                                    item: item,
                                    contextLabel: contextLabel,
                                    filters: activeFilters
                                )
                            } label: {
                                FlashcardPreviewCard(item: item)
                            }
                            .buttonStyle(.plain)
                        }
                    }
                }
            }
        }
        .scrollActivatedNavigationChrome(title: deck.title)
        .task {
            appModel.recordDeckOpened(event: event, deck: deck, contextLabel: contextLabel)
        }
    }

    private var reviewActionRow: some View {
        ViewThatFits(in: .horizontal) {
            HStack(spacing: 12) {
                smartReviewLink
                fullDeckLink
            }

            VStack(spacing: 10) {
                smartReviewLink
                fullDeckLink
            }
        }
    }

    private var smartReviewLink: some View {
        NavigationLink {
            FlashcardStudyView(
                event: event,
                deck: deck,
                contextLabel: contextLabel,
                cards: appModel.smartReviewCards(in: deck, filters: activeFilters)
            )
        } label: {
            CompactReviewAction(
                title: "Smart review",
                icon: "bolt.fill",
                accent: AppTheme.statusColor(.warning)
            )
        }
        .buttonStyle(.plain)
    }

    private var fullDeckLink: some View {
        NavigationLink {
            FlashcardStudyView(
                event: event,
                deck: deck,
                contextLabel: contextLabel,
                cards: appModel.cards(in: deck, filters: activeFilters)
            )
        } label: {
            CompactReviewAction(
                title: "Study full deck",
                icon: "rectangle.stack.fill",
                accent: AppTheme.domainColor(.flashcards)
            )
        }
        .buttonStyle(.plain)
    }

    private func toggle(_ filter: FlashcardFilterToken) {
        let allFilters = Set(availableFilters)
        guard !allFilters.isEmpty else { return }

        if selectedFilters.contains(filter) {
            selectedFilters.remove(filter)
            if selectedFilters.isEmpty {
                selectedFilters = allFilters
            }
        } else {
            selectedFilters.insert(filter)
        }
    }
}

struct FlashcardDetailView: View {
    let event: Event?
    let deck: FlashcardDeck
    let item: FlashcardListItemSnapshot
    let contextLabel: String
    let filters: Set<FlashcardFilterToken>

    @EnvironmentObject private var appModel: StudyAppModel

    var body: some View {
        AppScrollScreen {
            HeroCard(
                eyebrow: contextLabel,
                title: item.card.prompt,
                subtitle: item.answerPreview
            ) {
                HStack(spacing: 8) {
                    Badge(text: item.band.label, color: item.band.displayColor)

                    ForEach(referenceBadges(for: item.card), id: \.text) { badge in
                        Badge(text: badge.text, color: badge.color)
                    }

                    if item.isPriority {
                        Badge(text: "Smart review", color: AppTheme.warning)
                    }
                }
            }

            SectionContainer {
                VStack(alignment: .leading, spacing: 12) {
                    Text("Answer")
                        .font(.headline.weight(.semibold))
                        .foregroundStyle(AppTheme.textPrimary)

                    Text(item.card.answer)
                        .font(.body)
                        .foregroundStyle(AppTheme.textSecondary)
                        .fixedSize(horizontal: false, vertical: true)
                }
            }

            NavigationLink {
                FlashcardStudyView(
                    event: event,
                    deck: deck,
                    contextLabel: contextLabel,
                    cards: appModel.focusedReviewCards(in: deck, startingWith: item.card.id, filters: filters)
                )
            } label: {
                StudyActionButton(title: "Review this card", icon: "play.fill", tint: AppTheme.accent)
            }
            .buttonStyle(.plain)
        }
        .scrollActivatedNavigationChrome(title: "Card detail")
    }
}

struct FlashcardStudyView: View {
    let event: Event?
    let deck: FlashcardDeck
    let contextLabel: String
    let cards: [FlashcardDefinition]

    @EnvironmentObject private var appModel: StudyAppModel
    @Environment(\.dismiss) private var dismiss

    @State private var currentIndex = 0
    @State private var showingAnswer = false
    @State private var startedAt = Date()
    @State private var didRecordSession = false

    var body: some View {
        Group {
            if cards.isEmpty {
                AppScrollScreen {
                    EmptyStateCard(
                        icon: "checkmark.circle",
                        title: "No cards in this study view",
                        message: "Try a different study mode or turn on more filters to broaden the deck."
                    )
                }
            } else {
                AppScrollScreen(bottomPadding: 28) {
                    header
                    flashcardBody

                    if showingAnswer {
                        ratingBar
                    }
                }
            }
        }
        .scrollActivatedNavigationChrome(title: deck.title)
        .onAppear {
            startedAt = .now
        }
        .onDisappear {
            guard !didRecordSession, !cards.isEmpty else { return }

            appModel.recordStudySession(
                kind: .flashcards,
                topicIDs: appModel.topicIDs(for: deck, event: event),
                startedAt: startedAt,
                endedAt: .now,
                completedItems: currentIndex,
                totalItems: cards.count,
                outcome: .abandoned,
                activity: StudyActivityRecord(
                    kind: .flashcardSession,
                    destination: sessionDestination,
                    title: deck.title,
                    subtitle: contextLabel,
                    topicIDs: appModel.topicIDs(for: deck, event: event),
                    progressContext: "Abandoned"
                )
            )
            didRecordSession = true
        }
    }

    private var header: some View {
        HeroCard(
            eyebrow: contextLabel,
            title: deck.title,
            subtitle: "Card \(currentIndex + 1) of \(cards.count)"
        ) {
            ProgressStrip(value: Double(currentIndex + 1), total: Double(cards.count), tint: AppTheme.accent)
        }
    }

    private var flashcardBody: some View {
        let card = cards[currentIndex]

        return SectionContainer(highlighted: true) {
            Button {
                guard !showingAnswer else { return }
                withAnimation(.easeInOut(duration: 0.2)) {
                    showingAnswer = true
                }
            } label: {
                VStack(alignment: .leading, spacing: 18) {
                    HStack(spacing: 8) {
                        Text(showingAnswer ? "Answer" : "Prompt")
                            .font(.caption.weight(.semibold))
                            .foregroundStyle(showingAnswer ? AppTheme.success : AppTheme.accent)

                        ForEach(referenceBadges(for: card), id: \.text) { badge in
                            Badge(text: badge.text, color: badge.color)
                        }
                    }

                    Text(showingAnswer ? card.answer : card.prompt)
                        .font(showingAnswer ? .body : .system(size: 30, weight: .bold, design: .rounded))
                        .foregroundStyle(showingAnswer ? AppTheme.textSecondary : AppTheme.textPrimary)
                        .frame(maxWidth: .infinity, alignment: .leading)
                        .fixedSize(horizontal: false, vertical: true)

                    Text(showingAnswer ? "Tap Hide Answer below if you want another read before rating it." : "Tap anywhere on the card to reveal the answer.")
                        .font(.footnote)
                        .foregroundStyle(AppTheme.textSecondary)
                }
                .frame(maxWidth: .infinity, alignment: .leading)
            }
            .buttonStyle(.plain)

            if showingAnswer {
                Button {
                    withAnimation(.easeInOut(duration: 0.2)) {
                        showingAnswer = false
                    }
                } label: {
                    StudyActionButton(title: "Hide answer", tint: AppTheme.accent, isProminent: false)
                }
                .buttonStyle(.plain)
            }
        }
    }

    private var ratingBar: some View {
        VStack(alignment: .leading, spacing: 12) {
            SectionHeader(
                eyebrow: "Rate it",
                title: "How well did you know it?",
                subtitle: nil
            )

            LazyVGrid(columns: [GridItem(.adaptive(minimum: 140), spacing: 10)], spacing: 10) {
                ForEach(FlashcardRating.allCases, id: \.self) { rating in
                    Button {
                        submit(rating)
                    } label: {
                        Text(rating.label)
                            .font(.subheadline.weight(.semibold))
                            .foregroundStyle(AppTheme.prominentText(buttonColor(for: rating)))
                            .frame(maxWidth: .infinity)
                            .padding(.vertical, 14)
                            .background(
                                RoundedRectangle(cornerRadius: 16, style: .continuous)
                                    .fill(AppTheme.badgeFill(buttonColor(for: rating)))
                                    .overlay(
                                        RoundedRectangle(cornerRadius: 16, style: .continuous)
                                            .stroke(AppTheme.badgeStroke(buttonColor(for: rating)), lineWidth: 1)
                                    )
                            )
                    }
                    .buttonStyle(.plain)
                }
            }
        }
    }

    private func submit(_ rating: FlashcardRating) {
        appModel.recordCardReview(card: cards[currentIndex], rating: rating)

        if currentIndex == cards.count - 1 {
            if let event {
                appModel.markEventStudied(event)
            }
            appModel.recordStudySession(
                kind: .flashcards,
                topicIDs: appModel.topicIDs(for: deck, event: event),
                startedAt: startedAt,
                endedAt: .now,
                completedItems: cards.count,
                totalItems: cards.count,
                outcome: .completed,
                activity: StudyActivityRecord(
                    kind: .flashcardSession,
                    destination: sessionDestination,
                    title: deck.title,
                    subtitle: contextLabel,
                    topicIDs: appModel.topicIDs(for: deck, event: event),
                    completedAt: .now,
                    progressContext: "Completed"
                )
            )
            didRecordSession = true
            dismiss()
            return
        }

        currentIndex += 1
        showingAnswer = false
    }

    private func buttonColor(for rating: FlashcardRating) -> Color {
        switch rating {
        case .missed: AppTheme.statusColor(.rejected)
        case .hard: AppTheme.statusColor(.warning)
        case .good: AppTheme.accent
        case .easy: AppTheme.statusColor(.approved)
        }
    }

    private var sessionDestination: StudyActivityDestination {
        if let event, let phase = appModel.phase(containingEventID: event.id) {
            return .eventDeck(phaseID: phase.id, eventID: event.id, deckID: deck.id)
        }
        if let hub = appModel.libraryHub(containingDeckID: deck.id) {
            return .libraryDeck(id: hub.id)
        }
        return .questionOfDay(questionID: deck.id)
    }
}

private struct FlashcardPerformanceBar: View {
    let snapshot: DeckPerformanceSnapshot

    var body: some View {
        VStack(alignment: .leading, spacing: 10) {
            GeometryReader { proxy in
                HStack(spacing: 0) {
                    ForEach(snapshot.segments, id: \.band) { segment in
                        Rectangle()
                            .fill(segment.band.displayColor)
                            .frame(width: segmentWidth(for: segment, totalWidth: proxy.size.width))
                    }
                }
                .frame(width: proxy.size.width, height: 12, alignment: .leading)
                .background(AppTheme.secondaryGroupedBackground)
                .clipShape(Capsule())
            }
            .frame(height: 12)

            HStack(spacing: 8) {
                ForEach(snapshot.segments, id: \.band) { segment in
                    HStack(spacing: 6) {
                        Circle()
                            .fill(segment.band.displayColor)
                            .frame(width: 8, height: 8)

                        Text("\(segment.band.label) \(segment.count)")
                            .font(.caption.weight(.semibold))
                            .foregroundStyle(AppTheme.textSecondary)
                            .lineLimit(1)
                            .minimumScaleFactor(0.85)
                    }
                    .frame(maxWidth: .infinity, alignment: .leading)
                }
            }
        }
    }

    private func segmentWidth(for segment: DeckPerformanceSegment, totalWidth: CGFloat) -> CGFloat {
        guard snapshot.totalCount > 0 else { return 0 }
        return totalWidth * (CGFloat(segment.count) / CGFloat(snapshot.totalCount))
    }
}

private struct CompactReviewAction: View {
    let title: String
    let icon: String
    let accent: Color

    var body: some View {
        StudyActionButton(title: title, icon: icon, tint: accent, isProminent: false)
    }
}

private struct FlashcardPreviewCard: View {
    let item: FlashcardListItemSnapshot

    var body: some View {
        SectionContainer {
            VStack(alignment: .leading, spacing: 12) {
                HStack(alignment: .center, spacing: 10) {
                    Circle()
                        .fill(item.band.displayColor)
                        .frame(width: 10, height: 10)

                    Text(item.band.label)
                        .font(.caption.weight(.semibold))
                        .foregroundStyle(item.band.displayColor)

                    Spacer(minLength: 0)

                    ForEach(referenceBadges(for: item.card), id: \.text) { badge in
                        Badge(text: badge.text, color: badge.color)
                    }

                    if item.isPriority {
                        Badge(text: "Smart review", color: AppTheme.warning)
                    }
                }

                Text(item.card.prompt)
                    .font(.headline.weight(.semibold))
                    .foregroundStyle(AppTheme.textPrimary)
                    .frame(maxWidth: .infinity, alignment: .leading)

                Text(item.answerPreview)
                    .font(.subheadline)
                    .foregroundStyle(AppTheme.textSecondary)
                    .lineLimit(3)
                    .frame(maxWidth: .infinity, alignment: .leading)
            }
        }
    }
}

private extension FlashcardPerformanceBand {
    var displayColor: Color {
        switch self {
        case .notStudied:
            return AppTheme.textMuted
        case .gradeD:
            return AppTheme.statusColor(.rejected)
        case .gradeC:
            return AppTheme.statusColor(.warning)
        case .gradeB:
            return AppTheme.accent
        case .gradeA:
            return AppTheme.statusColor(.approved)
        }
    }
}

private struct Badge: View {
    let text: String
    let color: Color

    var body: some View {
        Text(text)
            .font(.caption2.weight(.semibold))
            .padding(.horizontal, 8)
            .padding(.vertical, 5)
            .background(AppTheme.badgeFill(color), in: Capsule())
            .overlay(
                Capsule()
                    .stroke(AppTheme.badgeStroke(color), lineWidth: 1)
            )
            .foregroundStyle(AppTheme.prominentText(color))
    }
}

private struct FlashcardSemanticBadge {
    let text: String
    let color: Color
}

private func referenceBadges(for card: FlashcardDefinition) -> [FlashcardSemanticBadge] {
    var badges: [FlashcardSemanticBadge] = []

    if card.tags.contains(FlashcardFilterToken.ep.tagValue) {
        badges.append(FlashcardSemanticBadge(text: "EP", color: FlashcardFilterToken.ep.domainColor))
    }

    if card.tags.contains(FlashcardFilterToken.limits.tagValue) {
        badges.append(FlashcardSemanticBadge(text: "Limits", color: FlashcardFilterToken.limits.domainColor))
    }

    if card.tags.contains(FlashcardFilterToken.nwc.tagValue) {
        badges.append(FlashcardSemanticBadge(text: "N/W/C", color: FlashcardFilterToken.nwc.domainColor))
    }

    return badges
}
