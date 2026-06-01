import SwiftUI

struct MoreCommunitySubmissionView: View {
    let category: CommunitySubmissionCategory
    let lockedTarget: CommunitySubmissionDraft?

    @EnvironmentObject private var communityStore: CommunitySubmissionStore
    @State private var draft = CommunitySubmissionDraft()
    @State private var didLoadDraft = false
    @State private var feedbackMessage: String?
    @State private var errorMessage: String?
    @State private var isSubmitting = false

    init(category: CommunitySubmissionCategory, lockedTarget: CommunitySubmissionDraft? = nil) {
        self.category = category
        self.lockedTarget = lockedTarget
    }

    private var submissions: [CommunitySubmissionRecord] {
        communityStore.submissions(for: category, limit: 6)
    }

    private var effectiveDraft: CommunitySubmissionDraft {
        if let lockedTarget {
            var merged = draft
            merged.targetKind = lockedTarget.targetKind
            merged.targetID = lockedTarget.targetID
            merged.targetTitle = lockedTarget.targetTitle
            merged.targetContext = lockedTarget.targetContext
            return merged
        }
        return draft
    }

    private var syncMessage: String {
        switch communityStore.syncStatus.phase {
        case .idle:
            return "Submissions sync through the shared Cloudflare inbox when the backend is available."
        case .syncing:
            return "Syncing queued submissions with Cloudflare."
        case .offline:
            if communityStore.isRemoteConfigured {
                return "Submissions can still be saved locally and will retry when the device is back online."
            }
            return "The backend is not configured right now, so submissions will stay queued locally until that changes."
        case .failed:
            return communityStore.syncStatus.errorMessage ?? "The last sync attempt failed. Saved submissions will retry automatically."
        }
    }

    private var syncStatusColor: Color {
        switch communityStore.syncStatus.phase {
        case .idle:
            return AppTheme.success
        case .syncing:
            return AppTheme.accent
        case .offline:
            return AppTheme.warning
        case .failed:
            return AppTheme.danger
        }
    }

    private var syncStatusTitle: String {
        switch communityStore.syncStatus.phase {
        case .idle:
            return "Ready"
        case .syncing:
            return "Syncing"
        case .offline:
            return "Queued"
        case .failed:
            return "Retrying"
        }
    }

    var body: some View {
        AppScrollScreen(topPadding: 20, bottomPadding: 32) {
            VStack(alignment: .leading, spacing: 18) {
                HeroCard(
                    eyebrow: category.eyebrow,
                    title: category.formTitle,
                    subtitle: category.formSubtitle,
                    accent: category.accentColor
                ) {
                    StatusBadge(
                        title: syncStatusTitle,
                        iconName: category.iconName,
                        color: syncStatusColor
                    )
                } content: {
                    Text(syncMessage)
                        .font(.subheadline)
                        .foregroundStyle(AppTheme.textSecondary)
                        .fixedSize(horizontal: false, vertical: true)
                }

                VStack(alignment: .leading, spacing: 12) {
                    SectionHeader(
                        eyebrow: category.eyebrow,
                        title: "Submission details",
                        subtitle: nil,
                        accent: category.accentColor
                    )

                    SectionContainer(style: .standard, accent: category.accentColor, contentPadding: 18) {
                        VStack(alignment: .leading, spacing: 16) {
                            MoreLabeledField(title: "Summary") {
                                MoreEntryTextField(text: $draft.summary, prompt: category.summaryPrompt)
                            }

                            MoreLabeledField(title: "Details") {
                                MoreEntryTextEditor(text: $draft.message, prompt: category.messagePrompt)
                            }
                        }
                    }
                }

                if category == .incorrectGouge {
                    targetSection
                }

                VStack(alignment: .leading, spacing: 12) {
                    SectionHeader(
                        eyebrow: "Follow up",
                        title: "Contact email",
                        subtitle: nil,
                        accent: category.accentColor
                    )

                    SectionContainer(style: .standard, accent: category.accentColor, contentPadding: 18) {
                        VStack(alignment: .leading, spacing: 12) {
                            Text("Optional. Add an email if you want follow-up about this submission.")
                                .font(.footnote)
                                .foregroundStyle(AppTheme.textSecondary)
                                .fixedSize(horizontal: false, vertical: true)

                            MoreEntryTextField(text: $draft.contactEmail, prompt: "name@example.com")
                                .keyboardType(.emailAddress)
                                .textInputAutocapitalization(.never)
                                .autocorrectionDisabled()
                        }
                    }
                }

                if let feedbackMessage {
                    submissionBanner(message: feedbackMessage, color: AppTheme.success, iconName: "checkmark.circle.fill")
                }

                if let errorMessage {
                    submissionBanner(message: errorMessage, color: AppTheme.warning, iconName: "exclamationmark.triangle.fill")
                }

                Button {
                    submit()
                } label: {
                    StudyActionButton(
                        title: isSubmitting ? "Saving…" : category.submitButtonTitle,
                        icon: category.iconName,
                        tint: category.accentColor,
                        isProminent: true
                    )
                }
                .buttonStyle(.plain)
                .disabled(isSubmitting)

                VStack(alignment: .leading, spacing: 12) {
                    SectionHeader(
                        eyebrow: category.eyebrow,
                        title: "Recent submissions",
                        subtitle: nil,
                        accent: category.accentColor
                    )

                    if submissions.isEmpty {
                        EmptyStateCard(
                            icon: category.iconName,
                            title: category.emptyStateTitle,
                            message: category.emptyStateMessage
                        )
                    } else {
                        MoreSectionContainer {
                            ForEach(Array(submissions.enumerated()), id: \.element.id) { index, submission in
                                CommunitySubmissionHistoryRow(submission: submission)

                                if index < submissions.count - 1 {
                                    Divider()
                                        .overlay(AppTheme.cardStroke.opacity(0.9))
                                        .padding(.leading, 62)
                                }
                            }
                        }
                    }
                }
            }
        }
        .detailNavigationChrome(title: category.title)
        .task {
            loadDraftIfNeeded()
        }
        .onChange(of: draft) { _, newDraft in
            guard didLoadDraft else { return }
            communityStore.saveDraft(mergedWithLockedTarget(newDraft), for: category)
        }
    }

