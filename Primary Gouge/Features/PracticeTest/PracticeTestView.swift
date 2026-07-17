import SwiftUI

struct PracticeTestView: View {
    let event: Event
    let bank: QuestionBank

    var body: some View {
        if bank.supportsObjectiveTesting {
            ObjectivePracticeTestView(event: event, bank: bank)
        } else {
            LegacyPracticeTestView(event: event, bank: bank)
        }
    }
}

private enum ObjectivePracticeMode: String, CaseIterable, Identifiable {
    case full
    case smartReview
    case starred

    var id: String { rawValue }

    var title: String {
        switch self {
        case .full: "Full Test"
        case .smartReview: "Smart Review"
        case .starred: "Starred"
        }
    }

    var summary: String {
        switch self {
        case .full:
            return "Run the complete bank in source order."
        case .smartReview:
            return "Starred questions first, then previous misses and weak questions."
        case .starred:
            return "Only questions you have starred for focused review."
        }
    }

    var iconName: String {
        switch self {
        case .full: "checklist.checked"
        case .smartReview: "sparkles"
        case .starred: "star.fill"
        }
    }
}

private struct ObjectivePracticeTestView: View {
    let event: Event
    let bank: QuestionBank

    @EnvironmentObject private var appModel: StudyAppModel
    @Environment(\.dismiss) private var dismiss

    @State private var activeMode: ObjectivePracticeMode?
    @State private var activeQuestions: [Question] = []
    @State private var currentIndex = 0
    @State private var selectedChoiceID: String?
    @State private var submittedChoiceID: String?
    @State private var startedAt = Date()
    @State private var results: [String: Bool] = [:]
    @State private var showingCompletionSheet = false
    @State private var didRecordSession = false

    private var currentQuestion: Question? {
        guard activeQuestions.indices.contains(currentIndex) else { return nil }
        return activeQuestions[currentIndex]
    }

    var body: some View {
        Group {
            if let currentQuestion {
                sessionView(for: currentQuestion)
            } else {
                setupView
            }
        }
        .detailNavigationChrome(title: bank.title)
        .alert("Practice Test Complete", isPresented: $showingCompletionSheet) {
            Button("Done") {
                dismiss()
            }
        } message: {
            Text(resultSummary)
        }
        .onDisappear {
            recordAbandonedSessionIfNeeded()
        }
    }

    private var setupView: some View {
        let performance = appModel.practiceTestPerformance(for: bank)
        let questionItems = appModel.practiceTestQuestionListItems(for: bank)
        let history = appModel.testHistory(for: bank.id)

        return AppScrollScreen(bottomPadding: 48) {
            HeroCard(
                eyebrow: "\(event.code) • Ground school test",
                title: bank.title,
                subtitle: bank.summary
            ) {
                PracticeTestPerformanceBar(snapshot: performance)
            }

            VStack(alignment: .leading, spacing: 12) {
                SectionHeader(
                    eyebrow: "Mode",
                    title: "Choose Your Run",
                    subtitle: nil
                )

                SectionContainer {
                    VStack(spacing: 12) {
                        ForEach(ObjectivePracticeMode.allCases) { mode in
                            Button {
                                start(mode)
                            } label: {
                                objectiveModeRow(mode)
                            }
                            .buttonStyle(.plain)
                            .disabled(questionCount(for: mode) == 0)
                            .opacity(questionCount(for: mode) == 0 ? 0.55 : 1)
                        }
                    }
                }
            }

            if !history.isEmpty {
                VStack(alignment: .leading, spacing: 12) {
                    SectionHeader(
                        eyebrow: "History",
                        title: "Recent Attempts",
                        subtitle: nil
                    )

                    SectionContainer {
                        VStack(alignment: .leading, spacing: 10) {
                            ForEach(history.prefix(3), id: \.id) { attempt in
                                ReviewRow(
                                    title: "\(attempt.score)/\(attempt.total)",
                                    subtitle: attempt.takenAt.formatted(date: .abbreviated, time: .shortened),
                                    detail: "\(attempt.total - attempt.score) missed",
                                    color: attempt.score == attempt.total ? AppTheme.success : AppTheme.warning
                                )
                            }
                        }
                    }
                }
            }

            PracticeQuestionLibrarySection(items: questionItems, bank: bank)
        }
    }

