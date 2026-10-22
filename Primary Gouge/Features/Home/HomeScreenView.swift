import SwiftUI

struct HomeScreenView: View {
    @EnvironmentObject private var appModel: StudyAppModel
    @EnvironmentObject private var searchChrome: SearchChromeModel
    @EnvironmentObject private var subscriptionStore: SubscriptionStore

    @State private var showingManageFocus = false

    private var displaySnapshot: HomeScreenSnapshot {
        #if DEBUG
        if HomeA1Fixture.isEnabled { return HomeA1Fixture.snapshot(in: appModel) }
        #endif
        return appModel.homeScreenSnapshot
    }

    var body: some View {
        let snapshot = displaySnapshot

        ScrollView {
            VStack(alignment: .leading, spacing: 0) {
                HomeIntroBlock(snapshot: snapshot)

                VStack(spacing: 0) {
                    ContinueStudyingCard(
                        snapshot: snapshot.continueStudying,
                        isPremiumLocked: isPremiumLocked(snapshot.continueStudying.destination)
                    ) { destination in
                        route(to: destination)
                    }

                    if !snapshot.recentDestinations.isEmpty {
                        VStack(spacing: 0) {
                            ForEach(snapshot.recentDestinations) { item in
                                Button { route(to: item.destination) } label: {
                                    HomeRecentRow(item: item)
                                }
                                .buttonStyle(.plain)
                            }
                        }
                    }
                }
                .padding(.top, 18)

                if let question = snapshot.questionOfDay.question {
                    HomeQuestionOfDayCard(
                        snapshot: snapshot.questionOfDay,
                        onSelectChoice: { choiceID in
                            #if DEBUG
                            if HomeA1Fixture.isEnabled { return }
                            #endif
                            appModel.answerQuestionOfDay(question, choiceID: choiceID)
                        }
                    )
                    .padding(.top, 30)
                }

                EmergencyReferenceShortcutCard {
                    route(to: .libraryDeck(id: "emergency-reference-hub"))
                }
                .padding(.top, 26)
            }
            .padding(.horizontal, 22)
            .padding(.top, 18)
            .padding(.bottom, 20)
            .frame(maxWidth: .infinity, alignment: .leading)
        }
        .background(StudyDesign.page.ignoresSafeArea())
        .foregroundStyle(StudyDesign.ink)
        .toolbar(.hidden, for: .navigationBar)
        .sheet(isPresented: $showingManageFocus) {
            FocusTopicManagerSheet(
                selectedTopicIDs: snapshot.currentFocus.pinnedTopics.map(\.id),
                topics: appModel.studyTopics.filter(\.isUserFocusable)
            ) { topicIDs in
                appModel.setPinnedTopicIDs(topicIDs)
            }
        }
        .onAppear {
            searchChrome.updateScope(.home)
        }
    }

    private func route(to destination: SearchDestination?) {
        guard let destination else { return }
        searchChrome.route(to: destination)
    }

    private func isPremiumLocked(_ destination: SearchDestination?) -> Bool {
        guard let destination else { return false }
        return ContentAccessPolicy.isLocked(
            ContentAccessPolicy.requirement(for: destination, in: appModel),
            subscriptionStore: subscriptionStore
        )
    }
}

private struct EmergencyReferenceShortcutCard: View {
    let action: () -> Void
    var body: some View {
        Button(action: action) {
            HStack(spacing: 12) {
                Image(systemName: "exclamationmark.shield")
                    .font(.system(size: 23)).foregroundStyle(StudyDesign.greenInk)
                    .frame(width: 42, height: 42)
                    .background(StudyDesign.color(0xCAE6D7, 0x2D5142), in: RoundedRectangle(cornerRadius: 13))
                VStack(alignment: .leading, spacing: 4) {
                    Text("EPs / Limits / N/W/C").homeText(.referenceTitle).foregroundStyle(StudyDesign.greenInk)
                    Text("Your core memory items, together.").homeText(.referenceCaption)
                        .foregroundStyle(StudyDesign.color(0x4D7360, 0xBDD5C8))
                }.frame(maxWidth: .infinity, alignment: .leading)
                Image(systemName: "arrow.right").font(.system(size: 19)).foregroundStyle(StudyDesign.greenInk)
            }
            .padding(.horizontal, 14).padding(.vertical, 19)
            .background(StudyDesign.greenFill, in: RoundedRectangle(cornerRadius: 20))
            .overlay(RoundedRectangle(cornerRadius: 20).strokeBorder(StudyDesign.color(0xCFE5DA, 0x344F43), lineWidth: 1))
        }.buttonStyle(.plain)
    }
}