    private var targetSection: some View {
        VStack(alignment: .leading, spacing: 12) {
            SectionHeader(
                eyebrow: "Accuracy",
                title: "Content target",
                subtitle: nil,
                accent: AppTheme.danger
            )

            SectionContainer(style: .standard, accent: AppTheme.danger, contentPadding: 18) {
                VStack(alignment: .leading, spacing: 16) {
                    Text("Optional. If you know exactly what needs correction, add the content type and where it lives.")
                        .font(.footnote)
                        .foregroundStyle(AppTheme.textSecondary)
                        .fixedSize(horizontal: false, vertical: true)

                    MoreLabeledField(title: "Content type") {
                        Picker("Content type", selection: $draft.targetKind) {
                            Text("Not specified").tag(Optional<CommunitySubmissionTargetKind>.none)
                            ForEach(CommunitySubmissionTargetKind.allCases) { targetKind in
                                Text(targetKind.title).tag(Optional(targetKind))
                            }
                        }
                        .pickerStyle(.menu)
                        .tint(AppTheme.textPrimary)
                        .disabled(lockedTarget != nil)
                    }

                    MoreLabeledField(title: "Title or identifier") {
                        MoreEntryTextField(
                            text: lockedTarget == nil ? $draft.targetTitle : .constant(draft.targetTitle),
                            prompt: "Example: Contact IFG or Form deck"
                        )
                        .disabled(lockedTarget != nil)
                    }

                    MoreLabeledField(title: "Location or context") {
                        MoreEntryTextField(
                            text: lockedTarget == nil ? $draft.targetContext : .constant(draft.targetContext),
                            prompt: "Example: General Library, Formation, or page/section"
                        )
                        .disabled(lockedTarget != nil)
                    }
                }
            }
        }
    }

    private func loadDraftIfNeeded() {
        guard !didLoadDraft else { return }
        draft = communityStore.draft(for: category)
        draft = mergedWithLockedTarget(draft)
        didLoadDraft = true
    }

    private func mergedWithLockedTarget(_ source: CommunitySubmissionDraft) -> CommunitySubmissionDraft {
        guard let lockedTarget else { return source }
        var merged = source
        merged.targetKind = lockedTarget.targetKind
        merged.targetID = lockedTarget.targetID
        merged.targetTitle = lockedTarget.targetTitle
        merged.targetContext = lockedTarget.targetContext
        return merged
    }

    @ViewBuilder
    private func submissionBanner(message: String, color: Color, iconName: String) -> some View {
        SectionContainer(style: .standard, accent: color, contentPadding: 16) {
            HStack(alignment: .center, spacing: 12) {
                Image(systemName: iconName)
                    .font(.system(size: 16, weight: .semibold))
                    .foregroundStyle(color)

                Text(message)
                    .font(.subheadline.weight(.semibold))
                    .foregroundStyle(AppTheme.textPrimary)
                    .fixedSize(horizontal: false, vertical: true)
            }
        }
    }

