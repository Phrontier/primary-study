import SwiftUI

struct QuizHubView: View {
    @EnvironmentObject private var quizStore: QuizStore

    @State private var selectedCategoryOptionID = QuizCategoryOption.allID
    @State private var selectedQuestionCount = 10
    @State private var activeSession: QuizSessionViewModel?
    @State private var reviewSession: QuizSessionViewModel?
    @State private var completedSession: QuizSessionRecord?
    @State private var completedQuestions: [QuizQuestion] = []

    private var categoryOptions: [QuizCategoryOption] {
        quizStore.categoryOptions()
    }

    private var selectedOption: QuizCategoryOption? {
        categoryOptions.first(where: { $0.id == selectedCategoryOptionID }) ?? categoryOptions.first
    }

    private var selectedCategoryHistory: [QuizSessionRecord] {
        quizStore.history(for: selectedOption?.categoryID)
    }

    var body: some View {
        Group {
            if let reviewSession {
                QuizSessionView(
                    viewModel: reviewSession,
                    onBack: {
                        self.reviewSession = nil
                    }
                ) { _ in
                    self.reviewSession = nil
                }
            } else if let activeSession {
                QuizSessionView(
                    viewModel: activeSession,
                    onBack: {
                        self.activeSession = nil
                    }
                ) { session in
                    quizStore.recordCompletedSession(session, questions: activeSession.questions)
                    completedQuestions = activeSession.questions
                    completedSession = session
                    self.activeSession = nil
                }
            } else if let completedSession {
                QuizResultsView(
                    session: completedSession,
                    questions: completedQuestions,
                    categoryTitle: selectedOption?.title ?? "Quiz",
                    missedCategories: quizStore.missedCategories(for: completedSession),
                    weakSignals: quizStore.weakAreaSignals(considering: completedSession, limit: 3),
                    recentHistory: selectedCategoryHistory,
                    onReviewMissed: startMissedReview,
                    onRetake: startQuiz,
                    onBackToSetup: {
                        self.completedSession = nil
                        self.completedQuestions = []
                    }
                )
            } else {
                QuizSetupView(
                    options: categoryOptions,
                    selectedCategoryOptionID: $selectedCategoryOptionID,
                    selectedQuestionCount: $selectedQuestionCount,
                    recentHistory: selectedCategoryHistory,
                    canStartQuiz: canStartQuiz,
                    onStartQuiz: startQuiz
                )
            }
        }
        .detailNavigationChrome(title: "Quiz")
        .onAppear {
            normalizeSelection()
        }
        .onChange(of: selectedCategoryOptionID) {
            normalizeSelection()
        }
    }

    private func normalizeSelection() {
        guard let selectedOption else {
            selectedCategoryOptionID = categoryOptions.first?.id ?? QuizCategoryOption.allID
            selectedQuestionCount = 10
            return
        }

        let validCounts = [10, 20, 30].filter { selectedOption.availableCount >= $0 }
        if let preferred = validCounts.first(where: { $0 == selectedQuestionCount }) {
            selectedQuestionCount = preferred
        } else if let fallback = validCounts.first {
            selectedQuestionCount = fallback
        }
    }

    private func canStartQuiz() -> Bool {
        guard let selectedOption else { return false }
        return quizStore.canStartQuiz(categoryID: selectedOption.categoryID, count: selectedQuestionCount)
    }

    private func startQuiz() {
        guard let selectedOption else { return }
        let questions = quizStore.buildQuestionSet(categoryID: selectedOption.categoryID, count: selectedQuestionCount)
        guard questions.count == selectedQuestionCount else { return }

        completedSession = nil
        completedQuestions = []
        activeSession = QuizSessionViewModel(
            mode: .quiz,
            categoryID: selectedOption.categoryID ?? QuizCategoryOption.allID,
            categoryTitle: selectedOption.title,
            questions: questions
        )
    }

    private func startMissedReview() {
        guard let completedSession else { return }
        let queue = quizStore.missedQueue(from: completedSession)
        guard !queue.isEmpty else { return }

        let questions = quizStore.missedQuestions(from: completedSession)
        guard !questions.isEmpty else { return }

        reviewSession = QuizSessionViewModel(
            mode: .missedReview(sourceSessionID: completedSession.id),
            categoryID: completedSession.categoryID,
            categoryTitle: "Missed Question Review",
            questions: questions
        )
    }
}

