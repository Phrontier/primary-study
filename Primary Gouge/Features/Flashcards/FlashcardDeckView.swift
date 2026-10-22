import SwiftUI
import UIKit

struct FlashcardDeckView: View {
    let deck: FlashcardDeck
    let event: Event?
    let contextLabel: String
    let availableFilters: [FlashcardFilterToken]
    let accessRequirement: ContentAccessRequirement

    @EnvironmentObject private var appModel: StudyAppModel
    @State private var selectedFilters: Set<FlashcardFilterToken>

    init(event: Event, deck: FlashcardDeck) {
        self.deck = deck
        self.event = event
        self.contextLabel = event.code
        self.availableFilters = []
        self.accessRequirement = ContentAccessPolicy.requirement(for: event)
        self._selectedFilters = State(initialValue: [])
    }

    init(hub: LibraryStudyHub) {
        self.deck = hub.deck
        self.event = nil
        self.contextLabel = "General Library"
        self.availableFilters = hub.availableFilters
        self.accessRequirement = ContentAccessPolicy.requirement(forLibraryHubID: hub.id)
        self._selectedFilters = State(initialValue: Set(hub.availableFilters))
    }

    private var activeFilters: Set<FlashcardFilterToken> {
        availableFilters.isEmpty ? [] : selectedFilters
    }

    var body: some View {
        PremiumContentGate(requirement: accessRequirement, title: deck.title) {
            deckContent
        }
    }