    private func sessionView(for question: Question) -> some View {
        AppScrollScreen(bottomPadding: 40) {
            HeroCard(
                eyebrow: "\(event.code) • \(activeMode?.title ?? "Practice Test")",
                title: bank.title,
                subtitle: nil
            ) {
                VStack(alignment: .leading, spacing: 12) {
                    HStack {
                        Text("Question \(currentIndex + 1) of \(activeQuestions.count)")
                            .font(.subheadline.weight(.semibold))
                            .foregroundStyle(AppTheme.accent)

                        Spacer()

                        starButton(for: question)
                    }

                    ProgressStrip(
                        value: Double(currentIndex + 1),
                        total: Double(activeQuestions.count),
                        tint: AppTheme.accent
                    )
                }
            }

            SectionContainer(highlighted: true) {
                QuizAdaptivePromptView(
                    prompt: question.prompt,
                    footer: question.format == .trueFalse ? "True or False" : "Select the best answer"
                )
                .frame(minHeight: 150, alignment: .topLeading)
            }

            ObjectiveAnswerPanel(
                question: question,
                submittedChoiceID: submittedChoiceID,
                onSelectChoice: selectChoice
            )

            if let submittedChoiceID {
                SectionContainer {
                    VStack(alignment: .leading, spacing: 10) {
                        Text(question.isCorrect(choiceID: submittedChoiceID) ? "Correct" : "Incorrect")
                            .font(.headline.weight(.bold))
                            .foregroundStyle(question.isCorrect(choiceID: submittedChoiceID) ? AppTheme.success : AppTheme.danger)

                        Text("Answer: \(question.answer)")
                            .font(.body)
                            .foregroundStyle(AppTheme.textPrimary)

                        if let explanation = question.explanation, !explanation.isEmpty {
                            Text(explanation)
                                .font(.footnote)
                                .foregroundStyle(AppTheme.textSecondary)
                        }
                    }
                }

                Button {
                    advance()
                } label: {
                    StudyActionButton(
                        title: currentIndex == activeQuestions.count - 1 ? "Finish" : "Continue",
                        icon: currentIndex == activeQuestions.count - 1 ? "checkmark" : "arrow.right",
                        tint: AppTheme.accent,
                        isProminent: true
                    )
                }
                .buttonStyle(.plain)
            }
        }
        .onAppear {
            if activeMode == nil {
                start(.full)
            }
        }
    }

    private func objectiveModeRow(_ mode: ObjectivePracticeMode) -> some View {
        HStack(spacing: 14) {
            ZStack {
                RoundedRectangle(cornerRadius: 14, style: .continuous)
                    .fill(AppTheme.accent.opacity(0.16))
                    .frame(width: 48, height: 48)

                Image(systemName: mode.iconName)
                    .font(.system(size: 19, weight: .semibold))
                    .foregroundStyle(AppTheme.accent)
            }

            VStack(alignment: .leading, spacing: 4) {
                Text(mode.title)
                    .font(.headline.weight(.bold))
                    .foregroundStyle(AppTheme.textPrimary)

                Text(mode.summary)
                    .font(.footnote)
                    .foregroundStyle(AppTheme.textSecondary)
                    .fixedSize(horizontal: false, vertical: true)
            }

            Spacer()

            Text("\(questionCount(for: mode))")
                .font(.caption.weight(.bold))
                .foregroundStyle(AppTheme.textMuted)
        }
        .padding(12)
        .background(AppTheme.cardBackground(style: .standard))
    }