    private func submit() {
        errorMessage = nil
        feedbackMessage = nil
        isSubmitting = true

        defer { isSubmitting = false }

        do {
            let record = try communityStore.submit(
                category: category,
                draft: effectiveDraft,
                lockedTarget: lockedTarget
            )
            draft = CommunitySubmissionDraft()
            draft = mergedWithLockedTarget(draft)
            feedbackMessage = category.successMessage
            if record.syncState == .queuedUpload && communityStore.syncStatus.phase != .idle {
                feedbackMessage = "\(category.successMessage) It will upload when the backend is reachable."
            }
        } catch {
            errorMessage = error.localizedDescription
        }
    }
}

private struct MoreLabeledField<Content: View>: View {
    let title: String
    @ViewBuilder let content: Content

    init(title: String, @ViewBuilder content: () -> Content) {
        self.title = title
        self.content = content()
    }

    var body: some View {
        VStack(alignment: .leading, spacing: 10) {
            Text(title.uppercased())
                .font(.system(.caption, design: .rounded, weight: .bold))
                .foregroundStyle(AppTheme.textMuted)
                .tracking(0.6)

            content
        }
    }
}

private struct MoreEntryTextField: View {
    @Binding var text: String
    let prompt: String

    var body: some View {
        TextField(prompt, text: $text)
            .font(.system(.body, design: .rounded, weight: .semibold))
            .foregroundStyle(AppTheme.textPrimary)
            .padding(.horizontal, 16)
            .padding(.vertical, 16)
            .frame(minHeight: 56)
            .background(
                RoundedRectangle(cornerRadius: 18, style: .continuous)
                    .fill(AppTheme.elevatedSurface)
                    .overlay(
                        RoundedRectangle(cornerRadius: 18, style: .continuous)
                            .stroke(AppTheme.cardStroke.opacity(0.9), lineWidth: 1)
                    )
            )
    }
}

private struct MoreEntryTextEditor: View {
    @Binding var text: String
    let prompt: String

    var body: some View {
        ZStack(alignment: .topLeading) {
            RoundedRectangle(cornerRadius: 22, style: .continuous)
                .fill(AppTheme.elevatedSurface)
                .overlay(
                    RoundedRectangle(cornerRadius: 22, style: .continuous)
                        .stroke(AppTheme.cardStroke.opacity(0.9), lineWidth: 1)
                )

            if text.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty {
                Text(prompt)
                    .font(.system(.body, design: .rounded))
                    .foregroundStyle(AppTheme.textSecondary.opacity(0.75))
                    .padding(.horizontal, 18)
                    .padding(.vertical, 16)
            }

            TextEditor(text: $text)
                .scrollContentBackground(.hidden)
                .frame(minHeight: 140)
                .font(.system(.body, design: .rounded))
                .foregroundStyle(AppTheme.textPrimary)
                .padding(.horizontal, 14)
                .padding(.vertical, 12)
        }
        .frame(minHeight: 140)
    }
}

private struct CommunitySubmissionHistoryRow: View {
    let submission: CommunitySubmissionRecord

    var body: some View {
        HStack(alignment: .top, spacing: 14) {
            ZStack {
                RoundedRectangle(cornerRadius: 12, style: .continuous)
                    .fill(AppTheme.semanticTint(submission.category.accentColor, opacity: 0.16))
                    .frame(width: 36, height: 36)
                    .overlay(
                        RoundedRectangle(cornerRadius: 12, style: .continuous)
                            .stroke(submission.category.accentColor.opacity(0.16), lineWidth: 1)
                    )

                Image(systemName: submission.category.iconName)
                    .font(.system(size: 15, weight: .semibold))
                    .foregroundStyle(submission.category.accentColor)
            }

            VStack(alignment: .leading, spacing: 6) {
                Text(submission.summary)
                    .font(.body.weight(.semibold))
                    .foregroundStyle(AppTheme.textPrimary)

                Text(submission.submittedAt.formatted(date: .abbreviated, time: .shortened))
                    .font(.footnote.weight(.semibold))
                    .foregroundStyle(AppTheme.textSecondary)

                if let targetSummary = submission.targetSummary {
                    Text(targetSummary)
                        .font(.footnote)
                        .foregroundStyle(AppTheme.textSecondary)
                        .fixedSize(horizontal: false, vertical: true)
                }

                Text(submission.statusDetail)
                    .font(.footnote)
                    .foregroundStyle(AppTheme.textSecondary)
                    .fixedSize(horizontal: false, vertical: true)
            }

            Spacer(minLength: 8)

            VStack(alignment: .trailing, spacing: 8) {
                StatusBadge(
                    title: submission.syncState.title,
                    iconName: "tray.and.arrow.up.fill",
                    color: submission.syncState.color
                )

                StatusBadge(
                    title: submission.status.title,
                    iconName: "clock.badge.checkmark.fill",
                    color: submission.status.color
                )
            }
        }
        .padding(.horizontal, 14)
        .padding(.vertical, 13)
    }
}