private struct HomeIntroBlock: View {
    let snapshot: HomeScreenSnapshot
    @ScaledMetric(relativeTo: .largeTitle) private var numberSize: CGFloat = 34
    @ScaledMetric(relativeTo: .largeTitle) private var numberRow: CGFloat = 38
    @ScaledMetric(relativeTo: .largeTitle) private var flameSize: CGFloat = 42
    @Environment(\.dynamicTypeSize) private var dynamicTypeSize

    var body: some View {
        VStack(alignment: .leading, spacing: 0) {
            Text("Home").homeText(.eyebrow).foregroundStyle(StudyDesign.secondary).padding(.bottom, 9)
                .accessibilityIdentifier("home-eyebrow")
            (Text(snapshot.greeting).foregroundStyle(StudyDesign.ink) + Text(".").foregroundStyle(StudyDesign.blue))
                .homeText(.greeting).padding(.bottom, 12)
                .accessibilityIdentifier("home-greeting")
            if dynamicTypeSize.isAccessibilitySize {
                VStack(alignment: .leading, spacing: 18) {
                    streakMetric
                    metric(value: snapshot.flashcardsReviewedToday, label: "flashcards reviewed today", tint: StudyDesign.secondary, captionWidth: 120)
                }
            } else {
                HStack(alignment: .center, spacing: 16) {
                    streakMetric.frame(maxWidth: .infinity, alignment: .leading)
                    metric(value: snapshot.flashcardsReviewedToday, label: "flashcards reviewed today", tint: StudyDesign.secondary, captionWidth: 120)
                        .padding(.leading, 19)
                        .frame(maxWidth: .infinity, alignment: .leading)
                        .overlay(alignment: .leading) { Rectangle().fill(StudyDesign.line).frame(width: 1) }
                }
                .frame(minHeight: 92)
            }
        }
    }
    private var streakMetric: some View {
        HStack(alignment: .center, spacing: 10) {
            Text("🔥").font(.system(size: flameSize)).frame(width: 42)
                .shadow(color: .orange.opacity(0.12), radius: 9, y: 5).accessibilityHidden(true)
            metric(value: snapshot.studyStreak, label: "day streak", tint: StudyDesign.amberInk)
        }
    }
    private func metric(value: Int, label: String, tint: Color, captionWidth: CGFloat? = nil) -> some View {
        VStack(alignment: .leading, spacing: 5) {
            Text(value.formatted()).font(.system(size: numberSize, weight: .bold)).tracking(-1)
                .frame(height: numberRow, alignment: .leading)
            Text(captionWidth != nil && dynamicTypeSize <= .large ? "flashcards reviewed\ntoday" : label)
                .homeText(.caption).foregroundStyle(tint).accessibilityLabel(label)
                .frame(width: dynamicTypeSize.isAccessibilitySize ? nil : captionWidth, alignment: .leading)
        }
        .frame(height: dynamicTypeSize <= .large ? 72 : nil, alignment: .top)
        .accessibilityElement(children: .combine)
    }
}

private struct ContinueStudyingCard: View {
    let snapshot: HomeContinueStudyingSnapshot
    let isPremiumLocked: Bool
    let onSelect: (SearchDestination?) -> Void

    var body: some View {
        VStack(alignment: .leading, spacing: 13) {
            Text("Continue studying").homeText(.section).accessibilityAddTraits(.isHeader)
            VStack(alignment: .leading, spacing: 0) {
                Text(snapshot.contextLabel ?? "GENERAL LIBRARY").homeText(.code).foregroundStyle(StudyDesign.blue)
                Text(snapshot.displayTitle ?? "Emergency References").homeText(.featured).padding(.vertical, 6)
                Text(snapshot.detail).homeText(.metadata).foregroundStyle(StudyDesign.secondary)
                Button { onSelect(snapshot.destination) } label: {
                    HStack {
                        Text(snapshot.actionTitle).homeText(.action)
                        Spacer(minLength: 0)
                        Image(systemName: isPremiumLocked ? "lock.fill" : "arrow.right")
                            .font(.system(size: 17, weight: .regular))
                    }
                    .foregroundStyle(.white).padding(.vertical, 13).padding(.horizontal, 15)
                    .frame(maxWidth: .infinity, minHeight: 46)
                    .background(StudyDesign.action, in: RoundedRectangle(cornerRadius: 13))
                }
                .buttonStyle(.plain).padding(.top, 20)
            }
            .padding(23).frame(maxWidth: .infinity, alignment: .leading)
            .background(LinearGradient(colors: [StudyDesign.blueFill, StudyDesign.blueEnd],
                startPoint: .topLeading, endPoint: .bottomTrailing), in: RoundedRectangle(cornerRadius: 24))
            .overlay(RoundedRectangle(cornerRadius: 24).strokeBorder(StudyDesign.color(0xD3E1FC, 0x34465D), lineWidth: 1))
            .accessibilityIdentifier("home-featured")
        }
    }
}

