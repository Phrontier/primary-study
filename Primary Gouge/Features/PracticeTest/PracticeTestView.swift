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
        .alert("Practice test complete", isPresented: $showingCompletionSheet) {
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
        AppScrollScreen(bottomPadding: 48) {
            HeroCard(
                eyebrow: "\(event.code) • Ground school test",
                title: bank.title,
                subtitle: bank.summary
            )

            VStack(alignment: .leading, spacing: 12) {
                SectionHeader(
                    eyebrow: "Mode",
                    title: "Choose your run",
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

            let history = appModel.testHistory(for: bank.id)
            if !history.isEmpty {
                VStack(alignment: .leading, spacing: 12) {
                    SectionHeader(
                        eyebrow: "History",
                        title: "Recent attempts",
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
        }
    }

    private func sessionView(for question: Question) -> some View {
        AppScrollScreen(bottomPadding: 40) {
            HeroCard(
                eyebrow: "\(event.code) • \(activeMode?.title ?? "Practice test")",
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
        .accessibilityLabel(isStarred ? "Unstar question" : "Star question")
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
                            title: revealed ? "Hide answer" : "Reveal answer",
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
                        title: "How did you do?",
                        subtitle: "Mark the result and move to the next question."
                    )

                    HStack(spacing: 12) {
                        Button {
                            submit(false)
                        } label: {
                            StudyActionButton(title: "Mark missed", icon: "xmark", tint: AppTheme.danger, isProminent: false)
                        }
                        .buttonStyle(.plain)

                        Button {
                            submit(true)
                        } label: {
                            StudyActionButton(title: "Mark correct", icon: "checkmark", tint: AppTheme.success)
                        }
                        .buttonStyle(.plain)
                    }
                }
            }

            let history = appModel.testHistory(for: bank.id)
            if !history.isEmpty {
                VStack(alignment: .leading, spacing: 12) {
                    SectionHeader(
                        eyebrow: "History",
                        title: "Recent attempts",
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
        }
        .detailNavigationChrome(title: bank.title)
        .alert("Practice test complete", isPresented: $showingCompletionSheet) {
            Button("Done") {
                dismiss()
            }
        } message: {
            Text(resultSummary)
        }
        .onAppear {
            startedAt = .now
        }
        .onDisappear {
            guard !didRecordSession else { return }

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

    private var resultSummary: String {
        let score = results.values.filter { $0 }.count
        return "Score: \(score)/\(bank.questions.count). Missed questions stay visible in the test history for targeted review."
    }

    private func submit(_ correct: Bool) {
        results[currentQuestion.id] = correct

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
