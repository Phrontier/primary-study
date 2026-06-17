import SwiftUI

struct MoreCommunitySubmissionView: View {
    let category: CommunitySubmissionCategory
    let lockedTarget: CommunitySubmissionDraft?

    @EnvironmentObject private var accountStore: AccountStore
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

    private var canSubmit: Bool {
        accountStore.isSignedIn && !isSubmitting
    }

    var body: some View {
        AppScrollScreen(topPadding: 20, bottomPadding: 32) {
            VStack(alignment: .leading, spacing: 18) {
                MoreHeaderCard(accent: category.accentColor) {
                    HStack(alignment: .center, spacing: 14) {
                        MoreHeaderTextBlock(
                            eyebrow: category.eyebrow,
                            title: category.formTitle,
                            subtitle: category.formSubtitle,
                            accent: category.accentColor
                        )
                    }
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

                if !accountStore.isSignedIn {
                    submissionBanner(
                        message: "Sign in to send this request.",
                        color: category.accentColor,
                        iconName: "person.crop.circle.badge.exclamationmark"
                    )
                }

                Button {
                    submit()
                } label: {
                    StudyActionButton(
                        title: isSubmitting ? "Sending…" : (accountStore.isSignedIn ? category.submitButtonTitle : "Sign In To Send"),
                        icon: category.iconName,
                        tint: category.accentColor,
                        isProminent: true
                    )
                }
                .buttonStyle(.plain)
                .disabled(!canSubmit)
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
                    Text("If you know exactly what needs attention, add what it is and where it lives.")
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
            _ = try communityStore.submit(
                category: category,
                draft: effectiveDraft,
                lockedTarget: lockedTarget
            )
            draft = CommunitySubmissionDraft()
            draft = mergedWithLockedTarget(draft)
            feedbackMessage = category.successMessage
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
