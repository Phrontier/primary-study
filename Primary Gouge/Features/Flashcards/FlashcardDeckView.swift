import SwiftUI
import UIKit

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
        .detailNavigationChrome(title: deck.title)
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

                    if let imageRelativePath = item.card.imageRelativePath {
                        FlashcardAssetImage(relativePath: imageRelativePath)
                    }

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
        .detailNavigationChrome(title: "Card detail")
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
        .detailNavigationChrome(title: deck.title)
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
        FlashcardStudyHeader(
            contextLabel: contextLabel,
            deckTitle: deck.title,
            currentIndex: currentIndex,
            totalCount: cards.count
        )
    }

    private var flashcardBody: some View {
        FlashcardStudyCard(
            card: cards[currentIndex],
            showingAnswer: showingAnswer,
            onTap: toggleAnswerVisibility
        )
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

    private func toggleAnswerVisibility() {
        withAnimation(.easeInOut(duration: 0.18)) {
            showingAnswer.toggle()
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

private struct FlashcardStudyHeader: View {
    let contextLabel: String
    let deckTitle: String
    let currentIndex: Int
    let totalCount: Int

    private var progressText: String {
        "Card \(currentIndex + 1) of \(totalCount)"
    }

    var body: some View {
        SectionContainer(style: .metric, accent: AppTheme.domainColor(.flashcards), contentPadding: 18) {
            VStack(alignment: .leading, spacing: 14) {
                HStack(alignment: .top, spacing: 12) {
                    VStack(alignment: .leading, spacing: 6) {
                        Text(contextLabel.uppercased())
                            .font(.caption.weight(.semibold))
                            .foregroundStyle(AppTheme.domainColor(.flashcards))
                            .tracking(0.6)

                        Text(deckTitle)
                            .font(.title3.weight(.bold))
                            .foregroundStyle(AppTheme.textPrimary)
                            .fixedSize(horizontal: false, vertical: true)
                    }

                    Spacer(minLength: 0)

                    Text(progressText)
                        .font(.footnote.weight(.semibold))
                        .foregroundStyle(AppTheme.prominentText(AppTheme.domainColor(.flashcards)))
                        .padding(.horizontal, 12)
                        .padding(.vertical, 8)
                        .background(AppTheme.badgeFill(AppTheme.domainColor(.flashcards)), in: Capsule())
                        .overlay(
                            Capsule()
                                .stroke(AppTheme.badgeStroke(AppTheme.domainColor(.flashcards)), lineWidth: 1)
                        )
                }

                ProgressStrip(
                    value: Double(currentIndex + 1),
                    total: Double(totalCount),
                    tint: AppTheme.domainColor(.flashcards)
                )
            }
        }
    }
}

private struct FlashcardStudyCard: View {
    let card: FlashcardDefinition
    let showingAnswer: Bool
    let onTap: () -> Void

    private var stateAccent: Color {
        showingAnswer ? AppTheme.success : AppTheme.domainColor(.flashcards)
    }

    private var instructionText: String {
        showingAnswer ? "Tap the card again to hide the answer." : "Tap anywhere on the card to reveal the answer."
    }

    var body: some View {
        ZStack {
            FlashcardDeckStackBackground(accent: stateAccent, showingAnswer: showingAnswer)

            Button(action: onTap) {
                VStack(alignment: .leading, spacing: 20) {
                    HStack(alignment: .center, spacing: 8) {
                        Text(showingAnswer ? "Answer" : "Prompt")
                            .font(.caption.weight(.semibold))
                            .foregroundStyle(stateAccent)

                        ForEach(referenceBadges(for: card), id: \.text) { badge in
                            Badge(text: badge.text, color: badge.color)
                        }

                        Spacer(minLength: 0)

                        Image(systemName: showingAnswer ? "arrow.uturn.backward.circle.fill" : "hand.tap.fill")
                            .font(.system(size: 18, weight: .semibold))
                            .foregroundStyle(stateAccent.opacity(0.92))
                    }

                    Spacer(minLength: 0)

                    if showingAnswer, let imageRelativePath = card.imageRelativePath {
                        FlashcardAssetImage(relativePath: imageRelativePath)
                    }

                    Text(showingAnswer ? card.answer : card.prompt)
                        .font(showingAnswer ? .body : .system(size: 32, weight: .bold, design: .rounded))
                        .foregroundStyle(showingAnswer ? AppTheme.textSecondary : AppTheme.textPrimary)
                        .frame(maxWidth: .infinity, alignment: .leading)
                        .fixedSize(horizontal: false, vertical: true)

                    Spacer(minLength: 0)

                    HStack(alignment: .bottom, spacing: 12) {
                        Text(instructionText)
                            .font(.footnote)
                            .foregroundStyle(AppTheme.textSecondary)
                            .fixedSize(horizontal: false, vertical: true)

                        Spacer(minLength: 0)

                        Text(showingAnswer ? "Back" : "Front")
                            .font(.caption2.weight(.bold))
                            .foregroundStyle(AppTheme.prominentText(stateAccent))
                            .tracking(0.5)
                            .padding(.horizontal, 10)
                            .padding(.vertical, 6)
                            .background(AppTheme.badgeFill(stateAccent), in: Capsule())
                            .overlay(
                                Capsule()
                                    .stroke(AppTheme.badgeStroke(stateAccent), lineWidth: 1)
                            )
                    }
                }
                .padding(24)
                .frame(maxWidth: .infinity, minHeight: 340, alignment: .leading)
                .background(
                    AppTheme.cardBackground(
                        style: showingAnswer ? .hero : .primary,
                        accent: stateAccent
                    )
                )
                .overlay(
                    RoundedRectangle(cornerRadius: AppTheme.Radius.largeCard, style: .continuous)
                        .strokeBorder(stateAccent.opacity(showingAnswer ? 0.28 : 0.18), lineWidth: 1)
                )
            }
            .buttonStyle(.plain)
        }
        .padding(.horizontal, 4)
        .padding(.vertical, 8)
        .animation(.easeInOut(duration: 0.18), value: showingAnswer)
    }
}

private struct FlashcardAssetImage: View {
    let relativePath: String

    private let repository = ContentRepository()

    var body: some View {
        Group {
            if let url = repository.fileURL(for: relativePath),
               let image = UIImage(contentsOfFile: url.path) {
                Image(uiImage: image)
                    .resizable()
                    .scaledToFit()
                    .frame(maxWidth: .infinity)
                    .clipShape(RoundedRectangle(cornerRadius: 18, style: .continuous))
                    .overlay(
                        RoundedRectangle(cornerRadius: 18, style: .continuous)
                            .stroke(AppTheme.cardStroke.opacity(0.8), lineWidth: 1)
                    )
            }
        }
    }
}

private struct FlashcardDeckStackBackground: View {
    let accent: Color
    let showingAnswer: Bool

    var body: some View {
        ZStack {
            stackLayer(
                opacity: 0.28,
                scale: 0.97,
                yOffset: 24,
                extraAccentOpacity: 0.03
            )

            stackLayer(
                opacity: 0.42,
                scale: 0.985,
                yOffset: 12,
                extraAccentOpacity: 0.05
            )
        }
        .padding(.horizontal, 10)
    }

    private func stackLayer(opacity: Double, scale: CGFloat, yOffset: CGFloat, extraAccentOpacity: Double) -> some View {
        RoundedRectangle(cornerRadius: AppTheme.Radius.largeCard, style: .continuous)
            .fill(
                LinearGradient(
                    colors: [
                        AppTheme.groupedBackground.opacity(0.98),
                        accent.opacity(extraAccentOpacity),
                        AppTheme.sunkenSurface.opacity(0.98)
                    ],
                    startPoint: .topLeading,
                    endPoint: .bottomTrailing
                )
            )
            .overlay(
                RoundedRectangle(cornerRadius: AppTheme.Radius.largeCard, style: .continuous)
                    .stroke(AppTheme.cardStroke.opacity(opacity), lineWidth: 1)
            )
            .scaleEffect(scale)
            .offset(y: yOffset)
            .shadow(
                color: Color.black.opacity(showingAnswer ? 0.2 : 0.14),
                radius: 18,
                x: 0,
                y: 12
            )
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