private struct CurrentFocusSection: View {
    let snapshot: HomeCurrentFocusSnapshot
    let onManage: () -> Void
    let onSelect: (SearchDestination?) -> Void

    private let columns = [GridItem(.adaptive(minimum: 150), spacing: 10)]
    private let reservedPinnedSlots = 4

    private var placeholderCount: Int {
        max(0, reservedPinnedSlots - snapshot.pinnedTopics.count)
    }

    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            HomeSectionHeader(
                eyebrow: "Focus",
                title: "Current Priorities",
                subtitle: nil
            ) {
                Button("Manage", action: onManage)
                    .font(.footnote.weight(.semibold))
                    .foregroundStyle(AppTheme.accent)
                    .padding(.horizontal, 12)
                    .padding(.vertical, 8)
                    .background(
                        Capsule(style: .continuous)
                            .fill(AppTheme.semanticTint(AppTheme.accent, opacity: 0.12))
                    )
            }

            LazyVGrid(columns: columns, alignment: .leading, spacing: 10) {
                if snapshot.pinnedTopics.isEmpty {
                    ForEach(snapshot.suggestedTopics) { topic in
                        Button {
                            onSelect(topic.destination)
                        } label: {
                            FocusChip(topic: topic, isSuggested: true)
                        }
                        .buttonStyle(.plain)
                    }
                } else {
                    ForEach(snapshot.pinnedTopics) { topic in
                        Button {
                            onSelect(topic.destination)
                        } label: {
                            FocusChip(topic: topic, isSuggested: false)
                        }
                        .buttonStyle(.plain)
                    }

                    ForEach(0..<placeholderCount, id: \.self) { index in
                        Button(action: onManage) {
                            FocusAddCard(index: index)
                        }
                        .buttonStyle(.plain)
                    }
                }
            }
        }
    }
}

private struct FocusChip: View {
    let topic: HomeFocusTopicSnapshot
    let isSuggested: Bool

    var body: some View {
        ZStack(alignment: .topTrailing) {
            HStack(alignment: .center, spacing: 12) {
                ZStack {
                    RoundedRectangle(cornerRadius: 12, style: .continuous)
                        .fill((isSuggested ? AppTheme.textMuted : AppTheme.accent).opacity(0.12))
                        .frame(width: 38, height: 38)

                    Image(systemName: topic.iconName)
                        .font(.subheadline.weight(.semibold))
                        .foregroundStyle(isSuggested ? AppTheme.textSecondary : AppTheme.accent)
                }

                Text(topic.title)
                    .font(.title3.weight(.semibold))
                    .foregroundStyle(AppTheme.textPrimary)
                    .lineLimit(2)
                    .frame(maxWidth: .infinity, alignment: .leading)

                Spacer(minLength: 0)
            }
            .padding(.horizontal, 14)
            .padding(.vertical, 12)
            .frame(maxWidth: .infinity, minHeight: 88, alignment: .leading)
            .background(background)

            if !isSuggested {
                Image(systemName: "pin.fill")
                    .font(.caption2.weight(.bold))
                    .foregroundStyle(AppTheme.accent)
                    .rotationEffect(.degrees(18))
                    .padding(8)
            }
        }
    }

    private var background: some View {
        RoundedRectangle(cornerRadius: AppTheme.Radius.control, style: .continuous)
            .fill(isSuggested ? AppTheme.groupedBackground : AppTheme.raisedSurface)
            .overlay(
                RoundedRectangle(cornerRadius: AppTheme.Radius.control, style: .continuous)
                    .stroke((isSuggested ? AppTheme.cardStroke : AppTheme.accent.opacity(0.18)), lineWidth: 1)
            )
    }
}

