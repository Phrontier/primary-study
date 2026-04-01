import SwiftUI
import Combine

struct InstructorReviewDetailView: View {
    @EnvironmentObject private var reviewStore: InstructorReviewStore
    @EnvironmentObject private var searchChrome: SearchChromeModel
    @StateObject private var viewModel: InstructorReviewDetailViewModel

    init(instructor: Instructor) {
        _viewModel = StateObject(wrappedValue: InstructorReviewDetailViewModel(instructor: instructor))
    }

    var body: some View {
        AppScrollScreen(bottomPadding: 36) {
            HeroCard(
                eyebrow: viewModel.instructor.squadron.displayName,
                title: viewModel.instructor.name,
                subtitle: "\(viewModel.instructor.publishedReviewCount) published reviews"
            ) {
                HStack(spacing: 10) {
                    ForEach(viewModel.instructor.capabilityBadges, id: \.self) { capability in
                        InstructorCapabilityBadge(capability: capability)
                    }
                }
            }

            HStack(spacing: 12) {
                InstructorAggregateCard(
                    title: "Average Chill Factor",
                    label: viewModel.instructor.chillLabel,
                    average: viewModel.instructor.averageChillScore
                )
                InstructorAggregateCard(
                    title: "Average Grading Style",
                    label: viewModel.instructor.gradingLabel,
                    average: viewModel.instructor.averageGradingScore
                )
            }

            InstructorAdaptiveSelector(
                options: InstructorReviewSortOption.allCases,
                selected: viewModel.selectedSort,
                title: { $0.title },
                accent: { option in
                    switch option {
                    case .mostRecent:
                        return AppTheme.accent
                    case .oldest:
                        return AppTheme.warning
                    case .best:
                        return AppTheme.success
                    case .worst:
                        return AppTheme.danger
                    }
                },
                menuTitle: "Sort Reviews"
            ) { option in
                viewModel.selectedSort = option
            }

            if viewModel.reviews.isEmpty {
                EmptyStateCard(
                    icon: "tray.fill",
                    title: "No approved reviews yet",
                    message: "Once moderation approves a review, it will appear here automatically."
                )
            } else {
                LazyVStack(spacing: 14) {
                    ForEach(viewModel.reviews) { review in
                        InstructorReviewCard(review: review)
                    }
                }
            }
        }
        .navigationTitle("Instructor")
        .navigationBarTitleDisplayMode(.inline)
        .task {
            viewModel.load(using: reviewStore)
        }
        .onReceive(reviewStore.$revision.dropFirst()) { _ in
            viewModel.load(using: reviewStore)
        }
        .onAppear {
            searchChrome.updateScope(.instructors)
        }
    }
}
