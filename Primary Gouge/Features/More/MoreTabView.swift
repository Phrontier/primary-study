import SwiftUI

struct MoreTabView: View {
    @EnvironmentObject private var appModel: StudyAppModel
    @EnvironmentObject private var reviewStore: InstructorReviewStore
    @EnvironmentObject private var searchChrome: SearchChromeModel

    private var snapshot: MoreHubSnapshot {
        appModel.moreHubSnapshot
    }

    private var reviewSummary: (instructors: Int, reviews: Int) {
        let instructors = reviewStore.fetchInstructorSummaries(searchText: "")
        return (
            instructors: instructors.count,
            reviews: instructors.reduce(0) { $0 + $1.publishedReviewCount }
        )
    }

    private var profileItem: MoreHubItem {
        MoreHubItem(
            title: "Profile",
            subtitle: "Identity, stage, and study defaults",
            iconName: "person.crop.circle.fill",
            accent: MoreSectionColor.account,
            badge: .planned,
            destination: .placeholder(
                message: "Profile controls will eventually centralize identity, stage preferences, and saved defaults."
            )
        )
    }

    private var settingsItem: MoreHubItem {
        MoreHubItem(
            title: "Settings",
            subtitle: "Preferences and app behavior",
            iconName: "gearshape.fill",
            accent: MoreSectionColor.account,
            badge: .planned,
            destination: .placeholder(
                message: "Settings will collect preferences, downloads, and app-level behavior in one place."
            )
        )
    }

