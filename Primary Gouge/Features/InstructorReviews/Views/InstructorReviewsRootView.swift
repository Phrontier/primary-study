import SwiftUI
import Combine

struct InstructorReviewsRootView: View {
    @EnvironmentObject private var accountStore: AccountStore
    @EnvironmentObject private var reviewStore: InstructorReviewStore
    @EnvironmentObject private var searchChrome: SearchChromeModel
    @StateObject private var viewModel = InstructorReviewsRootViewModel()
    @State private var showingSubmission = false
    @State private var showingModeration = false

    var body: some View {
        AppScrollScreen(topPadding: AppTheme.Spacing.rootTabIntroTop, bottomPadding: 36) {
            heroCard

            SectionContainer {
                VStack(alignment: .leading, spacing: 16) {
                    InstructorPillSelector(
                        options: InstructorCapabilityFilter.allCases,
                        selected: viewModel.selectedFilter,
                        title: { $0.title },
                        accent: { $0.color }
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
        .rootNavigationChrome(title: "Instructor Reviews")
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
            reviewStore.setModeratorPermission(accountStore.hasPermission(.instructorGougeModerator))
            viewModel.setSquadronFilter(accountStore.profile?.squadronID)
            viewModel.load(using: reviewStore)
        }
        .onReceive(reviewStore.$revision.dropFirst()) { _ in
            viewModel.load(using: reviewStore)
        }
        .onReceive(accountStore.$session) { _ in
            reviewStore.setModeratorPermission(accountStore.hasPermission(.instructorGougeModerator))
            viewModel.setSquadronFilter(accountStore.profile?.squadronID)
        }
        .onAppear {
            searchChrome.updateScope(.instructors)
        }
    }

    private var heroCard: some View {
        RootSummaryCard(
            identity: TabHeaderIdentity(
                navigationTitle: "Instructor Reviews",
                eyebrow: "Instructor gouge",
                title: "Know who you're flying with",
                subtitle: nil,
                iconName: AppTab.instructors.iconName,
                accent: AppTheme.domainColor(.instructors)
            ),
            metrics: [
                TabHeaderMetric(label: "Reviews", value: "\(viewModel.totalPublishedReviews)", color: AppTheme.domainColor(.instructors), iconName: "text.bubble.fill"),
                TabHeaderMetric(label: "Instructors", value: "\(viewModel.instructors.count)", color: AppTheme.accent, iconName: "person.2.fill"),
                TabHeaderMetric(label: "Moderated", value: "Screened", color: AppTheme.statusColor(.pending), iconName: "checkmark.shield.fill")
            ],
            metricLayout: .compactRow
        ) {
            VStack(alignment: .leading, spacing: 12) {
                ViewThatFits(in: .horizontal) {
                    HStack(spacing: 10) {
                        InstructorPrimaryButton(title: "Submit Instructor Review", icon: "square.and.pencil", enabled: true) {
                            showingSubmission = true
                        }

                        if accountStore.hasPermission(.instructorGougeModerator) {
                            moderationBubble
                        }
                    }

                    VStack(spacing: 10) {
                        InstructorPrimaryButton(title: "Submit Instructor Review", icon: "square.and.pencil", enabled: true) {
                            showingSubmission = true
                        }

                        if accountStore.hasPermission(.instructorGougeModerator) {
                            moderationBubble
                        }
                    }
                }

                syncStatusLine
            }
        }
    }

    private var moderationBubble: some View {
        Button {
            showingModeration = true
        } label: {
            HeaderCapsuleButton(title: "Moderation", iconName: "checkmark.shield.fill", tint: AppTheme.statusColor(.pending))
        }
        .buttonStyle(.plain)
        .accessibilityLabel("Open moderation queue")
    }

    private var syncStatusLine: some View {
        HStack(spacing: 8) {
            Circle()
                .fill(syncStatusColor)
                .frame(width: 8, height: 8)

            Text(syncStatusText)
                .font(.system(.footnote, design: .rounded, weight: .semibold))
                .foregroundStyle(AppTheme.textSecondary)
        }
    }

    private var syncStatusText: String {
        switch reviewStore.syncStatus.phase {
        case .idle:
            if let lastSyncedAt = reviewStore.syncStatus.lastSyncedAt {
                return "Synced \(lastSyncedAt.formatted(date: .abbreviated, time: .shortened))"
            }
            if reviewStore.isRemoteConfigured {
                return "Ready to sync instructor reviews. \(reviewStore.syncStatus.configurationDetail ?? "")".trimmingCharacters(in: .whitespacesAndNewlines)
            }
            return reviewStore.syncStatus.errorMessage ?? "Remote sync is not configured yet."
        case .syncing:
            return "Syncing latest instructor reviews…"
        case .offline:
            if reviewStore.isRemoteConfigured {
                return "Offline. Reading local reviews and queueing submissions. \(reviewStore.syncStatus.configurationDetail ?? "")".trimmingCharacters(in: .whitespacesAndNewlines)
            }
            return reviewStore.syncStatus.errorMessage ?? "Remote sync is not configured yet."
        case .failed:
            return reviewStore.syncStatus.errorMessage ?? "Sync hit an error. Local reviews are still available."
        }
    }

    private var syncStatusColor: Color {
        switch reviewStore.syncStatus.phase {
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
}
