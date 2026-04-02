import SwiftUI

struct PracticeTestView: View {
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