    private func starButton(for question: Question) -> some View {
        let isStarred = appModel.isPracticeQuestionStarred(question, in: bank)

        return Button {
            appModel.setPracticeQuestionStarred(question, in: bank, isStarred: !isStarred)
        } label: {
            Image(systemName: isStarred ? "star.fill" : "star")
                .font(.system(size: 18, weight: .semibold))
                .foregroundStyle(isStarred ? AppTheme.warning : AppTheme.textSecondary)
                .frame(width: 40, height: 40)
                .background(
                    Circle()
                        .fill(AppTheme.surface.opacity(0.8))
                        .overlay(Circle().stroke(AppTheme.cardStroke, lineWidth: 1))
                )
        }
        .buttonStyle(.plain)
        .accessibilityLabel(isStarred ? "Unstar Question" : "Star Question")
    }

    private var resultSummary: String {
        let score = results.values.filter { $0 }.count
        return "Score: \(score)/\(activeQuestions.count). Starred and missed questions stay available for Smart Review."
    }

    private func questionCount(for mode: ObjectivePracticeMode) -> Int {
        switch mode {
        case .full:
            return bank.objectiveQuestions.count
        case .smartReview:
            return appModel.smartReviewQuestions(in: bank).count
        case .starred:
            return appModel.starredQuestions(in: bank).count
        }
    }

    private func questions(for mode: ObjectivePracticeMode) -> [Question] {
        switch mode {
        case .full:
            return bank.objectiveQuestions
        case .smartReview:
            return appModel.smartReviewQuestions(in: bank)
        case .starred:
            return appModel.starredQuestions(in: bank)
        }
    }

    private func start(_ mode: ObjectivePracticeMode) {
        let questions = questions(for: mode)
        guard !questions.isEmpty else { return }
        activeMode = mode
        activeQuestions = questions
        currentIndex = 0
        selectedChoiceID = nil
        submittedChoiceID = nil
        results = [:]
        startedAt = .now
        didRecordSession = false
    }

    private func selectChoice(_ choiceID: String) {
        guard submittedChoiceID == nil, let question = currentQuestion else { return }
        selectedChoiceID = choiceID
        submittedChoiceID = choiceID

        let correct = question.isCorrect(choiceID: choiceID)
        results[question.id] = correct
        appModel.recordPracticeQuestionAnswer(question, in: bank, wasCorrect: correct)
    }

    private func advance() {
        guard currentQuestion != nil else { return }

        if currentIndex == activeQuestions.count - 1 {
            recordCompletedSession()
            showingCompletionSheet = true
        } else {
            currentIndex += 1
            selectedChoiceID = nil
            submittedChoiceID = nil
        }
    }

    private func recordCompletedSession() {
        let missed = results.filter { !$0.value }.map(\.key)
        let score = results.values.filter { $0 }.count
        appModel.recordTestAttempt(
            bank: bank,
            topicIDs: appModel.topicIDs(for: bank, event: event),
            score: score,
            total: activeQuestions.count,
            missedQuestionIDs: missed,
            elapsedSeconds: Date().timeIntervalSince(startedAt)
        )
        appModel.markEventStudied(event)
        appModel.recordStudySession(
            kind: .practiceTest,
            topicIDs: appModel.topicIDs(for: bank, event: event),
            startedAt: startedAt,
            endedAt: .now,
            completedItems: activeQuestions.count,
            totalItems: activeQuestions.count,
            outcome: .completed,
            activity: StudyActivityRecord(
                kind: .practiceTest,
                destination: practiceDestination,
                title: bank.title,
                subtitle: event.code,
                topicIDs: appModel.topicIDs(for: bank, event: event),
                completedAt: .now,
                progressContext: activeMode?.title ?? "Completed"
            )
        )
        didRecordSession = true
    }

