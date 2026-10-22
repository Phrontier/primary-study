import SwiftUI
import Combine

struct InstructorReviewsRootView: View {
    @EnvironmentObject private var accountStore: AccountStore
    @EnvironmentObject private var reviewStore: InstructorReviewStore
    @EnvironmentObject private var searchChrome: SearchChromeModel
    @StateObject private var viewModel = InstructorReviewsRootViewModel()
    @Environment(\.dynamicTypeSize) private var typeSize
    @State private var showingSubmission = false
    @State private var showingModeration = false

    var body: some View {
        PilotPage {
            StudyHeading(title: "Instructors", subtitle: "Know who you’re flying with.").padding(.top, 7).padding(.bottom, 28)
            HStack(spacing: 10) {
                Image(systemName: "magnifyingglass").font(.system(size: 17)).accessibilityHidden(true).foregroundStyle(StudyDesign.secondary)
                TextField("Search instructors or squadrons", text: $viewModel.searchText, prompt: Text(typeSize.isAccessibilitySize ? "Search" : "Search instructors or squadrons").foregroundStyle(StudyDesign.secondary)).accessibilityLabel("Search instructors or squadrons")
                    .selectedText(13).textInputAutocapitalization(.never).autocorrectionDisabled()
            }.padding(14).frame(minHeight: 49).background(StudyDesign.surface, in: RoundedRectangle(cornerRadius: 13))
                .overlay(RoundedRectangle(cornerRadius: 13).strokeBorder(StudyDesign.cardLine, lineWidth: 1))
            Picker("Instructor type", selection: $viewModel.selectedFilter) {
                ForEach(InstructorCapabilityFilter.allCases) { filter in Text(filter.title).tag(filter) }
            }.pickerStyle(.segmented).frame(minHeight: 38).padding(.top, 14).padding(.bottom, 28)
            Text("Instructor reviews").pilotText(.section).padding(.bottom, 14)
            Button { showingSubmission = true } label: {
                HStack { Text("Submit review"); Spacer(); Image(systemName: "arrow.right") }
                    .selectedText(14, weight: .semibold).foregroundStyle(.white).padding(14)
                    .frame(maxWidth: .infinity, minHeight: 46).background(StudyDesign.action, in: RoundedRectangle(cornerRadius: 13))
            }.buttonStyle(.plain).accessibilityLabel("Submit Instructor Review")
            if accountStore.hasPermission(.instructorGougeModerator) { moderationBubble.padding(.top, 12) }
            if viewModel.instructors.isEmpty {
                EmptyStateCard(icon: "person.2", title: viewModel.hasPublishedReviews ? "No Matching Instructors" : "No Published Reviews Yet", message: viewModel.hasPublishedReviews ? "Try a different name, squadron, or filter." : "Approved reviews appear after moderation.").padding(.top, 24)
            } else {
                LazyVStack(spacing: 0) {
                    ForEach(viewModel.instructors) { instructor in
                        NavigationLink { InstructorReviewDetailView(instructor: instructor) } label: { SelectedInstructorRow(instructor: instructor) }.buttonStyle(.plain).accessibilityIdentifier("selected-instructor-\(instructor.id)")
                    }
                }
            }
            if reviewStore.syncStatus.phase == .failed || reviewStore.syncStatus.phase == .offline {
                syncStatusLine.padding(.top, 20)
            }
        }
        .pilotNavigation()
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
