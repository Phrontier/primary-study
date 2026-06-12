import SwiftUI
import Combine

struct ModerationQueueView: View {
    @Environment(\.dismiss) private var dismiss
    @EnvironmentObject private var accountStore: AccountStore
    @EnvironmentObject private var reviewStore: InstructorReviewStore
    @StateObject private var viewModel = ModerationQueueViewModel()
    @State private var email = ""
    @State private var password = ""
    @State private var authErrorMessage: String?
    @State private var signingIn = false

    var body: some View {
        AppScrollScreen(bottomPadding: 36) {
            HeroCard(
                eyebrow: "Moderation",
                title: "Review queue",
                subtitle: heroSubtitle,
                accessory: {
                    if accountStore.hasPermission(.instructorGougeModerator) {
                        StatusBadge(title: "Role Active", iconName: "checkmark.shield.fill", color: AppTheme.success)
                    }
                }
            ) {
                if canModerate {
                    HStack(spacing: 12) {
                        MetricChip(label: "Pending", value: "\(viewModel.pendingReviews.count)", color: AppTheme.warning)
                        MetricChip(label: "Reports", value: "\(viewModel.openReports.count)", color: AppTheme.danger)
                        MetricChip(label: "Inbox", value: "\(viewModel.openCommunitySubmissions.count)", color: MoreSectionColor.support)
                    }
                }
            }

            if let message = activeErrorMessage {
                Text(message)
                    .font(.footnote.weight(.semibold))
                    .foregroundStyle(AppTheme.warning)
                    .padding(.horizontal, 6)
            }

            if !canModerate {
                EmptyStateCard(
                    icon: "lock.shield.fill",
                    title: "Moderator Permission Required",
                    message: "This account does not have instructor gouge moderator access."
                )
            } else if viewModel.pendingReviews.isEmpty && viewModel.openReports.isEmpty && viewModel.openCommunitySubmissions.isEmpty {
                EmptyStateCard(
                    icon: "checkmark.seal.fill",
                    title: "Queue is clear",
                    message: "There are no pending reviews, gouge reports, or community submissions waiting on moderation right now."
                )
            } else {
                VStack(alignment: .leading, spacing: 20) {
                    if !viewModel.pendingReviews.isEmpty {
                        VStack(alignment: .leading, spacing: 14) {
                            SectionHeader(
                                eyebrow: "Moderation",
                                title: "Pending Reviews",
                                subtitle: nil,
                                accent: AppTheme.warning
                            )

                            ForEach(viewModel.pendingReviews) { review in
                                pendingReviewCard(review)
                            }
                        }
                    }

                    if !viewModel.openReports.isEmpty {
                        VStack(alignment: .leading, spacing: 14) {
                            SectionHeader(
                                eyebrow: "Moderation",
                                title: "Reported Gouge",
                                subtitle: nil,
                                accent: AppTheme.danger
                            )

                            ForEach(viewModel.openReports) { report in
                                reportCard(report)
                            }
                        }
                    }

                    if !viewModel.openCommunitySubmissions.isEmpty {
                        VStack(alignment: .leading, spacing: 14) {
                            SectionHeader(
                                eyebrow: "Moderation",
                                title: "Community Inbox",
                                subtitle: nil,
                                accent: MoreSectionColor.support
                            )

                            ForEach(viewModel.openCommunitySubmissions) { submission in
                                communitySubmissionCard(submission)
                            }
                        }
                    }
                }
            }
        }
        .detailNavigationChrome(title: "Moderation")
        .toolbar {
            ToolbarItem(placement: .topBarLeading) {
                Button("Close") {
                    dismiss()
                }
            }
        }
        .task {
            reviewStore.setModeratorPermission(accountStore.hasPermission(.instructorGougeModerator))
            viewModel.load(using: reviewStore)
        }
        .onReceive(reviewStore.$revision.dropFirst()) { _ in
            viewModel.load(using: reviewStore)
        }
    }