    private func recordAbandonedSessionIfNeeded() {
        guard activeMode != nil, !activeQuestions.isEmpty, !didRecordSession else { return }

        appModel.recordStudySession(
            kind: .practiceTest,
            topicIDs: appModel.topicIDs(for: bank, event: event),
            startedAt: startedAt,
            endedAt: .now,
            completedItems: results.count,
            totalItems: activeQuestions.count,
            outcome: .abandoned,
            activity: StudyActivityRecord(
                kind: .practiceTest,
                destination: practiceDestination,
                title: bank.title,
                subtitle: event.code,
                topicIDs: appModel.topicIDs(for: bank, event: event),
                progressContext: "Abandoned"
            )
        )
        didRecordSession = true
    }

    private var practiceDestination: StudyActivityDestination {
        if let phase = appModel.phase(containingEventID: event.id) {
            return .event(phaseID: phase.id, eventID: event.id)
        }
        return .questionOfDay(questionID: bank.id)
    }
}

private struct ObjectiveAnswerPanel: View {
    let question: Question
    let submittedChoiceID: String?
    let onSelectChoice: (String) -> Void

    private var choices: [QuizChoice] {
        question.choices ?? []
    }

    var body: some View {
        VStack(spacing: 8) {
            ForEach(choices) { choice in
                QuizAnswerButton(
                    label: choice.text,
                    badge: badgeText(for: choice),
                    state: answerState(for: choice.id),
                    isInteractive: submittedChoiceID == nil,
                    fixedHeight: nil
                ) {
                    onSelectChoice(choice.id)
                }
            }
        }
    }

    private func badgeText(for choice: QuizChoice) -> String? {
        guard let format = question.format else { return nil }
        return QuizChoicePresentation.badgeText(for: choice, format: format)
    }

    private func answerState(for choiceID: String) -> QuizAnswerVisualState {
        guard let submittedChoiceID else { return .idle }

        if choiceID == question.correctChoiceID {
            return submittedChoiceID == choiceID ? .correct : .correctReveal
        }

        if choiceID == submittedChoiceID {
            return .incorrect
        }

        return .subdued
    }
}

private struct LegacyPracticeTestView: View {
    let event: Event
    let bank: QuestionBank

    @EnvironmentObject private var appModel: StudyAppModel
    @Environment(\.dismiss) private var dismiss

    @State private var hasStarted = false
    @State private var currentIndex = 0
    @State private var revealed = false
    @State private var startedAt = Date()
    @State private var results: [String: Bool] = [:]
    @State private var showingCompletionSheet = false
    @State private var didRecordSession = false

    private var currentQuestion: Question {
        bank.questions[currentIndex]
    }

    var body: some View {
        Group {
            if hasStarted {
                sessionView
            } else {
                setupView
            }
        }
        .detailNavigationChrome(title: bank.title)
        .alert("Practice Test Complete", isPresented: $showingCompletionSheet) {
            Button("Done") {
                dismiss()
            }
        } message: {
            Text(resultSummary)
        }
        .onDisappear {
            guard hasStarted, !didRecordSession else { return }

            appModel.recordStudySession(
                kind: .practiceTest,
                topicIDs: appModel.topicIDs(for: bank, event: event),
                startedAt: startedAt,
                endedAt: .now,
                completedItems: results.count,
                totalItems: bank.questions.count,
                outcome: .abandoned,
                activity: StudyActivityRecord(
                    kind: .practiceTest,
                    destination: practiceDestination,
                    title: bank.title,
                    subtitle: event.code,
                    topicIDs: appModel.topicIDs(for: bank, event: event),
                    progressContext: "Abandoned"
                )
            )
            didRecordSession = true
        }
    }

