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
                MetricChip(label: "Pending", value: "\(viewModel.pendingReviews.count)", color: AppTheme.warning)
            }

            if let message = viewModel.errorMessage {
                Text(message)
                    .font(.footnote.weight(.semibold))
                    .foregroundStyle(AppTheme.warning)
                    .padding(.horizontal, 6)
            }

            if viewModel.pendingReviews.isEmpty {
                EmptyStateCard(
                    icon: "checkmark.seal.fill",
                    title: "Queue is clear",
                    message: "There are no pending instructor reviews waiting on moderation right now."
                )
            } else {
                LazyVStack(spacing: 14) {
                    ForEach(viewModel.pendingReviews) { review in
                        pendingReviewCard(review)
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
}