    private var canModerate: Bool {
        accountStore.hasPermission(.instructorGougeModerator)
    }

    private var heroSubtitle: String {
        if accountStore.hasPermission(.instructorGougeModerator) {
            return "Signed in as \(accountStore.profile?.email ?? accountStore.profile?.id ?? "moderator")."
        }
        return "Moderator access is assigned to a Primary Gouge account in Cloudflare."
    }

    private var activeErrorMessage: String? {
        viewModel.errorMessage
    }

    private var signInCard: some View {
        SectionContainer {
            VStack(alignment: .leading, spacing: 16) {
                Text("Moderator Sign In")
                    .font(.headline.weight(.semibold))
                    .foregroundStyle(AppTheme.textPrimary)

                Text("Use your moderator account to review queued instructor gouge and community inbox submissions from every device.")
                    .font(.subheadline)
                    .foregroundStyle(AppTheme.textSecondary)

                authField(title: "Email", placeholder: "moderator@example.com", text: $email, secure: false)
                authField(title: "Password", placeholder: "Password", text: $password, secure: true)

                InstructorPrimaryButton(
                    title: signingIn ? "Signing In…" : "Sign In to Moderate",
                    icon: "checkmark.shield.fill",
                    enabled: !signingIn && !email.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty && !password.isEmpty
                ) {
                    signIn()
                }
            }
        }
    }