private struct QuizSetupView: View {
    @Environment(\.dynamicTypeSize) private var textSize
    let options: [QuizCategoryOption]
    @Binding var selectedCategoryOptionID: String
    @Binding var selectedQuestionCount: Int
    let recentHistory: [QuizSessionRecord]
    let canStartQuiz: () -> Bool
    let onStartQuiz: () -> Void

    private var selectedOption: QuizCategoryOption? {
        options.first(where: { $0.id == selectedCategoryOptionID }) ?? options.first
    }

    private var availableCounts: [Int] {
        guard let selectedOption else { return [] }
        return [10, 20, 30].filter { selectedOption.availableCount >= $0 }
    }

    var body: some View {
        AppScrollScreen(bottomPadding: 56) {
            HeroCard(
                eyebrow: "Quiz setup",
                title: "Objective testing, one clean question at a time",
                subtitle: nil
            )

            if options.isEmpty {
                EmptyStateCard(
                    icon: "exclamationmark.bubble.fill",
                    title: "Quiz Bank Unavailable",
                    message: "The local quiz bank could not be loaded, so the quiz tool cannot start yet."
                )
            } else {
                VStack(alignment: .leading, spacing: 16) {
                    SectionHeader(
                        eyebrow: "Category",
                        title: "Choose Your Question Set",
                        subtitle: nil
                    )

                    Group {
                        LazyVGrid(columns: [GridItem(.adaptive(minimum: textSize.isAccessibilitySize ? 300 : 160), spacing: 12)], spacing: 12) {
                            ForEach(options) { option in
                                QuizCategoryOptionCard(
                                    option: option,
                                    isSelected: option.id == selectedCategoryOptionID
                                ) {
                                    selectedCategoryOptionID = option.id
                                }
                            }
                        }
                    }
                }

                if let selectedOption {
                    SectionContainer(highlighted: true) {
                        VStack(alignment: .leading, spacing: 18) {
                            HStack(alignment: .top, spacing: 14) {
                                ZStack {
                                    RoundedRectangle(cornerRadius: 18, style: .continuous)
                                        .fill(StudyDesign.action)
                                        .frame(width: 54, height: 54)

                                    Image(systemName: selectedOption.iconName)
                                        .font(.system(size: 22, weight: .semibold))
                                        .foregroundStyle(.white)
                                }

                                VStack(alignment: .leading, spacing: 6) {
                                    Text(selectedOption.title)
                                        .pilotText(.section)
                                        .foregroundStyle(AppTheme.textPrimary)

                                    Text(selectedOption.summary)
                                        .pilotText(.subtitle)
                                        .foregroundStyle(AppTheme.textSecondary)
                                }
                            }

                            VStack(alignment: .leading, spacing: 12) {
                                HStack {
                                    Text("Question Count")
                                        .pilotText(.tool)
                                        .foregroundStyle(AppTheme.textPrimary)

                                    Spacer()

                                    Text("\(selectedOption.availableCount) available")
                                        .pilotText(.metadata)
                                        .foregroundStyle(AppTheme.textMuted)
                                }

                                HStack(spacing: 10) {
                                    ForEach([10, 20, 30], id: \.self) { count in
                                        QuizCountButton(
                                            count: count,
                                            isSelected: selectedQuestionCount == count,
                                            isEnabled: availableCounts.contains(count)
                                        ) {
                                            selectedQuestionCount = count
                                        }
                                    }
                                }

                                if availableCounts.isEmpty {
                                    Text("This category needs at least 10 seeded questions before quizzes can start.")
                                        .pilotText(.metadata)
                                        .foregroundStyle(AppTheme.warning)
                                }
                            }

                            Button(action: onStartQuiz) {
                                StudyActionButton(title: "Start Quiz", icon: "arrow.right", tint: AppTheme.accent, isProminent: true)
                            }
                            .buttonStyle(.plain)
                            .disabled(!canStartQuiz())
                            .opacity(canStartQuiz() ? 1 : 0.58)
                        }
                    }
                }

                if !recentHistory.isEmpty {
                    VStack(alignment: .leading, spacing: 12) {
                        SectionHeader(
                            eyebrow: "History",
                            title: "Recent Attempts",
                            subtitle: nil
                        )

                        SectionContainer {
                            VStack(alignment: .leading, spacing: 14) {
                                ForEach(Array(recentHistory.prefix(3))) { session in
                                    ReviewRow(
                                        title: "\(session.finalScore) / \(session.questionCount)",
                                        subtitle: session.completionDate.formatted(date: .abbreviated, time: .shortened),
                                        detail: "\(session.percentageScore)%",
                                        color: color(for: session.percentageScore)
                                    )
                                }
                            }
                        }
                    }
                }
            }
        }
    }