    private var setupView: some View {
        let performance = appModel.practiceTestPerformance(for: bank)
        let questionItems = appModel.practiceTestQuestionListItems(for: bank)
        let history = appModel.testHistory(for: bank.id)

        return AppScrollScreen(bottomPadding: 48) {
            HeroCard(
                eyebrow: "\(event.code) • Practice Test",
                title: bank.title,
                subtitle: bank.summary
            ) {
                PracticeTestPerformanceBar(snapshot: performance)
            }

            VStack(alignment: .leading, spacing: 12) {
                SectionHeader(
                    eyebrow: "Mode",
                        title: "Choose Your Run",
                    subtitle: nil
                )

                SectionContainer {
                    Button {
                        startLegacyRun()
                    } label: {
                        PracticeTestModeRow(
                            title: "Full Test",
                            summary: "Run the complete bank using reveal and self-score.",
                            iconName: "checklist.checked",
                            count: bank.questions.count
                        )
                    }
                    .buttonStyle(.plain)
                    .disabled(bank.questions.isEmpty)
                    .opacity(bank.questions.isEmpty ? 0.55 : 1)
                }
            }

            if !history.isEmpty {
                VStack(alignment: .leading, spacing: 12) {
                    SectionHeader(
                        eyebrow: "History",
                        title: "Recent Attempts",
                        subtitle: "Quick context from your most recent runs."
                    )

                    SectionContainer {
                        VStack(alignment: .leading, spacing: 10) {
                            ForEach(history.prefix(3), id: \.id) { attempt in
                                ReviewRow(
                                    title: "\(attempt.score)/\(attempt.total)",
                                    subtitle: attempt.takenAt.formatted(date: .abbreviated, time: .shortened),
                                    detail: "\(attempt.total - attempt.score) missed",
                                    color: attempt.score == attempt.total ? AppTheme.success : AppTheme.warning
                                )
                            }
                        }
                    }
                }
            }

            PracticeQuestionLibrarySection(items: questionItems, bank: bank)
        }
    }

    private var sessionView: some View {
        AppScrollScreen(bottomPadding: 40) {
            HeroCard(
                eyebrow: "\(event.code) • Practice test",
                title: bank.title,
                subtitle: bank.summary
            ) {
                ProgressStrip(
                    value: Double(currentIndex + 1),
                    total: Double(bank.questions.count),
                    tint: AppTheme.accent
                )

                Text("Question \(currentIndex + 1) of \(bank.questions.count)")
                    .font(.subheadline.weight(.semibold))
                    .foregroundStyle(AppTheme.accent)
            }

            SectionContainer(highlighted: true) {
                VStack(alignment: .leading, spacing: 16) {
                    Text(currentQuestion.prompt)
                        .font(.title3.weight(.semibold))
                        .foregroundStyle(AppTheme.textPrimary)

                    if revealed {
                        Divider()

                        Text(currentQuestion.answer)
                            .font(.body)
                            .foregroundStyle(AppTheme.textSecondary)

                        if let explanation = currentQuestion.explanation {
                            Text(explanation)
                                .font(.footnote)
                                .foregroundStyle(AppTheme.textSecondary)
                        }
                    }

                    Button {
                        withAnimation(.easeInOut(duration: 0.2)) {
                            revealed.toggle()
                        }
                    } label: {
                        StudyActionButton(
                            title: revealed ? "Hide Answer" : "Reveal Answer",
                            icon: revealed ? "eye.slash.fill" : "eye.fill",
                            tint: AppTheme.accent,
                            isProminent: !revealed
                        )
                    }
                    .buttonStyle(.plain)
                }
            }

            if revealed {
                VStack(alignment: .leading, spacing: 12) {
                    SectionHeader(
                        eyebrow: "Score it",
                        title: "How Did You Do?",
                        subtitle: "Mark the result and move to the next question."
                    )

                    HStack(spacing: 12) {
                        Button {
                            submit(false)
                        } label: {
                            StudyActionButton(title: "Mark Missed", icon: "xmark", tint: AppTheme.danger, isProminent: false)
                        }
                        .buttonStyle(.plain)

                        Button {
                            submit(true)
                        } label: {
                            StudyActionButton(title: "Mark Correct", icon: "checkmark", tint: AppTheme.success)
                        }
                        .buttonStyle(.plain)
                    }
                }
            }
        }
    }