private struct FocusAddCard: View {
    let index: Int

    var body: some View {
        ZStack {
            RoundedRectangle(cornerRadius: AppTheme.Radius.control, style: .continuous)
                .fill(AppTheme.groupedBackground.opacity(0.36))
                .overlay(
                    RoundedRectangle(cornerRadius: AppTheme.Radius.control, style: .continuous)
                        .stroke(AppTheme.cardStroke.opacity(0.75), style: StrokeStyle(lineWidth: 1, dash: [7, 5]))
                )

            Image(systemName: "plus")
                .font(.title3.weight(.semibold))
                .foregroundStyle(AppTheme.textMuted)
        }
        .frame(maxWidth: .infinity, minHeight: 88)
        .accessibilityLabel("Add pinned focus topic \(index + 1)")
    }
}

private struct ReviewDueSection: View {
    let title: String
    let subtitle: String?
    let items: [HomeTopicActionSnapshot]
    let emptyMessage: String
    let onSelect: (SearchDestination?) -> Void

    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            HomeSectionHeader(eyebrow: "Study next", title: title, subtitle: subtitle)

            VStack(alignment: .leading, spacing: 10) {
                if items.isEmpty {
                    CompactEmptyState(message: emptyMessage)
                } else {
                    ForEach(items) { item in
                        TopicActionRow(item: item, showsDetail: true) {
                            onSelect(item.destination)
                        }
                    }
                }
            }
        }
    }
}

private struct WeakAreasSection: View {
    let title: String
    let subtitle: String?
    let items: [HomeTopicActionSnapshot]
    let emptyMessage: String
    let onSelect: (SearchDestination?) -> Void

    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            HomeSectionHeader(eyebrow: "Study next", title: title, subtitle: subtitle)

            VStack(alignment: .leading, spacing: 10) {
                if items.isEmpty {
                    CompactEmptyState(message: emptyMessage)
                } else {
                    ForEach(items) { item in
                        TopicActionRow(item: item, showsDetail: false) {
                            onSelect(item.destination)
                        }
                    }
                }
            }
        }
    }
}

private struct TopicActionRow: View {
    let item: HomeTopicActionSnapshot
    let showsDetail: Bool
    let action: () -> Void

    var body: some View {
        Button(action: action) {
            InsetListRow(title: item.title, subtitle: showsDetail ? item.detail : nil) {
                ZStack {
                    RoundedRectangle(cornerRadius: 14, style: .continuous)
                        .fill(accentColor.opacity(0.12))
                        .frame(width: 40, height: 40)

                    Image(systemName: item.iconName)
                        .font(.subheadline.weight(.semibold))
                        .foregroundStyle(accentColor)
                }
            } trailing: {
                HStack(spacing: 4) {
                    Text(item.actionTitle)
                    Image(systemName: "chevron.right")
                        .font(.caption.weight(.bold))
                }
                .font(.footnote.weight(.semibold))
                .foregroundStyle(accentColor)
                .padding(.horizontal, 10)
                .padding(.vertical, 8)
                .background(
                    Capsule()
                        .fill(accentColor.opacity(0.12))
                )
            }
        }
        .buttonStyle(.plain)
        .fixedSize(horizontal: false, vertical: true)
    }

    private var accentColor: Color {
        if let ratingColor = item.ratingColor {
            switch ratingColor {
            case .missed:
                return AppTheme.danger
            case .hard:
                return AppTheme.warning
            case .good:
                return AppTheme.accent
            case .easy:
                return AppTheme.success
            }
        }

        switch item.urgency {
        case .neutral:
            return AppTheme.accent
        case .warning:
            return AppTheme.warning
        case .alert:
            return AppTheme.danger
        }
    }
}

private struct HomeQuestionOfDayCard: View {
    let snapshot: HomeQuestionOfDaySnapshot
    let onSelectChoice: (String) -> Void

