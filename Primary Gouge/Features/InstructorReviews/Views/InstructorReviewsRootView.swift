import SwiftUI
import Combine

struct InstructorReviewsRootView: View {
    @EnvironmentObject private var reviewStore: InstructorReviewStore
    @EnvironmentObject private var searchChrome: SearchChromeModel
    @StateObject private var viewModel = InstructorReviewsRootViewModel()
    @State private var showingSubmission = false
    @State private var showingModeration = false

    var body: some View {
        AppScrollScreen(bottomPadding: 36) {
            heroCard

            SectionContainer {
                VStack(alignment: .leading, spacing: 16) {
                    InstructorPillSelector(
                        options: InstructorCapabilityFilter.allCases,
                        selected: viewModel.selectedFilter,
                        title: { $0.title },
                        accent: { filter in
                            switch filter {
                            case .all:
                                return AppTheme.accent
                            case .sims:
                                return AppTheme.warning
                            case .flights:
                                return AppTheme.success
                            }
                        }
                    ) { filter in
                        viewModel.selectedFilter = filter
                    }

                    InstructorSearchField(
                        placeholder: "Search instructors or squadrons",
                        text: $viewModel.searchText
                    )

                    Text("\(viewModel.instructors.count) instructors")
                        .font(.footnote.weight(.semibold))
                        .foregroundStyle(AppTheme.textSecondary)
                }
            }

            if viewModel.instructors.isEmpty {
                if viewModel.hasPublishedReviews {
                    EmptyStateCard(
                        icon: "magnifyingglass",
                        title: "No matching instructors",
                        message: "Try a different name, squadron, or filter to widen the roster."
                    )
                } else {
                    EmptyStateCard(
                        icon: "person.crop.rectangle.stack.fill",
                        title: "No published reviews yet",
                        message: "Approved reviews will appear here as soon as they clear moderation."
                    )
                }
            } else {
                LazyVStack(spacing: 14) {
                    ForEach(viewModel.instructors) { instructor in
                        NavigationLink {
                            InstructorReviewDetailView(instructor: instructor)
                        } label: {
                            InstructorSummaryCard(instructor: instructor)
                        }
                        .buttonStyle(.plain)
                    }
                }
            }
        }
        .navigationTitle("Instructor Reviews")
        .navigationBarTitleDisplayMode(.inline)
        .toolbar {
            ToolbarItem(placement: .topBarTrailing) {
                Button {
                    showingModeration = true
                } label: {
                    Image(systemName: "checkmark.shield.fill")
                        .foregroundStyle(AppTheme.accent)
                }
            }
        }
        .sheet(isPresented: $showingSubmission) {
            NavigationStack {
                ReviewSubmissionView()
            }
            .presentationDragIndicator(.visible)
        }
        .sheet(isPresented: $showingModeration) {
            NavigationStack {
                ModerationQueueView()
            }
            .presentationDragIndicator(.visible)
        }
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

    private var heroCard: some View {
        HeroCard(
            eyebrow: "Instructor gouge",
            title: "Quick context on who you're flying with.",
            subtitle: "Approved reviews drive every average. Filter the roster, then open an instructor when you need the full story."
        ) {
            HStack(spacing: 10) {
                MetricChip(label: "Published", value: "\(viewModel.totalPublishedReviews)", color: AppTheme.accent)
                MetricChip(label: "Filters", value: "3", color: AppTheme.accent)
                MetricChip(label: "Workflow", value: "Moderated", color: AppTheme.accent)
            }

            InstructorPrimaryButton(title: "Submit Instructor Review", icon: "square.and.pencil", enabled: true) {
                showingSubmission = true
            }
        }
    }
}
