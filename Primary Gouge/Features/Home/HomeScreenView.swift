import SwiftUI

struct HomeScreenView: View {
    @EnvironmentObject private var appModel: StudyAppModel
    @EnvironmentObject private var searchChrome: SearchChromeModel

    @State private var showingManageFocus = false

    var body: some View {
        AppScrollScreen(topPadding: 14, bottomPadding: 42) {
            HomeHeaderView(snapshot: appModel.homeScreenSnapshot)

            ContinueStudyingCard(snapshot: appModel.homeScreenSnapshot.continueStudying) { destination in
                route(to: destination)
            }

            CurrentFocusSection(
                snapshot: appModel.homeScreenSnapshot.currentFocus,
                onManage: { showingManageFocus = true },
                onSelect: route(to:)
            )

            ReviewDueSection(
                title: "Review Due",
                subtitle: "Cards and topics that are old enough to deserve attention now.",
                items: appModel.homeScreenSnapshot.reviewDue,
                emptyMessage: "Nothing is aging out right now.",
                onSelect: route(to:)
            )

            WeakAreasSection(
                title: "Weak Areas",
                subtitle: "Performance-based signals that show where another pass will pay off fastest.",
                items: appModel.homeScreenSnapshot.weakAreas,
                emptyMessage: "No weak areas are standing out yet.",
                onSelect: route(to:)
            )

            if let question = appModel.homeScreenSnapshot.questionOfDay.question {
                HomeQuestionOfDayCard(
                    snapshot: appModel.homeScreenSnapshot.questionOfDay,
                    onSelectChoice: { choiceID in
                        appModel.answerQuestionOfDay(question, choiceID: choiceID)
                    }
                )
            }
        }
        .sheet(isPresented: $showingManageFocus) {
            ManageFocusSheet(
                selectedTopicIDs: appModel.homeScreenSnapshot.currentFocus.pinnedTopics.map(\.id),
                topics: appModel.studyTopics.filter(\.isUserFocusable)
            ) { topicIDs in
                appModel.setPinnedTopicIDs(topicIDs)
            }
        }
        .navigationTitle("Home")
        .navigationBarTitleDisplayMode(.large)
        .onAppear {
            searchChrome.updateScope(.home)
        }
    }

    private func route(to destination: SearchDestination?) {
        guard let destination else { return }
        searchChrome.route(to: destination)
    }
}

private struct HomeHeaderView: View {
    let snapshot: HomeScreenSnapshot

    var body: some View {
        SectionContainer(style: .hero, accent: AppTheme.accent, contentPadding: 24) {
            VStack(alignment: .leading, spacing: 20) {
                HStack(alignment: .top, spacing: 12) {
                    VStack(alignment: .leading, spacing: 10) {
                        Text(snapshot.greeting.uppercased())
                            .font(.caption.weight(.semibold))
                            .foregroundStyle(AppTheme.accent)
                            .tracking(0.6)

                        Text("Your training dashboard")
                            .font(.system(size: 30, weight: .bold))
                            .foregroundStyle(AppTheme.textPrimary)
                            .fixedSize(horizontal: false, vertical: true)

                        Text(snapshot.statusLine)
                            .font(.subheadline.weight(.medium))
                            .foregroundStyle(AppTheme.textSecondary)
                    }

                    Spacer(minLength: 8)

                    StatusBadge(
                        title: snapshot.reviewDue.isEmpty ? "On schedule" : "\(snapshot.reviewDue.count) due now",
                        iconName: snapshot.reviewDue.isEmpty ? "checkmark.circle.fill" : "clock.fill",
                        color: snapshot.reviewDue.isEmpty ? AppTheme.success : AppTheme.warning
                    )
                }

                HStack(spacing: 12) {
                    MetricChip(label: "Streak", value: "\(max(snapshot.studyStreak, 0)) days", color: AppTheme.accent, iconName: "flame.fill")
                    MetricChip(label: "Review Due", value: "\(snapshot.reviewDue.count)", color: snapshot.reviewDue.isEmpty ? AppTheme.success : AppTheme.warning, iconName: "clock.fill")
                    MetricChip(label: "Weak Areas", value: "\(snapshot.weakAreas.count)", color: snapshot.weakAreas.isEmpty ? AppTheme.success : AppTheme.danger, iconName: "scope")
                }
            }
        }
    }
}

private struct ContinueStudyingCard: View {
    let snapshot: HomeContinueStudyingSnapshot
    let onSelect: (SearchDestination?) -> Void