    var body: some View {
        VStack(alignment: .leading, spacing: 14) {
            HStack {
                Text("Question of the day").homeText(.section).accessibilityAddTraits(.isHeader)
                Spacer()
                Circle().fill(StudyDesign.amberInk).frame(width: 8, height: 8).accessibilityHidden(true)
            }

            StudySurface {
                VStack(alignment: .leading, spacing: 18) {
                    if let question = snapshot.question {
                        Text(question.prompt)
                            .homeText(.question)
                            .foregroundStyle(StudyDesign.ink)

                        VStack(spacing: 8) {
                            ForEach(question.choices) { choice in
                                HomeQuestionChoice(
                                    label: choice.text,
                                    badge: QuizChoicePresentation.badgeText(for: choice, format: choiceFormat(for: question)),
                                    state: answerState(for: choice.id, question: question),
                                    isAnswered: snapshot.isAnswered
                                ) { onSelectChoice(choice.id) }

                            }
                        }
                    }
                }
            }
        }
    }

    private func choiceFormat(for question: HomeQuestionDefinition) -> QuizQuestionFormat {
        question.choices.count == 2 ? .trueFalse : .multipleChoice
    }

    private func answerState(for choiceID: String, question: HomeQuestionDefinition) -> QuizAnswerVisualState {
        guard let selectedChoiceID = snapshot.selectedChoiceID else { return .idle }

        if choiceID == question.correctChoiceID {
            return snapshot.wasCorrect == true ? .correct : .correctReveal
        }

        if choiceID == selectedChoiceID {
            return .incorrect
        }

        return .subdued
    }
}

private struct HomeQuestionChoice: View {
    let label: String
    let badge: String?
    let state: QuizAnswerVisualState
    let isAnswered: Bool
    let action: () -> Void

    private var resultColor: Color {
        switch state {
        case .correct, .correctReveal: AppTheme.success
        case .incorrect: AppTheme.danger
        default: StudyDesign.blue
        }
    }
    private var resultLabel: String {
        switch state {
        case .correct, .correctReveal: "Correct answer"
        case .incorrect: "Incorrect answer"
        default: ""
        }
    }
    var body: some View {
        Button(action: action) {
            HStack(alignment: .center, spacing: 11) {
                if let badge {
                    Text(badge).homeText(.badge).foregroundStyle(StudyDesign.secondary)
                        .frame(minWidth: 22, minHeight: 22)
                        .background(StudyDesign.color(0xE9EDF3, 0x2D3B50), in: RoundedRectangle(cornerRadius: 7))
                }
                Text(label).homeText(.choice).foregroundStyle(StudyDesign.ink)
                    .fixedSize(horizontal: false, vertical: true)
                Spacer(minLength: 0)
                if !resultLabel.isEmpty {
                    Image(systemName: state == .incorrect ? "xmark.circle.fill" : "checkmark.circle.fill")
                        .foregroundStyle(resultColor).accessibilityHidden(true)
                }
            }
            .padding(.horizontal, 12).padding(.vertical, 12)
            .frame(maxWidth: .infinity, minHeight: 46, alignment: .leading)
            .background(resultLabel.isEmpty ? StudyDesign.color(0xF5F7FA, 0x253244) : resultColor.opacity(0.12),
                        in: RoundedRectangle(cornerRadius: 12))
            .overlay(RoundedRectangle(cornerRadius: 12).strokeBorder(StudyDesign.color(0xE5EAF1, 0x34465D), lineWidth: 1))
        }
        .buttonStyle(.plain).disabled(isAnswered)
        .accessibilityValue(resultLabel)
    }
}

private struct HomeSignalPill: View {
    let title: String
    let iconName: String
    let color: Color

    var body: some View {
        HStack(spacing: 8) {
            ZStack {
                Circle()
                    .fill(color.opacity(0.16))
                    .frame(width: 22, height: 22)

                Image(systemName: iconName)
                    .font(.caption.weight(.bold))
            }

            Text(title)
                .lineLimit(1)
                .minimumScaleFactor(0.9)
        }
        .font(.caption.weight(.semibold))
        .foregroundStyle(color)
        .padding(.horizontal, 12)
        .padding(.vertical, 8)
        .background(
            Capsule(style: .continuous)
                .fill(
                    LinearGradient(
                        colors: [
                            color.opacity(0.16),
                            color.opacity(0.08)
                        ],
                        startPoint: .topLeading,
                        endPoint: .bottomTrailing
                    )
                )
                .overlay(
                    Capsule(style: .continuous)
                        .stroke(color.opacity(0.18), lineWidth: 1)
                )
        )
        .shadow(color: color.opacity(0.10), radius: 10, x: 0, y: 6)
    }
}

private struct HomeSectionHeader<Trailing: View>: View {
    let eyebrow: String
    let title: String
    let subtitle: String?
    @ViewBuilder let trailing: Trailing