    private var deckContent: some View {
        let performance = appModel.deckPerformance(for: deck, filters: activeFilters)
        let snapshots = appModel.cardSnapshots(in: deck, filters: activeFilters)

        return PilotPage {
            PilotBackHeader(title: contextLabel)
            StudyHeading(eyebrow: contextLabel, title: displayDeckTitle, subtitle: "Flashcard deck", pill: true)
                .padding(.bottom, 28)
            VStack(alignment: .leading, spacing: 0) {
                HStack(alignment: .center, spacing: 10) {
                    Text("\(performance.totalCount)").pilotText(.stat)
                    Text("cards in this deck").pilotText(.subtitle).foregroundStyle(StudyDesign.secondary)
                    Spacer(minLength: 0)
                    Text("\(performance.segments.first(where: { $0.band == .notStudied })?.count ?? 0) new")
                        .pilotText(.metadata).foregroundStyle(StudyDesign.secondary)
                }.padding(.bottom, 20)
                reviewActionRow
            }
            .padding(.leading, 18)
            .overlay(alignment: .leading) { Rectangle().fill(StudyDesign.blue).frame(width: 3) }
            .padding(.bottom, 30)

            if !availableFilters.isEmpty {
                VStack(alignment: .leading, spacing: 12) {
                    SectionHeader(
                        eyebrow: "Filter",
                        title: "Study Focus",
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
                VStack(alignment: .leading, spacing: 14) {
                    Text("All cards").pilotText(.section).accessibilityAddTraits(.isHeader)

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
        .pilotNavigation()
        .task {
            appModel.recordDeckOpened(event: event, deck: deck, contextLabel: contextLabel)
        }
    }

    private var displayDeckTitle: String {
        deck.title.hasPrefix(contextLabel + " ") ? String(deck.title.dropFirst(contextLabel.count + 1)) : deck.title
    }

    private var reviewActionRow: some View {
        VStack(spacing: 10) {
            smartReviewLink
            fullDeckLink
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
                title: "Smart Review",
                icon: "bolt.fill",
                accent: StudyDesign.action,
                prominent: true
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
                title: "Study Full Deck",
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
        StudyScreen {
            HeroCard(
                eyebrow: contextLabel,
                title: item.card.prompt,
                subtitle: nil
            ) {
                HStack(spacing: 8) {
                    Badge(text: item.band.label, color: item.band.displayColor)

                    ForEach(referenceBadges(for: item.card), id: \.text) { badge in
                        Badge(text: badge.text, color: badge.color)
                    }

                    if item.isPriority {
                        Badge(text: "Smart Review", color: AppTheme.warning)
                    }
                }
            }

            SectionContainer {
                VStack(alignment: .leading, spacing: 12) {
                    Text("Answer")
                        .font(.headline.weight(.semibold))
                        .foregroundStyle(StudyDesign.ink)

                    if let imageRelativePath = item.card.imageRelativePath {
                        FlashcardAssetImage(relativePath: imageRelativePath)
                    }

                    Text(item.card.answer)
                        .font(.body)
                        .foregroundStyle(StudyDesign.secondary)
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
                StudyActionButton(title: "Review This Card", icon: "play.fill", tint: AppTheme.accent)
            }
            .buttonStyle(.plain)
        }
        .detailNavigationChrome(title: "Card Detail")
    }
}

struct FlashcardStudyView: View {
    let event: Event?
    let deck: FlashcardDeck
    let contextLabel: String
    let cards: [FlashcardDefinition]

    @EnvironmentObject private var appModel: StudyAppModel
    @Environment(\.dismiss) private var dismiss
    @Environment(\.dynamicTypeSize) private var dynamicTypeSize

    @State private var currentIndex = 0
    @State private var showingAnswer = false
    @State private var startedAt = Date()
    @State private var didRecordSession = false

    var body: some View {
        Group {
            if cards.isEmpty {
                StudyScreen {
                    EmptyStateCard(
                        icon: "checkmark.circle",
                        title: "No Cards in This Study View",
                        message: "Try a different study mode or turn on more filters to broaden the deck."
                    )
                }
            } else {
                PilotPage {
                    PilotBackHeader(title: contextLabel)
                    header
                    flashcardBody
                    if showingAnswer { ratingBar.padding(.top, 35) }
                }
            }
        }
        .pilotNavigation()
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
        VStack(alignment: .leading, spacing: 14) {
            Text("How well did you know it?")
                .pilotText(.section).accessibilityAddTraits(.isHeader)

            LazyVGrid(columns: Array(repeating: GridItem(.flexible(), spacing: 4),
                                     count: dynamicTypeSize >= .xxxLarge ? 2 : 4), spacing: 4) {
                ForEach(FlashcardRating.allCases, id: \.self) { rating in
                    Button {
                        submit(rating)
                    } label: {
                        Text(rating.label)
                            .pilotText(.grade)
                            .foregroundStyle(ratingStyle(rating).text)
                            .frame(maxWidth: .infinity)
                            .padding(.horizontal, 2).padding(.vertical, 13).frame(minHeight: 44)
                            .background(
                                RoundedRectangle(cornerRadius: 11, style: .continuous)
                                    .fill(ratingStyle(rating).fill)
                                    .overlay(
                                        RoundedRectangle(cornerRadius: 11, style: .continuous)
                                            .stroke(ratingStyle(rating).border, lineWidth: 1)
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

    private func ratingStyle(_ rating: FlashcardRating) -> (text: Color, fill: Color, border: Color) {
        switch rating {
        case .missed: (StudyDesign.color(0xAE304B, 0xFF968E), StudyDesign.color(0xF9E3E9, 0x49303B), StudyDesign.color(0xE9BDC9, 0x875866))
        case .hard: (StudyDesign.color(0x916014, 0xF1CA79), StudyDesign.color(0xF7ECD7, 0x443B2B), StudyDesign.color(0xE7D2AB, 0x85714D))
        case .good: (StudyDesign.blue, StudyDesign.color(0xE2EBFC, 0x263955), StudyDesign.color(0xBFD0F1, 0x4C6992))
        case .easy: (StudyDesign.answerGreen, StudyDesign.greenFill, StudyDesign.color(0xBFDDCD, 0x447A62))
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
                            .foregroundStyle(StudyDesign.secondary)
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
    var prominent = false
    var body: some View {
        HStack(spacing: 10) {
            if !prominent { Image(systemName: "book").font(.system(size: 18)).frame(width: 18, height: 18).accessibilityHidden(true) }
            Text(title).pilotText(.action)
            if prominent { Spacer(); Image(systemName: "arrow.right").font(.system(size: 17)).frame(width: 18, height: 18).accessibilityHidden(true) }
        }
        .foregroundStyle(prominent ? .white : StudyDesign.purple)
        .padding(.horizontal, 15).padding(.vertical, 13)
        .frame(maxWidth: .infinity, minHeight: 46)
        .background(prominent ? StudyDesign.action : StudyDesign.surface, in: RoundedRectangle(cornerRadius: 13))
        .overlay { if !prominent { RoundedRectangle(cornerRadius: 13).strokeBorder(StudyDesign.color(0xDCD8ED, 0x53486F), lineWidth: 1) } }
    }
}

private struct FlashcardStudyHeader: View {
    let contextLabel: String
    let deckTitle: String
    let currentIndex: Int
    let totalCount: Int

    private var sessionTitle: String {
        deckTitle.hasPrefix(contextLabel + " ") ? String(deckTitle.dropFirst(contextLabel.count + 1)) : deckTitle
    }

    private var progressText: String {
        "Card \(currentIndex + 1) of \(totalCount)"
    }

    var body: some View {
        VStack(alignment: .leading, spacing: 15) {
            ViewThatFits(in: .horizontal) {
                HStack(alignment: .center, spacing: 12) {
                    StudyHeading(eyebrow: contextLabel, title: sessionTitle, pill: true, compact: true)
                    Spacer(minLength: 0)
                    Text(progressText).pilotText(.metadata).foregroundStyle(StudyDesign.secondary).fixedSize()
                }
                VStack(alignment: .leading, spacing: 10) {
                    StudyHeading(eyebrow: contextLabel, title: sessionTitle, pill: true, compact: true)
                    Text(progressText).pilotText(.metadata).foregroundStyle(StudyDesign.secondary)
                }
            }
            GeometryReader { geometry in
                Capsule().fill(StudyDesign.cardLine)
                    .overlay(alignment: .leading) {
                        Capsule().fill(StudyDesign.purple).frame(width: geometry.size.width * Double(currentIndex + 1) / Double(max(1, totalCount)))
                    }
            }.frame(height: 5).accessibilityLabel("Study progress").accessibilityValue(progressText)
        }.padding(.bottom, 28)
    }
}

private struct FlashcardStudyCard: View {
    let card: FlashcardDefinition
    let showingAnswer: Bool
    let onTap: () -> Void
    private var stateAccent: Color { showingAnswer ? StudyDesign.answerGreen : StudyDesign.purple }

    var body: some View {
        Button(action: onTap) {
            VStack(alignment: .leading, spacing: 0) {
                faceHeader
                if showingAnswer {
                    VStack(alignment: .leading, spacing: 9) {
                        if let imageRelativePath = card.imageRelativePath { FlashcardAssetImage(relativePath: imageRelativePath) }
                        ForEach(Array(card.answer.components(separatedBy: "\n").enumerated()), id: \.offset) { _, line in
                            Text(line).pilotText(.answer).foregroundStyle(StudyDesign.reading)
                                .frame(maxWidth: .infinity, alignment: .leading)
                        }
                    }.padding(.top, 22)
                    Spacer(minLength: 22)
                } else {
                    Color.clear.frame(height: 22)
                    Spacer(minLength: 0)
                    Text(card.prompt).pilotText(.prompt).foregroundStyle(StudyDesign.ink)
                        .frame(maxWidth: .infinity, alignment: .leading)
                    Color.clear.frame(height: 22)
                    Spacer(minLength: 0)
                    Spacer(minLength: 0)
                }
                HStack(alignment: .bottom, spacing: 14) {
                    Text(showingAnswer ? "Tap the card to hide the answer." : "Tap the card to reveal the answer.")
                        .pilotText(.footer).foregroundStyle(StudyDesign.secondary)
                    Spacer(minLength: 0)
                    Text(showingAnswer ? "Back" : "Front").pilotText(.footer).fontWeight(.semibold).foregroundStyle(stateAccent)
                }
            }
            .padding(.horizontal, 24).padding(.top, 28).padding(.bottom, 24)
            .frame(maxWidth: .infinity, minHeight: 386, alignment: .leading)
            .background(StudyDesign.surface)
            .overlay(RoundedRectangle(cornerRadius: 24).strokeBorder(StudyDesign.cardLine, lineWidth: 1))
            .overlay {
                RoundedRectangle(cornerRadius: 24).strokeBorder(stateAccent, lineWidth: 5)
                    .mask(alignment: .top) { Rectangle().frame(height: 26) }
            }
            .clipShape(RoundedRectangle(cornerRadius: 24))
            .shadow(color: StudyDesign.color(0x25365B, 0x000000).opacity(0.032), radius: 10, y: 8)
            .background { FlashcardDeckStackBackground(accent: stateAccent, showingAnswer: showingAnswer) }
        }
        .buttonStyle(.plain)
        .accessibilityLabel(showingAnswer ? "Answer: \(card.answer)" : "Question: \(card.prompt)")
        .accessibilityHint(showingAnswer ? "Show question" : "Reveal answer")
        .animation(.easeInOut(duration: 0.18), value: showingAnswer)
    }

    private var faceHeader: some View {
        HStack(alignment: .top, spacing: 8) {
            Text(showingAnswer ? "Answer" : "Prompt").pilotText(.metadata).fontWeight(.semibold)
            ForEach(referenceBadges(for: card), id: \.text) { badge in Badge(text: badge.text, color: badge.color) }
            Spacer(minLength: 0)
            Image(systemName: "book").font(.system(size: 18)).accessibilityHidden(true)
        }.foregroundStyle(stateAccent).frame(minHeight: 20)
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
        GeometryReader { proxy in
            RoundedRectangle(cornerRadius: 24)
                .fill(StudyDesign.color(0xEDF0F6, 0x263448))
                .overlay(RoundedRectangle(cornerRadius: 24).strokeBorder(StudyDesign.color(0xDCE2EE, 0x34465D), lineWidth: 1))
                .frame(width: max(0, proxy.size.width - 28), height: max(0, proxy.size.height - 2))
                .offset(x: 14, y: 18)
            RoundedRectangle(cornerRadius: 24)
                .fill(StudyDesign.color(0xE4E8F0, 0x243246))
                .overlay(RoundedRectangle(cornerRadius: 24).strokeBorder(StudyDesign.color(0xDCE2EE, 0x34465D), lineWidth: 1))
                .frame(width: max(0, proxy.size.width - 14), height: max(0, proxy.size.height - 1))
                .offset(x: 7, y: 10)
        }.allowsHitTesting(false).accessibilityHidden(true)
    }
}

private struct FlashcardPreviewCard: View {
    let item: FlashcardListItemSnapshot
    var body: some View {
        VStack(alignment: .leading, spacing: 0) {
            HStack(spacing: 8) {
                Text(item.band.label).pilotText(.state).foregroundStyle(item.band.displayColor)
                ForEach(referenceBadges(for: item.card), id: \.text) { badge in Badge(text: badge.text, color: badge.color) }
            }
            Text(item.card.prompt).pilotText(.preview).foregroundStyle(StudyDesign.ink).padding(.vertical, 8)
            Text(item.card.answer.components(separatedBy: "\n").first ?? item.answerPreview)
                .pilotText(.excerpt).foregroundStyle(StudyDesign.secondary)
        }
        .padding(21).frame(maxWidth: .infinity, alignment: .leading)
        .background(StudyDesign.surface, in: RoundedRectangle(cornerRadius: 24))
        .overlay(RoundedRectangle(cornerRadius: 24).strokeBorder(StudyDesign.cardLine, lineWidth: 1))
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