    private func color(for percentage: Int) -> Color {
        switch percentage {
        case 85...:
            return AppTheme.success
        case 70...:
            return AppTheme.warning
        default:
            return AppTheme.danger
        }
    }
}

private struct QuizSessionView: View {
    @ObservedObject var viewModel: QuizSessionViewModel
    let onBack: () -> Void
    let onComplete: (QuizSessionRecord) -> Void

    private let headerSideSlotWidth: CGFloat = 112

    var body: some View {
        AppScrollScreen(bottomPadding: 32) {
            ViewThatFits(in: .horizontal) {
                compactHeader(topInset: 0)
                VStack(alignment: .leading, spacing: 10) { headerBackButton; Text(headerTitle).designText(.section); headerCategoryBadge }
            }
            progressSection
            SelectedSurface {
                QuizAdaptivePromptView(prompt: viewModel.currentQuestion.prompt,
                    footer: viewModel.currentQuestion.format == .trueFalse ? "True or False" : "Select the best answer")
            }
            QuizAnswerPanel(question: viewModel.currentQuestion, submittedResult: viewModel.submittedResult,
                onSelectChoice: { _ = viewModel.selectChoice($0) })
            if viewModel.canAdvance { continueButton }
        }
        .toolbar(.hidden, for: .tabBar)
        .toolbar(.hidden, for: .navigationBar)
        .navigationBarBackButtonHidden(true)
    }

    private var continueButton: some View {
        Button {
            if let session = viewModel.advance() {
                onComplete(session)
            }
        } label: {
            Text(viewModel.primaryActionTitle)
                .pilotText(.tool)
                .foregroundStyle(.white)
                .frame(maxWidth: .infinity)
                .padding(.vertical, 16)
                .background(
                    RoundedRectangle(cornerRadius: 20, style: .continuous)
                        .fill(StudyDesign.action)
                )
        }
        .buttonStyle(.plain)

    }

    private func compactHeader(topInset: CGFloat) -> some View {
        HStack(spacing: 10) {
            headerBackButton
                .frame(width: headerSideSlotWidth, alignment: .leading)

            Text(headerTitle)
                .pilotText(.section)
                .foregroundStyle(AppTheme.textPrimary)
                .lineLimit(1)
                .minimumScaleFactor(0.85)
                .frame(maxWidth: .infinity, alignment: .center)

            headerCategoryBadge
                .frame(width: headerSideSlotWidth, alignment: .trailing)
        }
        .padding(.top, max(4, topInset * 0.22))
    }

    private var headerBackButton: some View {
        Button {
            onBack()
        } label: {
            Image(systemName: "chevron.left")
                .font(.system(size: 18, weight: .bold))
                .foregroundStyle(AppTheme.textPrimary)
                .frame(width: 42, height: 42)
                .background(
                    Circle()
                        .fill(AppTheme.surface.opacity(0.82))
                        .overlay(
                            Circle()
                                .stroke(AppTheme.cardStroke, lineWidth: 1)
                        )
                )
        }
        .buttonStyle(.plain)
        .accessibilityLabel("Back to quiz setup")
    }

    private var headerCategoryBadge: some View {
        Text(viewModel.categoryTitle)
            .pilotText(.metadata)
            .foregroundStyle(AppTheme.accentSoft)
            .lineLimit(1)
            .truncationMode(.tail)
            .padding(.horizontal, 12)
            .padding(.vertical, 5)
            .background(
                Capsule()
                    .fill(AppTheme.accent.opacity(0.12))
            )
    }

    private var progressSection: some View {
        VStack(alignment: .leading, spacing: 4) {
            Text(viewModel.progressText)
                .pilotText(.metadata)
                .foregroundStyle(AppTheme.textSecondary)

            GeometryReader { geometry in
                ZStack(alignment: .leading) {
                    Capsule()
                        .fill(AppTheme.raisedSurface)

                    Capsule()
                        .fill(StudyDesign.action)
                        .frame(width: geometry.size.width * viewModel.progressValue)
                }
            }
            .frame(height: 8)
        }
    }

    private var headerTitle: String {
        switch viewModel.mode {
        case .quiz:
            return "Quiz"
        case .missedReview:
            return "Missed Review"
        }
    }
}

private struct QuizAnswerPanel: View {
    let question: QuizQuestion
    let submittedResult: QuizQuestionResult?
    let onSelectChoice: (String) -> Void