    private var resultSummary: String {
        let score = results.values.filter { $0 }.count
        return "Score: \(score)/\(bank.questions.count). Missed questions stay visible in the test history for targeted review."
    }

    private func startLegacyRun() {
        hasStarted = true
        currentIndex = 0
        revealed = false
        results = [:]
        startedAt = .now
        didRecordSession = false
    }

    private func submit(_ correct: Bool) {
        results[currentQuestion.id] = correct
        appModel.recordPracticeQuestionAnswer(currentQuestion, in: bank, wasCorrect: correct)

        if currentIndex == bank.questions.count - 1 {
            let missed = results.filter { !$0.value }.map(\.key)
            let score = results.values.filter { $0 }.count
            appModel.recordTestAttempt(
                bank: bank,
                topicIDs: appModel.topicIDs(for: bank, event: event),
                score: score,
                total: bank.questions.count,
                missedQuestionIDs: missed,
                elapsedSeconds: Date().timeIntervalSince(startedAt)
            )
            appModel.markEventStudied(event)
            appModel.recordStudySession(
                kind: .practiceTest,
                topicIDs: appModel.topicIDs(for: bank, event: event),
                startedAt: startedAt,
                endedAt: .now,
                completedItems: bank.questions.count,
                totalItems: bank.questions.count,
                outcome: .completed,
                activity: StudyActivityRecord(
                    kind: .practiceTest,
                    destination: practiceDestination,
                    title: bank.title,
                    subtitle: event.code,
                    topicIDs: appModel.topicIDs(for: bank, event: event),
                    completedAt: .now,
                    progressContext: "Completed"
                )
            )
            didRecordSession = true
            showingCompletionSheet = true
        } else {
            currentIndex += 1
            revealed = false
        }
    }

    private var practiceDestination: StudyActivityDestination {
        if let phase = appModel.phase(containingEventID: event.id) {
            return .event(phaseID: phase.id, eventID: event.id)
        }
        return .questionOfDay(questionID: bank.id)
    }
}

private struct PracticeTestModeRow: View {
    let title: String
    let summary: String
    let iconName: String
    let count: Int

    var body: some View {
        HStack(spacing: 14) {
            ZStack {
                RoundedRectangle(cornerRadius: 14, style: .continuous)
                    .fill(AppTheme.accent.opacity(0.16))
                    .frame(width: 48, height: 48)

                Image(systemName: iconName)
                    .font(.system(size: 19, weight: .semibold))
                    .foregroundStyle(AppTheme.accent)
            }

            VStack(alignment: .leading, spacing: 4) {
                Text(title)
                    .font(.headline.weight(.bold))
                    .foregroundStyle(AppTheme.textPrimary)

                Text(summary)
                    .font(.footnote)
                    .foregroundStyle(AppTheme.textSecondary)
                    .fixedSize(horizontal: false, vertical: true)
            }

            Spacer()

            Text("\(count)")
                .font(.caption.weight(.bold))
                .foregroundStyle(AppTheme.textMuted)
        }
        .padding(12)
        .background(AppTheme.cardBackground(style: .standard))
    }
}

private struct PracticeTestPerformanceBar: View {
    let snapshot: PracticeTestPerformanceSnapshot

    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text(snapshot.detail)
                .font(.footnote)
                .foregroundStyle(AppTheme.textSecondary)
                .fixedSize(horizontal: false, vertical: true)

            GeometryReader { proxy in
                HStack(spacing: 6) {
                    ForEach(snapshot.segments, id: \.band) { segment in
                        Capsule(style: .continuous)
                            .fill(segment.band.displayColor)
                            .frame(width: segmentWidth(for: segment, totalWidth: proxy.size.width), height: 8)
                    }
                }
            }
            .frame(height: 8)

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

