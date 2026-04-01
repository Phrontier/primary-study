import SwiftUI

struct ReviewSubmissionView: View {
    private enum ActiveSelectionSheet: String, Identifiable {
        case squadron
        case event
        case chill
        case grading

        var id: String { rawValue }
    }

    @Environment(\.dismiss) private var dismiss
    @EnvironmentObject private var reviewStore: InstructorReviewStore
    @FocusState private var focusedField: Field?
    @StateObject private var viewModel = ReviewSubmissionViewModel()
    @State private var activeSheet: ActiveSelectionSheet?

    private enum Field {
        case writtenReview
    }

    var body: some View {
        AppScrollScreen(bottomPadding: 36) {
            GlassCard(highlighted: true) {
                VStack(alignment: .leading, spacing: 12) {
                    Text("Submit instructor gouge")
                        .font(.system(size: 28, weight: .bold, design: .rounded))
                        .foregroundStyle(AppTheme.textPrimary)

                    Text("Every submission starts as pending. Moderation checks the write-up before it becomes public and before it changes any averages.")
                        .font(.system(.body, design: .rounded))
                        .foregroundStyle(AppTheme.textSecondary)
                }
            }

            GlassCard {
                VStack(alignment: .leading, spacing: 14) {
                    InstructorTextFieldCard(
                        title: "Instructor Name",
                        placeholder: "Start typing an instructor",
                        text: $viewModel.instructorName
                    )

                    if !viewModel.instructorName.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty, !viewModel.suggestions.isEmpty {
                        VStack(alignment: .leading, spacing: 8) {
                            Text("Suggestions")
                                .font(.system(.footnote, design: .rounded, weight: .semibold))
                                .foregroundStyle(AppTheme.textSecondary)

                            ForEach(viewModel.suggestions) { suggestion in
                                Button {
                                    viewModel.applySuggestion(suggestion)
                                    focusedField = nil
                                } label: {
                                    HStack {
                                        VStack(alignment: .leading, spacing: 2) {
                                            Text(suggestion.name)
                                                .font(.system(.subheadline, design: .rounded, weight: .bold))
                                                .foregroundStyle(AppTheme.textPrimary)

                                            Text(suggestion.squadron.displayName)
                                                .font(.system(.caption, design: .rounded, weight: .medium))
                                                .foregroundStyle(AppTheme.textSecondary)
                                        }

                                        Spacer(minLength: 8)

                                        Image(systemName: "arrow.up.left")
                                            .font(.system(size: 12, weight: .bold))
                                            .foregroundStyle(AppTheme.accent)
                                    }
                                    .padding(.horizontal, 14)
                                    .padding(.vertical, 12)
                                    .background(
                                        RoundedRectangle(cornerRadius: 18, style: .continuous)
                                            .fill(AppTheme.elevatedSurface)
                                            .overlay(
                                                RoundedRectangle(cornerRadius: 18, style: .continuous)
                                                    .stroke(AppTheme.cardStroke.opacity(0.9), lineWidth: 1)
                                            )
                                    )
                                }
                                .buttonStyle(.plain)
                            }
                        }
                    }

                    InstructorMenuPicker(
                        title: "Squadron",
                        placeholder: "Select squadron",
                        selection: viewModel.selectedSquadron?.displayName,
                        accent: AppTheme.accent
                    ) {
                        activeSheet = .squadron
                    }

                    InstructorMenuPicker(
                        title: "Event",
                        placeholder: "Select event",
                        selection: viewModel.selectedEvent?.displayName,
                        detail: viewModel.selectedEvent?.kind.displayName,
                        accent: AppTheme.success
                    ) {
                        activeSheet = .event
                    }

                    InstructorMenuPicker(
                        title: "Chill Factor",
                        placeholder: "Select chill factor",
                        selection: viewModel.chillScore.map { InstructorRatingScale.label(for: $0, category: .chillFactor) },
                        detail: viewModel.chillScore.map { "Score \($0) / 7" },
                        accent: AppTheme.success
                    ) {
                        activeSheet = .chill
                    }

                    InstructorMenuPicker(
                        title: "Grading Style",
                        placeholder: "Select grading style",
                        selection: viewModel.gradingScore.map { InstructorRatingScale.label(for: $0, category: .gradingStyle) },
                        detail: viewModel.gradingScore.map { "Score \($0) / 7" },
                        accent: AppTheme.warning
                    ) {
                        activeSheet = .grading
                    }
                }
            }

            GlassCard {
                VStack(alignment: .leading, spacing: 12) {
                    Text("Written Review")
                        .font(.system(.headline, design: .rounded, weight: .bold))
                        .foregroundStyle(AppTheme.textPrimary)

                    Text("Give enough detail to help the next student understand the brief, vibe, and grading tendency. Low-effort submissions stay blocked.")
                        .font(.system(.footnote, design: .rounded))
                        .foregroundStyle(AppTheme.textSecondary)

                    ZStack(alignment: .topLeading) {
                        RoundedRectangle(cornerRadius: 22, style: .continuous)
                            .fill(AppTheme.elevatedSurface)
                            .overlay(
                                RoundedRectangle(cornerRadius: 22, style: .continuous)
                                    .stroke(AppTheme.cardStroke.opacity(0.9), lineWidth: 1)
                            )

                        if viewModel.reviewText.isEmpty {
                            Text("How did the instructor brief, teach, and grade? What should another student know before the event?")
                                .font(.system(.body, design: .rounded))
                                .foregroundStyle(AppTheme.textSecondary.opacity(0.75))
                                .padding(.horizontal, 18)
                                .padding(.vertical, 16)
                        }

                        TextEditor(text: $viewModel.reviewText)
                            .scrollContentBackground(.hidden)
                            .frame(minHeight: 170)
                            .font(.system(.body, design: .rounded))
                            .foregroundStyle(AppTheme.textPrimary)
                            .padding(.horizontal, 14)
                            .padding(.vertical, 12)
                            .focused($focusedField, equals: .writtenReview)
                    }
                    .frame(minHeight: 170)

                    HStack {
                        Text(viewModel.remainingCharacters == 0 ? "Minimum met" : "\(viewModel.remainingCharacters) characters to go")
                            .font(.system(.footnote, design: .rounded, weight: .semibold))
                            .foregroundStyle(viewModel.remainingCharacters == 0 ? AppTheme.success : AppTheme.warning)

                        Spacer()

                        Text("\(viewModel.trimmedReviewText.count) chars")
                            .font(.system(.footnote, design: .rounded, weight: .medium))
                            .foregroundStyle(AppTheme.textSecondary)
                    }
                }
            }

            if let message = viewModel.errorMessage ?? (viewModel.hasAttemptedSubmit ? viewModel.validationMessage : nil) {
                Text(message)
                    .font(.system(.footnote, design: .rounded, weight: .semibold))
                    .foregroundStyle(AppTheme.warning)
                    .padding(.horizontal, 6)
            }

            InstructorPrimaryButton(
                title: "Submit For Moderation",
                icon: "paperplane.fill",
                enabled: viewModel.isValid
            ) {
                focusedField = nil
                viewModel.submit(using: reviewStore)
            }
        }
        .scrollActivatedNavigationChrome(title: "Submit Review")
        .toolbar {
            ToolbarItem(placement: .topBarLeading) {
                Button("Close") {
                    dismiss()
                }
            }
        }
        .task {
            viewModel.load(using: reviewStore)
        }
        .onChange(of: viewModel.instructorName) { _, _ in
            viewModel.refreshSuggestions(using: reviewStore)
        }
        .sheet(item: $activeSheet) { selection in
            switch selection {
            case .squadron:
                InstructorSelectionSheet(
                    title: "Select Squadron",
                    subtitle: "Choose the instructor's squadron.",
                    options: viewModel.squadrons,
                    selectedID: viewModel.selectedSquadron?.id
                ) { squadron in
                    viewModel.selectedSquadron = squadron
                } rowContent: { squadron in
                    VStack(alignment: .leading, spacing: 4) {
                        Text(squadron.displayName)
                            .font(.system(.body, design: .rounded, weight: .bold))
                            .foregroundStyle(AppTheme.textPrimary)
                        Text("Squadron")
                            .font(.system(.caption, design: .rounded, weight: .medium))
                            .foregroundStyle(AppTheme.textSecondary)
                    }
                }
            case .event:
                InstructorSelectionSheet(
                    title: "Select Event",
                    subtitle: "Choose the event tied to this review.",
                    options: viewModel.events,
                    selectedID: viewModel.selectedEvent?.id
                ) { event in
                    viewModel.selectedEvent = event
                } rowContent: { event in
                    VStack(alignment: .leading, spacing: 4) {
                        Text(event.displayName)
                            .font(.system(.body, design: .rounded, weight: .bold))
                            .foregroundStyle(AppTheme.textPrimary)
                        Text(event.kind.displayName)
                            .font(.system(.caption, design: .rounded, weight: .medium))
                            .foregroundStyle(event.kind == .sim ? AppTheme.warning : AppTheme.success)
                    }
                }
            case .chill:
                InstructorSelectionSheet(
                    title: "Select Chill Factor",
                    subtitle: "Choose the score that matches the event.",
                    options: viewModel.chillOptions,
                    selectedID: viewModel.chillScore.map { "chill-\($0)" }
                ) { option in
                    viewModel.chillScore = option.score
                } rowContent: { option in
                    VStack(alignment: .leading, spacing: 4) {
                        Text(option.title)
                            .font(.system(.body, design: .rounded, weight: .bold))
                            .foregroundStyle(AppTheme.textPrimary)
                        Text(option.subtitle)
                            .font(.system(.caption, design: .rounded, weight: .medium))
                            .foregroundStyle(AppTheme.textSecondary)
                    }
                }
            case .grading:
                InstructorSelectionSheet(
                    title: "Select Grading Style",
                    subtitle: "Choose the score that matches the event.",
                    options: viewModel.gradingOptions,
                    selectedID: viewModel.gradingScore.map { "grading-\($0)" }
                ) { option in
                    viewModel.gradingScore = option.score
                } rowContent: { option in
                    VStack(alignment: .leading, spacing: 4) {
                        Text(option.title)
                            .font(.system(.body, design: .rounded, weight: .bold))
                            .foregroundStyle(AppTheme.textPrimary)
                        Text(option.subtitle)
                            .font(.system(.caption, design: .rounded, weight: .medium))
                            .foregroundStyle(AppTheme.textSecondary)
                    }
                }
            }
        }
        .alert(
            "Review submitted",
            isPresented: Binding(
                get: { viewModel.didSubmit },
                set: { newValue in
                    if !newValue {
                        viewModel.acknowledgeSubmission()
                    }
                }
            )
        ) {
            Button("Done") {
                viewModel.acknowledgeSubmission()
                dismiss()
            }
        } message: {
            Text("Your write-up is saved as pending and won't show publicly until moderation approves it.")
        }
    }
}