    var body: some View { flexibleAnswers }

    private var flexibleAnswers: some View {
        VStack(spacing: 6) {
            ForEach(question.choices) { choice in
                QuizAnswerButton(
                    label: choice.text,
                    badge: QuizChoicePresentation.badgeText(for: choice, format: question.format),
                    state: answerState(for: choice.id),
                    isInteractive: submittedResult == nil,
                    fixedHeight: nil
                ) {
                    onSelectChoice(choice.id)
                }
            }
        }
    }

    private func answerState(for choiceID: String) -> QuizAnswerVisualState {
        guard let submittedResult else { return .idle }

        if choiceID == submittedResult.correctChoiceID {
            return submittedResult.wasCorrect ? .correct : .correctReveal
        }

        if choiceID == submittedResult.selectedChoiceID {
            return .incorrect
        }

        return .subdued
    }
}

private struct QuizResultsView: View {
    let session: QuizSessionRecord
    let questions: [QuizQuestion]
    let categoryTitle: String
    let missedCategories: [QuizCategoryMissSnapshot]
    let weakSignals: [QuizWeakAreaSignal]
    let recentHistory: [QuizSessionRecord]
    let onReviewMissed: () -> Void
    let onRetake: () -> Void
    let onBackToSetup: () -> Void

    private var missedCount: Int {
        session.questionCount - session.finalScore
    }

    var body: some View {
        AppScrollScreen(bottomPadding: 56) {
            HeroCard(
                eyebrow: "Results",
                title: "Quiz Results",
                subtitle: resultMessage
            ) {
                VStack(alignment: .leading, spacing: 18) {
                    HStack(alignment: .firstTextBaseline, spacing: 10) {
                        Text("\(session.percentageScore)%")
                            .font(.system(size: 42, weight: .bold, design: .rounded))
                            .foregroundStyle(AppTheme.textPrimary)

                        Text("\(session.finalScore) / \(session.questionCount) correct")
                            .pilotText(.tool)
                            .foregroundStyle(AppTheme.textSecondary)
                    }

                    HStack(spacing: 10) {
                        ResultMetricPill(title: "Category", value: categoryTitle, color: AppTheme.accent)
                        ResultMetricPill(title: "Missed", value: "\(missedCount)", color: missedCount == 0 ? AppTheme.success : AppTheme.warning)
                    }
                }
            }

            if !missedCategories.isEmpty {
                VStack(alignment: .leading, spacing: 12) {
                    SectionHeader(
                        eyebrow: "Misses",
                        title: "Missed Categories",
                        subtitle: nil
                    )

                    SectionContainer {
                        VStack(alignment: .leading, spacing: 14) {
                            ForEach(missedCategories) { snapshot in
                                ReviewRow(
                                    title: snapshot.title,
                                    subtitle: "Category with the highest concentration of misses in this session.",
                                    detail: snapshot.missedCount == 1 ? "1 miss" : "\(snapshot.missedCount) misses",
                                    color: AppTheme.warning
                                )
                            }
                        }
                    }
                }
            }

            if !weakSignals.isEmpty {
                VStack(alignment: .leading, spacing: 12) {
                    SectionHeader(
                        eyebrow: "Signals",
                        title: "Weak Topics Detected",
                        subtitle: nil
                    )

                    SectionContainer {
                        VStack(alignment: .leading, spacing: 14) {
                            ForEach(weakSignals) { signal in
                                ReviewRow(
                                    title: signal.title,
                                    subtitle: signal.detail,
                                    detail: "Review",
                                    color: AppTheme.danger
                                )
                            }
                        }
                    }
                }
            }

            if recentHistory.count > 1 {
                VStack(alignment: .leading, spacing: 12) {
                    SectionHeader(
                        eyebrow: "Trend",
                        title: "Recent History",
                        subtitle: nil
                    )

                    SectionContainer {
                        VStack(alignment: .leading, spacing: 12) {
                            ForEach(Array(recentHistory.prefix(4))) { attempt in
                                ReviewRow(
                                    title: "\(attempt.finalScore) / \(attempt.questionCount)",
                                    subtitle: attempt.completionDate.formatted(date: .abbreviated, time: .shortened),
                                    detail: "\(attempt.percentageScore)%",
                                    color: attempt.id == session.id ? AppTheme.accent : AppTheme.textSecondary
                                )
                            }
                        }
                    }
                }
            }

            VStack(alignment: .leading, spacing: 12) {
                if missedCount > 0 {
                    Button(action: onReviewMissed) {
                        StudyActionButton(title: "Review Missed Questions", icon: "arrow.uturn.left", tint: AppTheme.warning, isProminent: true)
                    }
                    .buttonStyle(.plain)
                }

                Button(action: onRetake) {
                    StudyActionButton(title: "Retake Quiz", icon: "arrow.clockwise", tint: AppTheme.accent, isProminent: true)
                }
                .buttonStyle(.plain)

                Button(action: onBackToSetup) {
                    StudyActionButton(title: "Back to Setup", icon: "chevron.left", tint: AppTheme.accent, isProminent: false)
                }
                .buttonStyle(.plain)
            }
        }
    }

