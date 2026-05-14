import SwiftUI

struct ReviewSubmissionView: View {
    private enum ActiveSelectionSheet: String, Identifiable {
        case squadron
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
            VStack(alignment: .leading, spacing: 8) {
                Text("Submit instructor gouge")
                    .font(.system(size: 28, weight: .bold, design: .rounded))
                    .foregroundStyle(AppTheme.textPrimary)

                Text("Start with the instructor, lock in whether this was a sim or flight review, then the form narrows the squadron and event choices for you.")
                    .font(.system(.body, design: .rounded))
                    .foregroundStyle(AppTheme.textSecondary)
            }

            GlassCard {
                VStack(alignment: .leading, spacing: 18) {
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

                    VStack(alignment: .leading, spacing: 10) {
                        Text("Review Type")
                            .font(.system(.caption, design: .rounded, weight: .bold))
                            .foregroundStyle(AppTheme.textMuted)
                            .tracking(0.6)

                        InstructorPillSelector(
                            options: InstructorSubmissionMode.allCases,
                            selected: viewModel.submissionMode,
                            title: \.title,
                            accent: \.color
                        ) { mode in
                            viewModel.submissionMode = mode
                        }
                    }

                    InstructorMenuPicker(
                        title: "Squadron",
                        placeholder: "Select squadron",
                        selection: viewModel.selectedSquadron?.displayName,
                        detail: viewModel.selectedSquadron?.reviewEventKind?.displayName,
                        accent: viewModel.selectedSquadron?.reviewEventKind?.domainColor ?? viewModel.submissionMode.color
                    ) {
                        activeSheet = .squadron
                    }

                    InstructorTextFieldCard(
                        title: "Event",
                        placeholder: viewModel.selectedSquadron == nil ? "Choose a squadron first" : "Type an event",
                        detail: viewModel.selectedSquadron == nil ? "Pick a squadron to narrow the event lane." : "Suggestions stay in the selected sim or flight lane.",
                        enabled: viewModel.selectedSquadron != nil,
                        text: $viewModel.eventName
                    )

                    if viewModel.selectedSquadron != nil, !viewModel.trimmedEventName.isEmpty {
                        VStack(alignment: .leading, spacing: 8) {
                            Text("Event Suggestions")
                                .font(.system(.footnote, design: .rounded, weight: .semibold))
                                .foregroundStyle(AppTheme.textSecondary)

                            ForEach(viewModel.eventSuggestions) { event in
                                Button {
                                    viewModel.applyEventSuggestion(event)
                                    focusedField = nil
                                } label: {
                                    HStack(spacing: 12) {
                                        Circle()
                                            .fill(event.kind.domainColor)
                                            .frame(width: 10, height: 10)

                                        VStack(alignment: .leading, spacing: 2) {
                                            Text(event.displayName)
                                                .font(.system(.subheadline, design: .rounded, weight: .bold))
                                                .foregroundStyle(AppTheme.textPrimary)

                                            Text(event.kind.displayName)
                                                .font(.system(.caption, design: .rounded, weight: .medium))
                                                .foregroundStyle(AppTheme.prominentText(event.kind.domainColor))
                                        }

                                        Spacer(minLength: 8)

                                        if viewModel.selectedEvent == event {
                                            Image(systemName: "checkmark.circle.fill")
                                                .font(.system(size: 16, weight: .bold))
                                                .foregroundStyle(event.kind.domainColor)
                                        }
                                    }
                                    .padding(.horizontal, 14)
                                    .padding(.vertical, 12)
                                    .background(
                                        RoundedRectangle(cornerRadius: 18, style: .continuous)
                                            .fill(AppTheme.elevatedSurface)
                                            .overlay(
                                                RoundedRectangle(cornerRadius: 18, style: .continuous)
                                                    .stroke(viewModel.selectedEvent == event ? AppTheme.badgeStroke(event.kind.domainColor) : AppTheme.cardStroke.opacity(0.9), lineWidth: 1)
                                            )
                                    )
                                }
                                .buttonStyle(.plain)
                            }

                            if !viewModel.eventHasExactSuggestionMatch {
                                Button {
                                    viewModel.selectedEvent = nil
                                } label: {
                                    HStack(spacing: 12) {
                                        Image(systemName: "keyboard")
                                            .font(.system(size: 14, weight: .bold))
                                            .foregroundStyle(viewModel.selectedSquadron?.reviewEventKind?.domainColor ?? viewModel.submissionMode.color)

                                        VStack(alignment: .leading, spacing: 2) {
                                            Text("Use \"\(viewModel.trimmedEventName)\"")
                                                .font(.system(.subheadline, design: .rounded, weight: .bold))
                                                .foregroundStyle(AppTheme.textPrimary)

                                            Text("Custom event")
                                                .font(.system(.caption, design: .rounded, weight: .medium))
                                                .foregroundStyle(AppTheme.textSecondary)
                                        }

                                        Spacer(minLength: 8)
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
                        title: "Chill Factor",
                        placeholder: viewModel.canChooseRatings ? "Select chill factor" : "Choose an event first",
                        selection: viewModel.chillScore.map { InstructorRatingScale.label(for: $0, category: .chillFactor) },
                        detail: viewModel.chillScore.map {
                            "Score \(InstructorRatingScale.format(average: InstructorRatingScale.tenScaleValue(for: Double($0)))) / 10"
                        },
                        accent: AppTheme.success,
                        enabled: viewModel.canChooseRatings
                    ) {
                        activeSheet = .chill
                    }

                    InstructorMenuPicker(
                        title: "Grading Style",
                        placeholder: viewModel.canChooseRatings ? "Select grading style" : "Choose an event first",
                        selection: viewModel.gradingScore.map { InstructorRatingScale.label(for: $0, category: .gradingStyle) },
                        detail: viewModel.gradingScore.map {
                            "Score \(InstructorRatingScale.format(average: InstructorRatingScale.tenScaleValue(for: Double($0)))) / 10"
                        },
                        accent: AppTheme.warning,
                        enabled: viewModel.canChooseRatings
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

                    HStack(alignment: .top, spacing: 10) {
                        Image(systemName: "exclamationmark.triangle.fill")
                            .font(.system(size: 13, weight: .bold))
                            .foregroundStyle(AppTheme.danger)
                            .padding(.top, 1)

                        Text("Profanity, slurs, threats, and abusive content will not be posted. Submissions that cross the line stay blocked in moderation.")
                            .font(.system(.footnote, design: .rounded, weight: .semibold))
                            .foregroundStyle(AppTheme.danger)
                            .fixedSize(horizontal: false, vertical: true)
                    }
                    .padding(.top, 2)
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
        .detailNavigationChrome(title: "Submit Review")
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
                InstructorSearchableSelectionSheet(
                    title: "Select Squadron",
                    subtitle: "Choose the instructor's squadron for this review type.",
                    searchPlaceholder: "Search squadrons",
                    emptyMessage: "Try a different squadron search or widen the review type.",
                    options: viewModel.visibleSquadrons,
                    selectedID: viewModel.selectedSquadron?.id,
                    searchableText: { squadron in
                        squadron.displayName
                    },
                    accent: { squadron in
                        squadron.reviewEventKind?.domainColor ?? viewModel.submissionMode.color
                    },
                    onSelect: { squadron in
                        viewModel.selectedSquadron = squadron
                    }
                ) { squadron in
                    HStack(spacing: 12) {
                        Circle()
                            .fill(squadron.reviewEventKind?.domainColor ?? viewModel.submissionMode.color)
                            .frame(width: 10, height: 10)

                        VStack(alignment: .leading, spacing: 4) {
                            Text(squadron.displayName)
                                .font(.system(.body, design: .rounded, weight: .bold))
                                .foregroundStyle(AppTheme.textPrimary)
                            Text(squadron.reviewEventKind?.displayName ?? "Squadron")
                                .font(.system(.caption, design: .rounded, weight: .medium))
                                .foregroundStyle(AppTheme.textSecondary)
                        }
                    }
                }
            case .chill:
                InstructorSelectionSheet(
                    title: "Select Chill Factor",
                    subtitle: "Choose the score that matches the event.",
                    options: viewModel.chillOptions,
                    selectedID: viewModel.chillScore.map { "chill-\($0)" },
                    accent: { option in
                        option.accent
                    },
                    onSelect: { option in
                        viewModel.chillScore = option.score
                    }
                ) { option in
                    HStack(spacing: 12) {
                        Circle()
                            .fill(option.accent)
                            .frame(width: 10, height: 10)

                        VStack(alignment: .leading, spacing: 4) {
                            Text(option.title)
                                .font(.system(.body, design: .rounded, weight: .bold))
                                .foregroundStyle(AppTheme.textPrimary)
                            Text(option.subtitle)
                                .font(.system(.caption, design: .rounded, weight: .medium))
                                .foregroundStyle(AppTheme.prominentText(option.accent))
                        }
                    }
                }
            case .grading:
                InstructorSelectionSheet(
                    title: "Select Grading Style",
                    subtitle: "Choose the score that matches the event.",
                    options: viewModel.gradingOptions,
                    selectedID: viewModel.gradingScore.map { "grading-\($0)" },
                    accent: { option in
                        option.accent
                    },
                    onSelect: { option in
                        viewModel.gradingScore = option.score
                    }
                ) { option in
                    HStack(spacing: 12) {
                        Circle()
                            .fill(option.accent)
                            .frame(width: 10, height: 10)

                        VStack(alignment: .leading, spacing: 4) {
                            Text(option.title)
                                .font(.system(.body, design: .rounded, weight: .bold))
                                .foregroundStyle(AppTheme.textPrimary)
                            Text(option.subtitle)
                                .font(.system(.caption, design: .rounded, weight: .medium))
                                .foregroundStyle(AppTheme.prominentText(option.accent))
                        }
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
