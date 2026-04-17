import SwiftUI
import Combine

struct ModerationQueueView: View {
    @Environment(\.dismiss) private var dismiss
    @EnvironmentObject private var reviewStore: InstructorReviewStore
    @StateObject private var viewModel = ModerationQueueViewModel()

    var body: some View {
        AppScrollScreen(bottomPadding: 36) {
            HeroCard(
                eyebrow: "Moderation",
                title: "Review queue",
                subtitle: "Pending reviews stay out of the public list until they are approved."
            ) {
                HStack(spacing: 12) {
                    MetricChip(label: "Pending", value: "\(viewModel.pendingReviews.count)", color: AppTheme.warning)
                    MetricChip(label: "Reports", value: "\(viewModel.openReports.count)", color: AppTheme.danger)
                }
            }

            if let message = viewModel.errorMessage {
                Text(message)
                    .font(.footnote.weight(.semibold))
                    .foregroundStyle(AppTheme.warning)
                    .padding(.horizontal, 6)
            }

            if viewModel.pendingReviews.isEmpty && viewModel.openReports.isEmpty {
                EmptyStateCard(
                    icon: "checkmark.seal.fill",
                    title: "Queue is clear",
                    message: "There are no pending reviews or gouge reports waiting on moderation right now."
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
            viewModel.load(using: reviewStore)
        }
        .onReceive(reviewStore.$revision.dropFirst()) { _ in
            viewModel.load(using: reviewStore)
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
                        subtitle: InstructorRatingScale.formatOutOfSeven(score: review.chillScore),
                        score: review.chillScore,
                        style: .individual
                    )
                    InstructorRatingBadge(
                        title: "Grading Style",
                        label: InstructorRatingScale.label(for: review.gradingScore, category: .gradingStyle),
                        subtitle: InstructorRatingScale.formatOutOfSeven(score: review.gradingScore),
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
}