    private var sections: [MoreHubSection] {
        [
            MoreHubSection(
                title: "Account",
                color: MoreSectionColor.account,
                items: [
                    profileItem,
                    MoreHubItem(
                        title: "Premium",
                        subtitle: "Upgrade path for future perks",
                        iconName: "star.circle.fill",
                        accent: MoreSectionColor.account,
                        badge: .premium,
                        destination: .placeholder(
                            message: "Premium state and entitlements will live here once paid features exist."
                        )
                    ),
                    settingsItem,
                    MoreHubItem(
                        title: "Notifications",
                        subtitle: "Alerts and study reminders",
                        iconName: "bell.badge.fill",
                        accent: MoreSectionColor.account,
                        badge: .planned,
                        destination: .placeholder(
                            message: "Notification controls will cover reminders, releases, and useful study nudges."
                        )
                    )
                ]
            ),
            MoreHubSection(
                title: "Study Tools",
                color: MoreSectionColor.studyTools,
                items: [
                    MoreHubItem(
                        title: "Quiz Mode",
                        subtitle: snapshot.quizSubtitle,
                        iconName: "checkmark.circle.fill",
                        accent: MoreSectionColor.studyTools,
                        destination: .quiz
                    ),
                    MoreHubItem(
                        title: "TOLD Calculator",
                        subtitle: "Field performance inputs and outputs",
                        iconName: "function",
                        accent: MoreSectionColor.studyTools,
                        badge: .planned,
                        destination: .placeholder(
                            message: "The TOLD calculator is reserved for a future utility pass."
                        )
                    ),
                    MoreHubItem(
                        title: "Fuel Planning",
                        subtitle: "Bingo, burn, and reserve helpers",
                        iconName: "fuelpump.fill",
                        accent: MoreSectionColor.studyTools,
                        badge: .planned,
                        destination: .placeholder(
                            message: "Fuel planning tools will consolidate reserve math, route planning, and quick checks."
                        )
                    ),
                    MoreHubItem(
                        title: "Jet Log Helpers",
                        subtitle: "Timing, legs, and planning aids",
                        iconName: "list.clipboard.fill",
                        accent: MoreSectionColor.studyTools,
                        badge: .planned,
                        destination: .placeholder(
                            message: "Jet log helpers will gather reusable planning shortcuts and reference calculators."
                        )
                    ),
                    MoreHubItem(
                        title: "Flashcard Performance Stats",
                        subtitle: snapshot.flashcardStatsSubtitle,
                        iconName: "chart.bar.fill",
                        accent: MoreSectionColor.studyTools,
                        destination: .statsDashboard
                    )
                ]
            ),
            MoreHubSection(
                title: "Library",
                color: MoreSectionColor.saved,
                items: [
                    MoreHubItem(
                        title: "Recent Briefs",
                        subtitle: snapshot.recentBriefsSubtitle,
                        iconName: "bookmark.fill",
                        accent: MoreSectionColor.saved,
                        destination: .recentBriefs
                    ),
                    MoreHubItem(
                        title: "Recent Flashcard Sets",
                        subtitle: snapshot.recentFlashcardSetsSubtitle,
                        iconName: "rectangle.stack.fill.badge.plus",
                        accent: MoreSectionColor.saved,
                        destination: .recentFlashcardSets
                    ),
                    MoreHubItem(
                        title: "Instructor Reviews",
                        subtitle: instructorReviewsSubtitle,
                        iconName: "person.2.crop.square.stack.fill",
                        accent: MoreSectionColor.saved,
                        destination: .instructorReviews
                    )
                ]
            ),
            MoreHubSection(
                title: "Community & Support",
                color: MoreSectionColor.support,
                items: [
                    MoreHubItem(
                        title: "Feedback",
                        subtitle: "Share what is working",
                        iconName: "bubble.left.and.text.bubble.right.fill",
                        accent: MoreSectionColor.support,
                        destination: .placeholder(
                            message: "Feedback intake will live here once the support workflow is wired up."
                        )
                    ),
                    MoreHubItem(
                        title: "Request a Feature",
                        subtitle: "Tell us what you need next",
                        iconName: "lightbulb.fill",
                        accent: MoreSectionColor.support,
                        destination: .placeholder(
                            message: "Feature requests will eventually route into a dedicated product feedback flow."
                        )
                    ),
                    MoreHubItem(
                        title: "FAQ",
                        subtitle: "Common answers and guidance",
                        iconName: "questionmark.circle.fill",
                        accent: MoreSectionColor.support,
                        destination: .placeholder(
                            message: "An FAQ surface is reserved for common app and study workflow questions."
                        )
                    ),
                    MoreHubItem(
                        title: "Support",
                        subtitle: "Get help with the app",
                        iconName: "lifepreserver.fill",
                        accent: MoreSectionColor.support,
                        destination: .placeholder(
                            message: "Support options will land here once a real help channel is connected."
                        )
                    ),
                    MoreHubItem(
                        title: "Report Incorrect Gouge",
                        subtitle: "Flag outdated or wrong info",
                        iconName: "exclamationmark.bubble.fill",
                        accent: AppTheme.danger,
                        destination: .placeholder(
                            message: "Incorrect gouge reporting will route into a dedicated review workflow once it is built."
                        )
                    )
                ]
            ),
            MoreHubSection(
                title: "About",
                color: MoreSectionColor.about,
                items: [
                    MoreHubItem(
                        title: "Version",
                        subtitle: snapshot.versionSubtitle,
                        iconName: "number.circle.fill",
                        accent: MoreSectionColor.about,
                        destination: .placeholder(
                            message: "Build metadata is available now, and a fuller release details view can grow here later."
                        )
                    ),
                    MoreHubItem(
                        title: "Changelog",
                        subtitle: "What changed recently",
                        iconName: "clock.arrow.circlepath",
                        accent: MoreSectionColor.about,
                        badge: .planned,
                        destination: .placeholder(
                            message: "A release log is planned for future app updates."
                        )
                    ),
                    MoreHubItem(
                        title: "Privacy",
                        subtitle: "How data is handled",
                        iconName: "lock.shield.fill",
                        accent: MoreSectionColor.about,
                        destination: .placeholder(
                            message: "Privacy details will live here once the app publishes its policy surface."
                        )
                    ),
                    MoreHubItem(
                        title: "Terms",
                        subtitle: "Usage and access terms",
                        iconName: "doc.text.fill",
                        accent: MoreSectionColor.about,
                        destination: .placeholder(
                            message: "Terms and access details will live here once they are ready to ship."
                        )
                    )
                ]
            )
        ]
    }