    private func segmentWidth(for segment: PracticeTestPerformanceSegment, totalWidth: CGFloat) -> CGFloat {
        guard snapshot.totalCount > 0 else { return 0 }
        return totalWidth * (CGFloat(segment.count) / CGFloat(snapshot.totalCount))
    }
}

private struct PracticeQuestionLibrarySection: View {
    let items: [PracticeTestQuestionListItemSnapshot]
    let bank: QuestionBank

    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            SectionHeader(
                eyebrow: "Library",
                    title: "All Questions",
                subtitle: nil
            )

            if items.isEmpty {
                EmptyStateCard(
                    icon: "tray",
                    title: "No Questions Yet",
                    message: "This test bank does not have any questions to review right now."
                )
            } else {
                LazyVStack(spacing: 12) {
                    ForEach(Array(items.enumerated()), id: \.element.question.id) { index, item in
                        PracticeQuestionPreviewCard(
                            item: item,
                            ordinal: index + 1,
                            showsCorrectChoice: bank.supportsObjectiveTesting
                        )
                    }
                }
            }
        }
    }
}

private struct PracticeQuestionPreviewCard: View {
    let item: PracticeTestQuestionListItemSnapshot
    let ordinal: Int
    let showsCorrectChoice: Bool

    var body: some View {
        SectionContainer {
            VStack(alignment: .leading, spacing: 12) {
                HStack(alignment: .center, spacing: 8) {
                    Text("Q\(ordinal)")
                        .font(.caption.weight(.bold))
                        .foregroundStyle(AppTheme.textMuted)

                    PracticeQuestionStatusBadge(text: item.band.label, color: item.band.displayColor)

                    if item.isStarred {
                        PracticeQuestionStatusBadge(text: "Starred", color: AppTheme.warning)
                    }

                    Spacer(minLength: 0)
                }

                Text(item.question.prompt)
                    .font(.headline.weight(.semibold))
                    .foregroundStyle(AppTheme.textPrimary)
                    .frame(maxWidth: .infinity, alignment: .leading)

                if showsCorrectChoice, let correctChoiceText = item.correctChoiceText {
                    VStack(alignment: .leading, spacing: 4) {
                        Text("Correct choice")
                            .font(.caption.weight(.semibold))
                            .foregroundStyle(AppTheme.textMuted)

                        Text(correctChoiceText)
                            .font(.subheadline.weight(.medium))
                            .foregroundStyle(AppTheme.textPrimary)
                            .frame(maxWidth: .infinity, alignment: .leading)
                    }
                }

                VStack(alignment: .leading, spacing: 4) {
                    Text("Answer")
                        .font(.caption.weight(.semibold))
                        .foregroundStyle(AppTheme.textMuted)

                    Text(item.question.answer)
                        .font(.subheadline)
                        .foregroundStyle(AppTheme.textSecondary)
                        .frame(maxWidth: .infinity, alignment: .leading)
                        .fixedSize(horizontal: false, vertical: true)
                }

                if let explanation = item.question.explanation, !explanation.isEmpty {
                    VStack(alignment: .leading, spacing: 4) {
                        Text("Explanation")
                            .font(.caption.weight(.semibold))
                            .foregroundStyle(AppTheme.textMuted)

                        Text(explanation)
                            .font(.footnote)
                            .foregroundStyle(AppTheme.textSecondary)
                            .frame(maxWidth: .infinity, alignment: .leading)
                            .fixedSize(horizontal: false, vertical: true)
                    }
                }
            }
        }
    }
}

private struct PracticeQuestionStatusBadge: View {
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

private extension PracticeTestPerformanceBand {
    var displayColor: Color {
        switch self {
        case .new:
            return AppTheme.textMuted
        case .missed:
            return AppTheme.statusColor(.rejected)
        case .needsReview:
            return AppTheme.statusColor(.warning)
        case .solid:
            return AppTheme.statusColor(.approved)
        }
    }
}