    init(
        eyebrow: String,
        title: String,
        subtitle: String? = nil,
        @ViewBuilder trailing: () -> Trailing = { EmptyView() }
    ) {
        self.eyebrow = eyebrow
        self.title = title
        self.subtitle = subtitle
        self.trailing = trailing()
    }

    var body: some View {
        HStack(alignment: .top, spacing: 12) {
            VStack(alignment: .leading, spacing: subtitle == nil ? 3 : 6) {
                Text(eyebrow.uppercased())
                    .font(.caption.weight(.semibold))
                    .foregroundStyle(AppTheme.accent)
                    .tracking(0.6)

                Text(title)
                    .font((subtitle == nil ? Font.title2 : .title3).weight(.semibold))
                    .foregroundStyle(AppTheme.textPrimary)

                if let subtitle, !subtitle.isEmpty {
                    Text(subtitle)
                        .font(.footnote)
                        .foregroundStyle(AppTheme.textSecondary)
                        .fixedSize(horizontal: false, vertical: true)
                }
            }

            Spacer(minLength: 12)

            trailing
        }
    }
}

private struct CompactEmptyState: View {
    let message: String

    var body: some View {
        Text(message)
            .font(.footnote)
            .foregroundStyle(AppTheme.textSecondary)
            .padding(.horizontal, 16)
            .padding(.vertical, 14)
            .frame(maxWidth: .infinity, alignment: .leading)
            .background(
                RoundedRectangle(cornerRadius: AppTheme.Radius.control, style: .continuous)
                    .fill(AppTheme.groupedBackground)
                    .overlay(
                        RoundedRectangle(cornerRadius: AppTheme.Radius.control, style: .continuous)
                            .stroke(AppTheme.cardStroke, lineWidth: 1)
                    )
            )
    }
}

struct FocusTopicManagerSheet: View {
    let topics: [StudyTopicDefinition]
    let onSave: ([String]) -> Void

    @Environment(\.dismiss) private var dismiss
    @State private var selectedTopicIDs: [String]

    init(selectedTopicIDs: [String], topics: [StudyTopicDefinition], onSave: @escaping ([String]) -> Void) {
        self.topics = topics
        self.onSave = onSave
        _selectedTopicIDs = State(initialValue: selectedTopicIDs)
    }

    var body: some View {
        NavigationStack {
            List {
                Section("Pinned") {
                    if selectedTopicIDs.isEmpty {
                        Text("Choose a few focus areas to keep them on Home.")
                            .foregroundStyle(.secondary)
                    } else {
                        ForEach(selectedTopicIDs, id: \.self) { topicID in
                            if let topic = topics.first(where: { $0.id == topicID }) {
                                Label(topic.title, systemImage: topic.iconName)
                            }
                        }
                        .onMove(perform: movePinnedTopics)
                    }
                }

                Section("Available") {
                    ForEach(topics, id: \.id) { topic in
                        Button {
                            toggle(topic.id)
                        } label: {
                            HStack {
                                Label(topic.title, systemImage: topic.iconName)
                                    .foregroundStyle(.primary)

                                Spacer()

                                if selectedTopicIDs.contains(topic.id) {
                                    Image(systemName: "checkmark.circle.fill")
                                        .foregroundStyle(AppTheme.accent)
                                }
                            }
                        }
                    }
                }
            }
            .scrollContentBackground(.hidden)
            .background(AppTheme.screenBackground.ignoresSafeArea())
            .detailNavigationChrome(title: "Current Focus")
            .toolbar {
                ToolbarItem(placement: .topBarLeading) {
                    Button("Cancel") {
                        dismiss()
                    }
                }
                ToolbarItem(placement: .topBarTrailing) {
                    EditButton()
                }
                ToolbarItem(placement: .confirmationAction) {
                    Button("Save") {
                        onSave(selectedTopicIDs)
                        dismiss()
                    }
                }
            }
        }
    }

    private func toggle(_ topicID: String) {
        if let index = selectedTopicIDs.firstIndex(of: topicID) {
            selectedTopicIDs.remove(at: index)
        } else {
            selectedTopicIDs.append(topicID)
        }
    }

    private func movePinnedTopics(from source: IndexSet, to destination: Int) {
        selectedTopicIDs.move(fromOffsets: source, toOffset: destination)
    }
}