    var body: some View {
        SectionContainer(style: .primary, accent: AppTheme.accent, contentPadding: 22) {
            VStack(alignment: .leading, spacing: 18) {
                HStack(alignment: .top, spacing: 14) {
                    ZStack {
                        RoundedRectangle(cornerRadius: 16, style: .continuous)
                            .fill(AppTheme.accent.opacity(0.10))
                            .frame(width: 50, height: 50)

                        Image(systemName: snapshot.isFallback ? "safari.fill" : "play.fill")
                            .font(.headline.weight(.bold))
                            .foregroundStyle(AppTheme.accent)
                    }

                    VStack(alignment: .leading, spacing: 7) {
                        Text("Continue studying")
                            .font(.caption.weight(.semibold))
                            .foregroundStyle(AppTheme.accent)
                            .tracking(0.6)

                        Text(snapshot.title)
                            .font(.title3.weight(.bold))
                            .foregroundStyle(AppTheme.textPrimary)

                        Text(snapshot.subtitle)
                            .font(.subheadline.weight(.medium))
                            .foregroundStyle(AppTheme.textSecondary)
                    }

                    Spacer()

                    StatusBadge(
                        title: snapshot.isFallback ? "Suggested" : "Resume",
                        iconName: snapshot.isFallback ? "sparkles" : "arrow.clockwise",
                        color: AppTheme.accent
                    )
                }

                Text(snapshot.detail)
                    .font(.footnote)
                    .foregroundStyle(AppTheme.textSecondary)

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

    private let columns = [GridItem(.adaptive(minimum: 140), spacing: 12)]

    var body: some View {
        VStack(alignment: .leading, spacing: 14) {
            HStack(alignment: .top) {
                SectionHeader(
                    eyebrow: "Focus",
                    title: "Current priorities",
                    subtitle: snapshot.pinnedTopics.isEmpty
                        ? "Pin the areas you want living on Home."
                        : "Keep your current study priorities one tap away."
                )

                Spacer(minLength: 12)

                Button("Manage", action: onManage)
                    .font(.subheadline.weight(.semibold))
                    .foregroundStyle(AppTheme.accent)
                    .padding(.top, 2)
            }

            SectionContainer {
                LazyVGrid(columns: columns, alignment: .leading, spacing: 12) {
                    ForEach(snapshot.pinnedTopics.isEmpty ? snapshot.suggestedTopics : snapshot.pinnedTopics) { topic in
                        Button {
                            onSelect(topic.destination)
                        } label: {
                            FocusChip(topic: topic, isSuggested: snapshot.pinnedTopics.isEmpty)
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
        VStack(alignment: .leading, spacing: 10) {
            Image(systemName: topic.iconName)
                .font(.headline.weight(.semibold))
                .foregroundStyle(isSuggested ? AppTheme.textSecondary : AppTheme.accent)

            Text(topic.title)
                .font(.subheadline.weight(.semibold))
                .foregroundStyle(AppTheme.textPrimary)
                .lineLimit(2)

            Text(isSuggested ? "Suggested" : "Pinned")
                .font(.caption.weight(.semibold))
                .foregroundStyle(isSuggested ? AppTheme.textMuted : AppTheme.accent)
        }
        .padding(14)
        .frame(maxWidth: .infinity, minHeight: 104, alignment: .leading)
        .background(
            RoundedRectangle(cornerRadius: AppTheme.Radius.control, style: .continuous)
                .fill(
                    LinearGradient(
                        colors: [
                            AppTheme.elevatedSurface,
                            (isSuggested ? AppTheme.surface : AppTheme.accent.opacity(0.04))
                        ],
                        startPoint: .topLeading,
                        endPoint: .bottomTrailing
                    )
                )
                .overlay(
                    RoundedRectangle(cornerRadius: AppTheme.Radius.control, style: .continuous)
                        .stroke((isSuggested ? AppTheme.cardStroke : AppTheme.accent.opacity(0.14)), lineWidth: 1)
                )
        )
    }
}

private struct ReviewDueSection: View {
    let title: String
    let subtitle: String
    let items: [HomeTopicActionSnapshot]
    let emptyMessage: String
    let onSelect: (SearchDestination?) -> Void

    var body: some View {
        VStack(alignment: .leading, spacing: 14) {
            SectionHeader(eyebrow: "Study next", title: title, subtitle: subtitle)

            SectionContainer {
                VStack(alignment: .leading, spacing: 12) {
                    if items.isEmpty {
                        Text(emptyMessage)
                            .font(.footnote)
                            .foregroundStyle(AppTheme.textSecondary)
                    } else {
                        ForEach(Array(items.enumerated()), id: \.element.id) { index, item in
                            TopicActionRow(item: item) {
                                onSelect(item.destination)
                            }

                            if index < items.count - 1 {
                                Divider()
                                    .overlay(AppTheme.cardStroke.opacity(0.9))
                                    .padding(.leading, 54)
                            }
                        }
                    }
                }
            }
        }
    }
}

private struct WeakAreasSection: View {
    let title: String
    let subtitle: String
    let items: [HomeTopicActionSnapshot]
    let emptyMessage: String
    let onSelect: (SearchDestination?) -> Void

    var body: some View {
        ReviewDueSection(
            title: title,
            subtitle: subtitle,
            items: items,
            emptyMessage: emptyMessage,
            onSelect: onSelect
        )
    }
}

private struct TopicActionRow: View {
    let item: HomeTopicActionSnapshot
    let action: () -> Void

    var body: some View {
        InsetListRow(title: item.title, subtitle: item.detail) {
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
    }

    private var accentColor: Color {
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
            SectionHeader(
                eyebrow: "Daily rep",
                title: "Question of the day",
                subtitle: "One focused knowledge check to keep high-value material moving."
            )

            SectionContainer {
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

private struct ManageFocusSheet: View {
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
            .navigationTitle("Current Focus")
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