    private var resultMessage: String {
        switch session.percentageScore {
        case 90...:
            return "Strong run. Keep the misses sharp, but the category is holding together well."
        case 75...:
            return "Solid base. The misses below are the fastest way to tighten this quiz back up."
        default:
            return "This category needs another pass. Review the misses first, then retake while the explanations are still fresh."
        }
    }
}

private struct QuizCategoryOptionCard: View {
    let option: QuizCategoryOption
    let isSelected: Bool
    let action: () -> Void

    var body: some View {
        Button(action: action) {
            VStack(alignment: .leading, spacing: 10) {
                HStack {
                    Image(systemName: option.iconName)
                        .font(.system(size: 18, weight: .semibold))
                        .foregroundStyle(isSelected ? AppTheme.accentSoft : AppTheme.textSecondary)

                    Spacer()

                    Text("\(option.availableCount)")
                        .pilotText(.metadata)
                        .foregroundStyle(isSelected ? AppTheme.accentSoft : AppTheme.textMuted)
                }

                Text(option.title)
                    .pilotText(.tool)
                    .foregroundStyle(AppTheme.textPrimary)

                Text(option.summary)
                    .pilotText(.metadata)
                    .foregroundStyle(AppTheme.textSecondary)
                    .lineLimit(3)
            }
            .padding(16)
            .frame(maxWidth: .infinity, alignment: .leading)
            .background(
                RoundedRectangle(cornerRadius: 22, style: .continuous)
                    .fill(isSelected ? AppTheme.accent.opacity(0.16) : AppTheme.surface.opacity(0.9))
                    .overlay(
                        RoundedRectangle(cornerRadius: 22, style: .continuous)
                            .stroke(isSelected ? AppTheme.accent.opacity(0.55) : AppTheme.cardStroke, lineWidth: 1)
                    )
            )
        }
        .buttonStyle(.plain)
    }
}

private struct QuizCountButton: View {
    let count: Int
    let isSelected: Bool
    let isEnabled: Bool
    let action: () -> Void

    var body: some View {
        Button(action: action) {
            Text("\(count)")
                .pilotText(.tool)
                .foregroundStyle(foregroundColor)
                .frame(maxWidth: .infinity)
                .padding(.vertical, 14)
                .background(
                    RoundedRectangle(cornerRadius: 16, style: .continuous)
                        .fill(backgroundColor)
                )
        }
        .buttonStyle(.plain)
        .disabled(!isEnabled)
        .opacity(isEnabled ? 1 : 0.4)
    }

    private var foregroundColor: Color {
        if isSelected {
            return .white
        }
        return isEnabled ? AppTheme.textPrimary : AppTheme.textMuted
    }

    private var backgroundColor: AnyShapeStyle {
        if isSelected {
            return AnyShapeStyle(StudyDesign.action)
        }
        return AnyShapeStyle(AppTheme.raisedSurface.opacity(0.92))
    }
}

private struct ResultMetricPill: View {
    let title: String
    let value: String
    let color: Color

    var body: some View {
        VStack(alignment: .leading, spacing: 4) {
            Text(title.uppercased())
                .pilotText(.footer)
                .foregroundStyle(AppTheme.textMuted)
                .tracking(0.7)

            Text(value)
                .pilotText(.subtitle)
                .foregroundStyle(color)
                .lineLimit(1)
                .minimumScaleFactor(0.8)
        }
        .padding(.horizontal, 14)
        .padding(.vertical, 12)
        .background(
            RoundedRectangle(cornerRadius: 18, style: .continuous)
                .fill(AppTheme.surface.opacity(0.82))
                .overlay(
                    RoundedRectangle(cornerRadius: 18, style: .continuous)
                        .stroke(color.opacity(0.28), lineWidth: 1)
                )
        )
    }
}