    private var instructorReviewsSubtitle: String {
        let instructorCount = reviewSummary.instructors
        let reviewCount = reviewSummary.reviews

        guard reviewCount > 0 else {
            return "Browse published instructor gouge"
        }

        return "\(instructorCount) instructors • \(reviewCount) reviews"
    }

    var body: some View {
        AppScrollScreen(topPadding: AppTheme.Spacing.screenTop, bottomPadding: 28) {
            VStack(alignment: .leading, spacing: 18) {
                MoreHeroCard(
                    snapshot: snapshot,
                    profileDestination: profileItem,
                    settingsDestination: settingsItem
                )

                ForEach(sections) { section in
                    VStack(alignment: .leading, spacing: 10) {
                        MoreSectionHeader(title: section.title, color: section.color)

                        MoreSectionContainer {
                            ForEach(Array(section.items.enumerated()), id: \.element.id) { index, item in
                                NavigationLink {
                                    destinationView(for: item)
                                } label: {
                                    MoreUtilityRow(item: item)
                                }
                                .buttonStyle(.plain)

                                if index < section.items.count - 1 {
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
        .rootNavigationChrome(title: "More")
        .onAppear {
            searchChrome.updateScope(.home)
        }
    }

    @ViewBuilder
    private func destinationView(for item: MoreHubItem) -> some View {
        switch item.destination {
        case .quiz:
            QuizHubView()
        case .instructorReviews:
            InstructorReviewsRootView()
        case .statsDashboard:
            MoreStatsDashboardView(snapshot: snapshot)
        case .recentBriefs:
            MoreRecentBriefsView(snapshot: snapshot)
        case .recentFlashcardSets:
            MoreRecentFlashcardSetsView(snapshot: snapshot)
        case .generalLibrary:
            generalLibraryDestination
        case let .placeholder(message):
            MorePlaceholderDetailView(item: item, message: message, snapshot: snapshot)
        }
    }

    private var generalLibraryDestination: some View {
        GeneralLibraryView(
            hubs: appModel.generalLibraryStudyHubs,
            resourceGroups: appModel.generalLibraryGroupedResources,
            videos: appModel.generalLibraryVideos
        )
    }
}

private struct MoreHeroCard: View {
    let snapshot: MoreHubSnapshot
    let profileDestination: MoreHubItem
    let settingsDestination: MoreHubItem

    var body: some View {
        SectionContainer(style: .rootSummary, accent: MoreSectionColor.account, contentPadding: 20) {
            VStack(alignment: .leading, spacing: 16) {
                HStack(alignment: .top, spacing: 14) {
                    VStack(alignment: .leading, spacing: 8) {
                        Text("ACCOUNT")
                            .font(.caption.weight(.semibold))
                            .foregroundStyle(MoreSectionColor.account)
                            .tracking(0.7)

                        Text(snapshot.identityTitle)
                            .font(.title3.weight(.semibold))
                            .foregroundStyle(AppTheme.textPrimary)
                            .fixedSize(horizontal: false, vertical: true)

                        Text(snapshot.currentFocusLine)
                            .font(.footnote)
                            .foregroundStyle(AppTheme.textSecondary)
                            .fixedSize(horizontal: false, vertical: true)
                    }

                    Spacer(minLength: 12)

                    ZStack {
                        Circle()
                            .fill(AppTheme.badgeFill(MoreSectionColor.account))
                            .frame(width: 46, height: 46)
                            .overlay(
                                Circle()
                                    .stroke(AppTheme.badgeStroke(MoreSectionColor.account), lineWidth: 1)
                            )

                        Text(snapshot.avatarInitials)
                            .font(.headline.weight(.bold))
                            .foregroundStyle(AppTheme.iconTint(MoreSectionColor.account))
                    }
                }

                HStack(spacing: 10) {
                    NavigationLink {
                        MorePlaceholderDetailView(
                            item: profileDestination,
                            message: "Profile controls will eventually centralize identity, stage preferences, and saved defaults.",
                            snapshot: snapshot
                        )
                    } label: {
                        HeaderCapsuleButton(title: "Profile", iconName: "person.crop.circle", tint: MoreSectionColor.account)
                    }
                    .buttonStyle(.plain)

                    NavigationLink {
                        MorePlaceholderDetailView(
                            item: settingsDestination,
                            message: "Settings will collect preferences, downloads, and app-level behavior in one place.",
                            snapshot: snapshot
                        )
                    } label: {
                        HeaderCapsuleButton(title: "Settings", iconName: "gearshape", tint: MoreSectionColor.account)
                    }
                    .buttonStyle(.plain)
                }
            }
        }
    }
}

private struct MoreSectionHeader: View {
    let title: String
    let color: Color

    var body: some View {
        Text(title.uppercased())
            .font(.caption.weight(.semibold))
            .foregroundStyle(color)
            .tracking(0.6)
            .padding(.horizontal, 4)
    }
}

private struct MoreSectionContainer<Content: View>: View {
    @ViewBuilder let content: Content

    var body: some View {
        VStack(spacing: 0) {
            content
        }
        .background(
            RoundedRectangle(cornerRadius: 22, style: .continuous)
                .fill(AppTheme.surface)
                .overlay(
                    RoundedRectangle(cornerRadius: 22, style: .continuous)
                        .stroke(AppTheme.cardStroke.opacity(0.9), lineWidth: 1)
                )
        )
    }
}

private struct MoreUtilityRow: View {
    let item: MoreHubItem

    private let accessoryColumnWidth: CGFloat = 96

    var body: some View {
        HStack(spacing: 14) {
            ZStack {
                RoundedRectangle(cornerRadius: 12, style: .continuous)
                    .fill(AppTheme.semanticTint(item.accent, opacity: 0.16))
                    .frame(width: 36, height: 36)
                    .overlay(
                        RoundedRectangle(cornerRadius: 12, style: .continuous)
                            .stroke(item.accent.opacity(0.16), lineWidth: 1)
                    )

                Image(systemName: item.iconName)
                    .font(.system(size: 15, weight: .semibold))
                    .foregroundStyle(item.accent)
            }

            VStack(alignment: .leading, spacing: 0) {
                Text(item.title)
                    .font(.body.weight(.semibold))
                    .foregroundStyle(AppTheme.textPrimary)
            }

            Spacer(minLength: 8)

            HStack(spacing: 10) {
                if let badge = item.badge {
                    MoreRowBadge(style: badge)
                }

                Image(systemName: "chevron.right")
                    .font(.system(size: 12, weight: .bold))
                    .foregroundStyle(AppTheme.accessoryTint(item.accent))
            }
            .frame(width: accessoryColumnWidth, alignment: .trailing)
        }
        .padding(.horizontal, 14)
        .padding(.vertical, 11)
        .frame(minHeight: 60, alignment: .leading)
        .contentShape(Rectangle())
    }
}

private struct MoreRowBadge: View {
    let style: MoreRowBadgeStyle

    var body: some View {
        Text(style.title)
            .font(.caption2.weight(.semibold))
            .foregroundStyle(style.color)
            .padding(.horizontal, 8)
            .padding(.vertical, 4)
            .background(
                Capsule()
                    .fill(style.color.opacity(0.12))
                    .overlay(
                        Capsule()
                            .stroke(style.color.opacity(0.18), lineWidth: 1)
                    )
            )
    }
}

private struct MoreStatsDashboardView: View {
    let snapshot: MoreHubSnapshot

    var body: some View {
        AppScrollScreen(topPadding: 20, bottomPadding: 32) {
            VStack(alignment: .leading, spacing: 18) {
                if snapshot.stats.hasContent {
                    VStack(alignment: .leading, spacing: 12) {
                        SectionHeader(
                            eyebrow: "Overview",
                            title: "Study snapshot",
                            subtitle: nil
                        )

                        LazyVGrid(
                            columns: [
                                GridItem(.flexible(), spacing: 12),
                                GridItem(.flexible(), spacing: 12)
                            ],
                            spacing: 12
                        ) {
                            CompactMetricChip(
                                label: "Studied Cards",
                                value: "\(snapshot.stats.studiedCardCount)",
                                color: MoreSectionColor.studyTools,
                                iconName: "rectangle.stack.fill"
                            )

                            CompactMetricChip(
                                label: "Due Now",
                                value: "\(snapshot.stats.dueCardCount)",
                                color: AppTheme.warning,
                                iconName: "clock.badge.exclamationmark.fill"
                            )

                            CompactMetricChip(
                                label: "Quiz Sessions",
                                value: "\(snapshot.stats.quizSessionCount)",
                                color: AppTheme.domainColor(.quizzes),
                                iconName: "checkmark.circle.fill"
                            )

                            if let averageScore = snapshot.stats.averageQuizScore {
                                CompactMetricChip(
                                    label: "Avg Score",
                                    value: "\(averageScore)%",
                                    color: AppTheme.success,
                                    iconName: "chart.line.uptrend.xyaxis"
                                )
                            }
                        }
                    }

                    if !snapshot.stats.weakAreaSignals.isEmpty {
                        VStack(alignment: .leading, spacing: 12) {
                            SectionHeader(
                                eyebrow: "Quiz trends",
                                title: "Weak areas to tighten",
                                subtitle: nil
                            )

                            MoreSectionContainer {
                                ForEach(Array(snapshot.stats.weakAreaSignals.enumerated()), id: \.element.id) { index, signal in
                                    MoreWeakAreaRow(signal: signal)

                                    if index < snapshot.stats.weakAreaSignals.count - 1 {
                                        Divider()
                                            .overlay(AppTheme.cardStroke.opacity(0.9))
                                            .padding(.leading, 62)
                                    }
                                }
                            }
                        }
                    }
                } else {
                    EmptyStateCard(
                        icon: "chart.bar.xaxis",
                        title: "No performance history yet",
                        message: "Start a quiz or work through a flashcard deck to build your first study snapshot."
                    )
                }
            }
        }
        .detailNavigationChrome(title: "Flashcard Performance Stats")
    }
}

private struct MoreWeakAreaRow: View {
    let signal: QuizWeakAreaSignal

    var body: some View {
        HStack(alignment: .top, spacing: 14) {
            ZStack {
                RoundedRectangle(cornerRadius: 12, style: .continuous)
                    .fill(AppTheme.semanticTint(AppTheme.warning, opacity: 0.16))
                    .frame(width: 36, height: 36)
                    .overlay(
                        RoundedRectangle(cornerRadius: 12, style: .continuous)
                            .stroke(AppTheme.warning.opacity(0.18), lineWidth: 1)
                    )

                Image(systemName: "scope")
                    .font(.system(size: 15, weight: .semibold))
                    .foregroundStyle(AppTheme.warning)
            }

            VStack(alignment: .leading, spacing: 4) {
                Text(signal.title)
                    .font(.body.weight(.semibold))
                    .foregroundStyle(AppTheme.textPrimary)

                Text(signal.detail)
                    .font(.subheadline)
                    .foregroundStyle(AppTheme.textSecondary)
                    .fixedSize(horizontal: false, vertical: true)
            }

            Spacer(minLength: 0)
        }
        .padding(.horizontal, 14)
        .padding(.vertical, 13)
    }
}

private struct MoreRecentBriefsView: View {
    let snapshot: MoreHubSnapshot

    @EnvironmentObject private var appModel: StudyAppModel

    var body: some View {
        AppScrollScreen(topPadding: 20, bottomPadding: 32) {
            VStack(alignment: .leading, spacing: 18) {
                if snapshot.recentBriefs.isEmpty {
                    MoreRecentEmptyState(
                        icon: "doc.text.magnifyingglass",
                        title: "No recent briefs yet",
                        message: "Open a brief or reference from the General Library and it will show up here."
                    )
                } else {
                    VStack(alignment: .leading, spacing: 12) {
                        SectionHeader(
                            eyebrow: "Library",
                            title: "Recently opened briefs",
                            subtitle: nil
                        )

                        MoreSectionContainer {
                            ForEach(Array(snapshot.recentBriefs.enumerated()), id: \.element.id) { index, item in
                                NavigationLink {
                                    recentBriefDestination(for: item)
                                } label: {
                                    MoreRecentItemRow(
                                        iconName: "doc.text.fill",
                                        accent: MoreSectionColor.saved,
                                        title: item.title,
                                        subtitle: "\(item.context) • \(item.lastOpenedAt.moreDisplayString)"
                                    )
                                }
                                .buttonStyle(.plain)

                                if index < snapshot.recentBriefs.count - 1 {
                                    Divider()
                                        .overlay(AppTheme.cardStroke.opacity(0.9))
                                        .padding(.leading, 62)
                                }
                            }
                        }
                    }

                    generalLibraryShortcut
                }
            }
        }
        .detailNavigationChrome(title: "Recent Briefs")
    }

    @ViewBuilder
    private func recentBriefDestination(for item: MoreRecentBriefItem) -> some View {
        if let resource = appModel.sharedResource(id: item.resourceID) {
            SharedResourceDetailView(resource: resource)
        } else {
            EmptyStateCard(
                icon: "exclamationmark.triangle.fill",
                title: "Brief unavailable",
                message: "This recent brief could not be reopened right now."
            )
        }
    }

    private var generalLibraryShortcut: some View {
        NavigationLink {
            GeneralLibraryView(
                hubs: appModel.generalLibraryStudyHubs,
                resourceGroups: appModel.generalLibraryGroupedResources,
                videos: appModel.generalLibraryVideos
            )
        } label: {
            StudyActionButton(
                title: "Open General Library",
                icon: "books.vertical.fill",
                tint: MoreSectionColor.saved,
                isProminent: false
            )
        }
        .buttonStyle(.plain)
    }
}

private struct MoreRecentFlashcardSetsView: View {
    let snapshot: MoreHubSnapshot

    @EnvironmentObject private var appModel: StudyAppModel

    var body: some View {
        AppScrollScreen(topPadding: 20, bottomPadding: 32) {
            VStack(alignment: .leading, spacing: 18) {
                if snapshot.recentDecks.isEmpty {
                    MoreRecentEmptyState(
                        icon: "rectangle.stack.badge.play.fill",
                        title: "No recent flashcard sets yet",
                        message: "Open a deck from the General Library or an event card deck and it will show up here."
                    )
                } else {
                    VStack(alignment: .leading, spacing: 12) {
                        SectionHeader(
                            eyebrow: "Library",
                            title: "Recently opened flashcard sets",
                            subtitle: nil
                        )

                        MoreSectionContainer {
                            ForEach(Array(snapshot.recentDecks.enumerated()), id: \.element.id) { index, item in
                                NavigationLink {
                                    recentDeckDestination(for: item)
                                } label: {
                                    MoreRecentItemRow(
                                        iconName: "rectangle.stack.fill",
                                        accent: MoreSectionColor.saved,
                                        title: item.deckTitle,
                                        subtitle: "\(item.context) • \(item.lastOpenedAt.moreDisplayString)"
                                    )
                                }
                                .buttonStyle(.plain)

                                if index < snapshot.recentDecks.count - 1 {
                                    Divider()
                                        .overlay(AppTheme.cardStroke.opacity(0.9))
                                        .padding(.leading, 62)
                                }
                            }
                        }
                    }

                    generalLibraryShortcut
                }
            }
        }
        .detailNavigationChrome(title: "Recent Flashcard Sets")
    }

    @ViewBuilder
    private func recentDeckDestination(for item: MoreRecentDeckItem) -> some View {
        switch item.destination {
        case let .eventDeck(phaseID, eventID, deckID):
            if let context = appModel.eventDeckContext(phaseID: phaseID, eventID: eventID, deckID: deckID) {
                FlashcardDeckView(event: context.0, deck: context.1)
            } else {
                missingDeckState
            }
        case let .libraryDeck(id):
            if let hub = appModel.libraryHub(id: id) {
                FlashcardDeckView(hub: hub)
            } else {
                missingDeckState
            }
        }
    }

    private var generalLibraryShortcut: some View {
        NavigationLink {
            GeneralLibraryView(
                hubs: appModel.generalLibraryStudyHubs,
                resourceGroups: appModel.generalLibraryGroupedResources,
                videos: appModel.generalLibraryVideos
            )
        } label: {
            StudyActionButton(
                title: "Open General Library",
                icon: "books.vertical.fill",
                tint: MoreSectionColor.saved,
                isProminent: false
            )
        }
        .buttonStyle(.plain)
    }

    private var missingDeckState: some View {
        EmptyStateCard(
            icon: "exclamationmark.triangle.fill",
            title: "Deck unavailable",
            message: "This recent deck could not be reopened right now."
        )
    }
}

private struct MoreRecentItemRow: View {
    let iconName: String
    let accent: Color
    let title: String
    let subtitle: String

    var body: some View {
        HStack(spacing: 14) {
            ZStack {
                RoundedRectangle(cornerRadius: 12, style: .continuous)
                    .fill(AppTheme.semanticTint(accent, opacity: 0.16))
                    .frame(width: 36, height: 36)
                    .overlay(
                        RoundedRectangle(cornerRadius: 12, style: .continuous)
                            .stroke(accent.opacity(0.16), lineWidth: 1)
                    )

                Image(systemName: iconName)
                    .font(.system(size: 15, weight: .semibold))
                    .foregroundStyle(accent)
            }

            VStack(alignment: .leading, spacing: 4) {
                Text(title)
                    .font(.body.weight(.semibold))
                    .foregroundStyle(AppTheme.textPrimary)

                Text(subtitle)
                    .font(.subheadline)
                    .foregroundStyle(AppTheme.textSecondary)
                    .fixedSize(horizontal: false, vertical: true)
            }

            Spacer(minLength: 8)

            Image(systemName: "chevron.right")
                .font(.system(size: 12, weight: .bold))
                .foregroundStyle(AppTheme.accessoryTint(accent))
        }
        .padding(.horizontal, 14)
        .padding(.vertical, 13)
        .contentShape(Rectangle())
    }
}

private struct MoreRecentEmptyState: View {
    let icon: String
    let title: String
    let message: String

    @EnvironmentObject private var appModel: StudyAppModel

    var body: some View {
        VStack(alignment: .leading, spacing: 16) {
            EmptyStateCard(
                icon: icon,
                title: title,
                message: message
            )

            NavigationLink {
                GeneralLibraryView(
                    hubs: appModel.generalLibraryStudyHubs,
                    resourceGroups: appModel.generalLibraryGroupedResources,
                    videos: appModel.generalLibraryVideos
                )
            } label: {
                StudyActionButton(
                    title: "Open General Library",
                    icon: "books.vertical.fill",
                    tint: MoreSectionColor.saved,
                    isProminent: false
                )
            }
            .buttonStyle(.plain)
        }
    }
}

private struct MorePlaceholderDetailView: View {
    let item: MoreHubItem
    let message: String
    let snapshot: MoreHubSnapshot

    private var detailSummary: String {
        switch item.title {
        case "Version":
            return snapshot.versionSubtitle
        case "Recent Briefs":
            return snapshot.recentBriefsSubtitle
        case "Recent Flashcard Sets":
            return snapshot.recentFlashcardSetsSubtitle
        case "Flashcard Performance Stats":
            return snapshot.flashcardStatsSubtitle
        default:
            return item.subtitle ?? ""
        }
    }

    var body: some View {
        AppScrollScreen(topPadding: 20, bottomPadding: 32) {
            VStack(alignment: .leading, spacing: 18) {
                GlassCard(highlighted: true) {
                    VStack(alignment: .leading, spacing: 16) {
                        HStack(alignment: .top, spacing: 14) {
                            ZStack {
                                RoundedRectangle(cornerRadius: 18, style: .continuous)
                                    .fill(AppTheme.semanticTint(item.accent, opacity: 0.12))
                                    .frame(width: 50, height: 50)

                                Image(systemName: item.iconName)
                                    .font(.system(size: 20, weight: .semibold))
                                    .foregroundStyle(item.accent)
                            }

                            VStack(alignment: .leading, spacing: 6) {
                                HStack(spacing: 8) {
                                    Text(item.title)
                                        .font(.system(.title3, design: .rounded, weight: .bold))
                                        .foregroundStyle(AppTheme.textPrimary)

                                    if let badge = item.badge {
                                        MoreRowBadge(style: badge)
                                    }
                                }

                                if !detailSummary.isEmpty {
                                    Text(detailSummary)
                                        .font(.system(.subheadline, design: .rounded, weight: .semibold))
                                        .foregroundStyle(AppTheme.textSecondary)
                                }
                            }
                        }

                        Text(message)
                            .font(.system(.body, design: .rounded))
                            .foregroundStyle(AppTheme.textSecondary)
                    }
                }
            }
        }
        .detailNavigationChrome(title: item.title)
    }
}

private struct MoreHubSection: Identifiable {
    let title: String
    let color: Color
    let items: [MoreHubItem]

    var id: String { title }
}

private enum MoreSectionColor {
    static let account = AppTheme.color(0x93A3B8)
    static let studyTools = AppTheme.color(0x45CFFF)
    static let saved = AppTheme.color(0x8B74FF)
    static let support = AppTheme.color(0x58B3A7)
    static let about = AppTheme.color(0xD7A23E)
}

private struct MoreHubItem: Identifiable {
    let title: String
    let subtitle: String?
    let iconName: String
    let accent: Color
    let badge: MoreRowBadgeStyle?
    let destination: MoreHubDestination

    var id: String { title }

    init(
        title: String,
        subtitle: String? = nil,
        iconName: String,
        accent: Color,
        badge: MoreRowBadgeStyle? = nil,
        destination: MoreHubDestination
    ) {
        self.title = title
        self.subtitle = subtitle
        self.iconName = iconName
        self.accent = accent
        self.badge = badge
        self.destination = destination
    }
}

private enum MoreHubDestination {
    case quiz
    case instructorReviews
    case statsDashboard
    case recentBriefs
    case recentFlashcardSets
    case generalLibrary
    case placeholder(message: String)
}

private enum MoreRowBadgeStyle {
    case planned
    case premium
    case beta
    case new

    var title: String {
        switch self {
        case .planned:
            return "Planned"
        case .premium:
            return "Premium"
        case .beta:
            return "Beta"
        case .new:
            return "New"
        }
    }

    var color: Color {
        switch self {
        case .planned:
            return AppTheme.textMuted
        case .premium:
            return AppTheme.warning
        case .beta:
            return AppTheme.accent
        case .new:
            return AppTheme.success
        }
    }
}

private extension Date {
    var moreDisplayString: String {
        formatted(date: .abbreviated, time: .omitted)
    }
}
