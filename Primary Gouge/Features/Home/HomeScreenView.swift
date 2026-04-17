import SwiftUI

struct HomeScreenView: View {
    @EnvironmentObject private var appModel: StudyAppModel
    @EnvironmentObject private var searchChrome: SearchChromeModel

    @State private var showingManageFocus = false

    var body: some View {
        let snapshot = appModel.homeScreenSnapshot

        AppScrollScreen(topPadding: AppTheme.Spacing.rootTabIntroTop, bottomPadding: 28) {
            HomeIntroBlock(snapshot: snapshot)

            ContinueStudyingCard(snapshot: snapshot.continueStudying) { destination in
                route(to: destination)
            }

            CurrentFocusSection(
                snapshot: snapshot.currentFocus,
                onManage: { showingManageFocus = true },
                onSelect: route(to:)
            )

            ReviewDueSection(
                title: "Review due",
                subtitle: nil,
                items: snapshot.reviewDue,
                emptyMessage: "Nothing is aging out right now.",
                onSelect: route(to:)
            )

            WeakAreasSection(
                title: "Weak areas",
                subtitle: nil,
                items: snapshot.weakAreas,
                emptyMessage: "No weak areas are standing out yet.",
                onSelect: route(to:)
            )

            if let question = snapshot.questionOfDay.question {
                HomeQuestionOfDayCard(
                    snapshot: snapshot.questionOfDay,
                    onSelectChoice: { choiceID in
                        appModel.answerQuestionOfDay(question, choiceID: choiceID)
                    }
                )
            }
        }
        .sheet(isPresented: $showingManageFocus) {
            FocusTopicManagerSheet(
                selectedTopicIDs: snapshot.currentFocus.pinnedTopics.map(\.id),
                topics: appModel.studyTopics.filter(\.isUserFocusable)
            ) { topicIDs in
                appModel.setPinnedTopicIDs(topicIDs)
            }
        }
        .rootNavigationChrome(title: "Home")
        .onAppear {
            searchChrome.updateScope(.home)
        }
    }

    private func route(to destination: SearchDestination?) {
        guard let destination else { return }
        searchChrome.route(to: destination)
    }
}

private struct HomeIntroBlock: View {
    let snapshot: HomeScreenSnapshot

    var body: some View {
        VStack(alignment: .leading, spacing: 10) {
            Text("\(snapshot.greeting), \(snapshot.personalizedLine.lowercasedFirstLetter)")
                .font(.title2.weight(.bold))
            .foregroundStyle(AppTheme.textPrimary)
            .fixedSize(horizontal: false, vertical: true)

            if snapshot.studyStreak > 0 {
                HomeSignalPill(
                    title: "\(snapshot.studyStreak)-day streak",
                    iconName: "flame.fill",
                    color: AppTheme.warning
                )
                .fixedSize(horizontal: false, vertical: true)
            }
        }
    }
}

private extension String {
    var lowercasedFirstLetter: String {
        guard let first else { return self }
        return first.lowercased() + dropFirst()
    }
}

private struct ContinueStudyingCard: View {
    let snapshot: HomeContinueStudyingSnapshot
    let onSelect: (SearchDestination?) -> Void

    var body: some View {
        SectionContainer(style: .primary, accent: AppTheme.accent, contentPadding: 18) {
            VStack(alignment: .leading, spacing: 14) {
                VStack(alignment: .leading, spacing: 8) {
                    Text("CONTINUE STUDYING")
                        .font(.caption.weight(.semibold))
                        .foregroundStyle(AppTheme.accent)
                        .tracking(0.7)

                    Text(snapshot.title)
                        .font(.title3.weight(.semibold))
                        .foregroundStyle(AppTheme.textPrimary)
                        .fixedSize(horizontal: false, vertical: true)

                    Text(snapshot.subtitle)
                        .font(.subheadline)
                        .foregroundStyle(AppTheme.textSecondary)
                        .fixedSize(horizontal: false, vertical: true)
                }

                Text(snapshot.detail)
                    .font(.footnote)
                    .foregroundStyle(AppTheme.textSecondary)
                    .fixedSize(horizontal: false, vertical: true)

                Button {
                    onSelect(snapshot.destination)
                } label: {
                    StudyActionButton(
                        title: snapshot.actionTitle,
                        icon: snapshot.isFallback ? "arrow.right.circle.fill" : "play.fill",
                        tint: AppTheme.accent
                    )
                }
                .buttonStyle(.plain)
            }
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
                title: "Current priorities",
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
            Button(action: action) {
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
        VStack(alignment: .leading, spacing: 12) {
            HomeSectionHeader(
                eyebrow: "Daily rep",
                title: "Question of the day",
                subtitle: nil
            )

            SectionContainer(contentPadding: 16) {
                VStack(alignment: .leading, spacing: 16) {
                    if let question = snapshot.question {
                        Text(question.prompt)
                            .font(.title3.weight(.semibold))
                            .foregroundStyle(AppTheme.textPrimary)

                        VStack(spacing: 10) {
                            ForEach(question.choices) { choice in
                                QuizAnswerButton(
                                    label: choice.text,
                                    badge: QuizChoicePresentation.badgeText(for: choice, format: choiceFormat(for: question)),
                                    state: answerState(for: choice.id, question: question),
                                    isInteractive: !snapshot.isAnswered,
                                    fixedHeight: 72
                                ) {
                                    onSelectChoice(choice.id)
                                }
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