    @ViewBuilder
    private func authField(title: String, placeholder: String, text: Binding<String>, secure: Bool) -> some View {
        VStack(alignment: .leading, spacing: 10) {
            Text(title.uppercased())
                .font(.system(.caption, design: .rounded, weight: .bold))
                .foregroundStyle(AppTheme.textMuted)
                .tracking(0.6)

            Group {
                if secure {
                    SecureField(placeholder, text: text)
                        .textContentType(.password)
                } else {
                    TextField(placeholder, text: text)
                        .textInputAutocapitalization(.never)
                        .autocorrectionDisabled()
                        .textContentType(.username)
                        .keyboardType(.emailAddress)
                }
            }
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

    private func signIn() {
        authErrorMessage = nil
        signingIn = true

        Task { @MainActor in
            defer { signingIn = false }
            do {
                try await reviewStore.signInModerator(
                    email: email.trimmingCharacters(in: .whitespacesAndNewlines),
                    password: password
                )
                password = ""
                viewModel.load(using: reviewStore)
            } catch {
                authErrorMessage = error.localizedDescription
            }
        }
    }

    private func pendingReviewCard(_ review: InstructorReview) -> some View {
        SectionContainer {
            VStack(alignment: .leading, spacing: 16) {
                HStack(alignment: .top) {
                    VStack(alignment: .leading, spacing: 4) {
                        Text(review.instructorName)
                            .font(.headline.weight(.semibold))
                            .foregroundStyle(AppTheme.textPrimary)

                        Text(review.squadron.displayName)
                            .font(.subheadline)
                            .foregroundStyle(AppTheme.textSecondary)
                    }

                    Spacer(minLength: 12)

                    VStack(alignment: .trailing, spacing: 4) {
                        if let eventName = review.eventName {
                            Text(eventName)
                                .font(.footnote.weight(.semibold))
                                .foregroundStyle(AppTheme.accent)
                        }

                        Text(review.eventKind.displayName)
                            .font(.caption.weight(.semibold))
                            .foregroundStyle(AppTheme.accentSoft)

                        Text(review.submittedAt.formatted(date: .abbreviated, time: .shortened))
                            .font(.caption)
                            .foregroundStyle(AppTheme.textSecondary)
                    }
                }

                HStack(spacing: 12) {
                    InstructorRatingBadge(
                        title: "Chill Factor",
                        label: InstructorRatingScale.label(for: review.chillScore, category: .chillFactor),
                        subtitle: InstructorRatingScale.formatOutOfTen(score: review.chillScore),
                        score: review.chillScore,
                        style: .individual
                    )
                    InstructorRatingBadge(
                        title: "Grading Style",
                        label: InstructorRatingScale.label(for: review.gradingScore, category: .gradingStyle),
                        subtitle: InstructorRatingScale.formatOutOfTen(score: review.gradingScore),
                        score: review.gradingScore,
                        style: .individual
                    )
                }

                Text(review.reviewText)
                    .font(.body)
                    .foregroundStyle(AppTheme.textSecondary)
                    .fixedSize(horizontal: false, vertical: true)

                HStack(spacing: 12) {
                    Button {
                        viewModel.reject(reviewID: review.id, using: reviewStore)
                    } label: {
                        StudyActionButton(title: "Reject", icon: "xmark", tint: AppTheme.danger, isProminent: false)
                    }
                    .buttonStyle(.plain)
                    .disabled(viewModel.processingIDs.contains(review.id))

                    Button {
                        viewModel.approve(reviewID: review.id, using: reviewStore)
                    } label: {
                        StudyActionButton(title: "Approve", icon: "checkmark", tint: AppTheme.success, isProminent: false)
                    }
                    .buttonStyle(.plain)
                    .disabled(viewModel.processingIDs.contains(review.id))
                }
            }
        }
    }

    private func reportCard(_ report: InstructorGougeReport) -> some View {
        SectionContainer {
            VStack(alignment: .leading, spacing: 16) {
                HStack(alignment: .top, spacing: 12) {
                    VStack(alignment: .leading, spacing: 4) {
                        Text(report.instructorName)
                            .font(.headline.weight(.semibold))
                            .foregroundStyle(AppTheme.textPrimary)

                        HStack(spacing: 8) {
                            Text(report.squadron.displayName)
                                .font(.subheadline)
                                .foregroundStyle(AppTheme.textSecondary)

                            Text(report.targetKind.displayName.uppercased())
                                .font(.caption2.weight(.bold))
                                .foregroundStyle(AppTheme.prominentText(AppTheme.danger))
                                .padding(.horizontal, 8)
                                .padding(.vertical, 5)
                                .background(
                                    Capsule()
                                        .fill(AppTheme.badgeFill(AppTheme.danger))
                                        .overlay(
                                            Capsule()
                                                .stroke(AppTheme.badgeStroke(AppTheme.danger), lineWidth: 1)
                                        )
                                )
                        }
                    }

                    Spacer(minLength: 12)

                    Text(report.submittedAt.formatted(date: .abbreviated, time: .shortened))
                        .font(.caption)
                        .foregroundStyle(AppTheme.textSecondary)
                }

                if let eventName = report.eventName, let eventKind = report.eventKind {
                    HStack(spacing: 8) {
                        Text(eventKind.displayName.uppercased())
                            .font(.system(.caption2, design: .rounded, weight: .bold))
                            .foregroundStyle(AppTheme.prominentText(eventKind.domainColor))
                            .padding(.horizontal, 9)
                            .padding(.vertical, 6)
                            .background(
                                Capsule()
                                    .fill(AppTheme.badgeFill(eventKind.domainColor))
                                    .overlay(
                                        Capsule()
                                            .stroke(AppTheme.badgeStroke(eventKind.domainColor), lineWidth: 1)
                                    )
                            )

                        Text(eventName)
                            .font(.footnote.weight(.semibold))
                            .foregroundStyle(AppTheme.textSecondary)
                    }
                }

                VStack(alignment: .leading, spacing: 8) {
                    reportRow(title: "Reason", value: report.reasonTitle)

                    if let note = report.note, !note.isEmpty {
                        reportRow(title: "Note", value: note)
                    }

                    if let reviewText = report.reviewText, !reviewText.isEmpty {
                        reportRow(title: "Reported Review", value: reviewText)
                    }
                }

                HStack(spacing: 12) {
                    Button {
                        viewModel.dismissReport(reportID: report.id, using: reviewStore)
                    } label: {
                        StudyActionButton(title: "Dismiss Report", icon: "checkmark", tint: AppTheme.warning, isProminent: false)
                    }
                    .buttonStyle(.plain)
                    .disabled(viewModel.processingIDs.contains(report.id))

                    if let reviewID = report.reviewID {
                        Button {
                            viewModel.reject(reviewID: reviewID, using: reviewStore)
                        } label: {
                            StudyActionButton(title: "Reject Review", icon: "xmark", tint: AppTheme.danger, isProminent: false)
                        }
                        .buttonStyle(.plain)
                        .disabled(viewModel.processingIDs.contains(reviewID))
                    }
                }
            }
        }
    }

    private func reportRow(title: String, value: String) -> some View {
        VStack(alignment: .leading, spacing: 4) {
            Text(title.uppercased())
                .font(.caption2.weight(.bold))
                .foregroundStyle(AppTheme.textMuted)
                .tracking(0.6)

            Text(value)
                .font(.body)
                .foregroundStyle(AppTheme.textSecondary)
                .fixedSize(horizontal: false, vertical: true)
        }
    }

    private func communitySubmissionCard(_ submission: CommunitySubmissionModerationItem) -> some View {
        SectionContainer {
            VStack(alignment: .leading, spacing: 16) {
                HStack(alignment: .top, spacing: 12) {
                    VStack(alignment: .leading, spacing: 4) {
                        Text(submission.summary)
                            .font(.headline.weight(.semibold))
                            .foregroundStyle(AppTheme.textPrimary)

                        HStack(spacing: 8) {
                            Text(submission.category.title)
                                .font(.subheadline)
                                .foregroundStyle(AppTheme.textSecondary)

                            Text(submission.status.title.uppercased())
                                .font(.caption2.weight(.bold))
                                .foregroundStyle(AppTheme.prominentText(submission.category.accentColor))
                                .padding(.horizontal, 8)
                                .padding(.vertical, 5)
                                .background(
                                    Capsule()
                                        .fill(AppTheme.badgeFill(submission.category.accentColor))
                                        .overlay(
                                            Capsule()
                                                .stroke(AppTheme.badgeStroke(submission.category.accentColor), lineWidth: 1)
                                        )
                                )
                        }
                    }

                    Spacer(minLength: 12)

                    Text(submission.submittedAt.formatted(date: .abbreviated, time: .shortened))
                        .font(.caption)
                        .foregroundStyle(AppTheme.textSecondary)
                }

                Text(submission.message)
                    .font(.body)
                    .foregroundStyle(AppTheme.textSecondary)
                    .fixedSize(horizontal: false, vertical: true)

                if let targetSummary = submission.targetSummary {
                    reportRow(title: "Target", value: targetSummary)
                }

                if let contactEmail = submission.contactEmail, !contactEmail.isEmpty {
                    reportRow(title: "Contact", value: contactEmail)
                }

                reportRow(title: "App Build", value: [submission.appVersion, submission.buildNumber].compactMap { $0 }.joined(separator: " • "))

                HStack(spacing: 12) {
                    Button {
                        viewModel.dismissCommunitySubmission(submissionID: submission.id, using: reviewStore)
                    } label: {
                        StudyActionButton(title: "Dismiss", icon: "xmark", tint: AppTheme.warning, isProminent: false)
                    }
                    .buttonStyle(.plain)
                    .disabled(viewModel.processingIDs.contains(submission.id))

                    Button {
                        viewModel.resolveCommunitySubmission(submissionID: submission.id, using: reviewStore)
                    } label: {
                        StudyActionButton(title: "Resolve", icon: "checkmark", tint: AppTheme.success, isProminent: false)
                    }
                    .buttonStyle(.plain)
                    .disabled(viewModel.processingIDs.contains(submission.id))
                }
            }
        }
    }
}
