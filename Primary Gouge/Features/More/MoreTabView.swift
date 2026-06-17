import SwiftUI

struct MoreTabView: View {
    @EnvironmentObject private var accountStore: AccountStore
    @EnvironmentObject private var appModel: StudyAppModel
    @EnvironmentObject private var searchChrome: SearchChromeModel

    private var snapshot: MoreHubSnapshot {
        appModel.moreHubSnapshot
    }

    private var profileItem: MoreHubItem {
        MoreHubItem(
            title: "Profile",
            subtitle: "Your info and training setup",
            iconName: "person.crop.circle.fill",
            accent: MoreSectionColor.account,
            destination: .profile
        )
    }

    private var settingsItem: MoreHubItem {
        MoreHubItem(
            title: "Settings",
            subtitle: "Focus topics and preferences",
            iconName: "gearshape.fill",
            accent: MoreSectionColor.account,
            destination: .settings
        )
    }

    private var sections: [MoreHubSection] {
        [
            MoreHubSection(
                title: "Account",
                color: MoreSectionColor.account,
                items: [
                    profileItem,
                    settingsItem,
                    MoreHubItem(
                        title: "Notifications",
                        subtitle: "Daily reminders",
                        iconName: "bell.badge.fill",
                        accent: MoreSectionColor.account,
                        destination: .notifications
                    )
                ]
            ),
            MoreHubSection(
                title: "Study Tools",
                color: MoreSectionColor.studyTools,
                items: [
                    MoreHubItem(
                        title: "Quiz Mode",
                        subtitle: nil,
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
                        iconName: "checklist.checked",
                        accent: MoreSectionColor.studyTools,
                        badge: .planned,
                        destination: .placeholder(
                            message: "Jet log helpers will gather reusable planning shortcuts and reference calculators."
                        )
                    ),
                    MoreHubItem(
                        title: "Flashcard Performance Stats",
                        subtitle: nil,
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
                        subtitle: nil,
                        iconName: "bookmark.fill",
                        accent: MoreSectionColor.saved,
                        destination: .recentBriefs
                    ),
                    MoreHubItem(
                        title: "Recent Flashcard Sets",
                        subtitle: nil,
                        iconName: "rectangle.stack.fill.badge.plus",
                        accent: MoreSectionColor.saved,
                        destination: .recentFlashcardSets
                    ),
                    MoreHubItem(
                        title: "My Instructor Reviews",
                        subtitle: nil,
                        iconName: "person.2.crop.square.stack.fill",
                        accent: MoreSectionColor.saved,
                        destination: .myInstructorReviews
                    )
                ]
            ),
            MoreHubSection(
                title: "Community & Support",
                color: MoreSectionColor.support,
                items: [
                    MoreHubItem(
                        title: "Feedback",
                        subtitle: nil,
                        iconName: "bubble.left.and.text.bubble.right.fill",
                        accent: MoreSectionColor.support,
                        destination: .community(category: .feedback)
                    ),
                    MoreHubItem(
                        title: "Request a Feature",
                        subtitle: nil,
                        iconName: "lightbulb.fill",
                        accent: MoreSectionColor.support,
                        destination: .community(category: .featureRequest)
                    ),
                    MoreHubItem(
                        title: "FAQ",
                        subtitle: nil,
                        iconName: "questionmark.circle.fill",
                        accent: MoreSectionColor.support,
                        destination: .article(.faq)
                    ),
                    MoreHubItem(
                        title: "Support",
                        subtitle: nil,
                        iconName: "lifepreserver.fill",
                        accent: MoreSectionColor.support,
                        destination: .community(category: .support)
                    ),
                    MoreHubItem(
                        title: "Report Incorrect Gouge",
                        subtitle: nil,
                        iconName: "exclamationmark.bubble.fill",
                        accent: AppTheme.danger,
                        destination: .community(category: .incorrectGouge)
                    )
                ]
            ),
            MoreHubSection(
                title: "About",
                color: MoreSectionColor.about,
                items: [
                    MoreHubItem(
                        title: "Version",
                        subtitle: nil,
                        iconName: "number.circle.fill",
                        accent: MoreSectionColor.about,
                        destination: .version
                    ),
                    MoreHubItem(
                        title: "Changelog",
                        subtitle: nil,
                        iconName: "clock.arrow.circlepath",
                        accent: MoreSectionColor.about,
                        destination: .article(.changelog)
                    ),
                    MoreHubItem(
                        title: "Privacy",
                        subtitle: nil,
                        iconName: "lock.shield.fill",
                        accent: MoreSectionColor.about,
                        destination: .article(.privacy)
                    ),
                    MoreHubItem(
                        title: "Terms",
                        subtitle: nil,
                        iconName: "doc.text.fill",
                        accent: MoreSectionColor.about,
                        destination: .article(.terms)
                    )
                ]
            )
        ]
    }

    private var isPremiumSubscribed: Bool {
        appModel.homePreferences.premiumSubscribedPlaceholder
    }

    var body: some View {
        AppScrollScreen(topPadding: AppTheme.Spacing.screenTop, bottomPadding: 28) {
            VStack(alignment: .leading, spacing: 18) {
                MoreHeroCard(snapshot: snapshot, profile: accountStore.profile)
                NavigationLink {
                    MorePremiumView(snapshot: snapshot)
                } label: {
                    MorePremiumPromoCard(isSubscribed: isPremiumSubscribed)
                }
                .buttonStyle(.plain)

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
        case .profile:
            MoreProfileView(snapshot: snapshot)
        case .settings:
            MoreSettingsView(snapshot: snapshot)
        case .notifications:
            MoreNotificationsView()
        case .premium:
            MorePremiumView(snapshot: snapshot)
        case .quiz:
            QuizHubView()
        case .myInstructorReviews:
            MoreMyInstructorReviewsView()
        case .statsDashboard:
            MoreStatsDashboardView(snapshot: snapshot)
        case .recentBriefs:
            MoreRecentBriefsView(snapshot: snapshot)
        case .recentFlashcardSets:
            MoreRecentFlashcardSetsView(snapshot: snapshot)
        case .generalLibrary:
            generalLibraryDestination
        case let .community(category):
            MoreCommunitySubmissionView(category: category)
        case let .article(pageID):
            MoreArticleView(
                page: MoreArticleContentLoader.page(pageID),
                accent: item.accent,
                iconName: item.iconName
            )
        case .version:
            MoreVersionView(snapshot: snapshot)
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
    let profile: AccountProfile?

    var body: some View {
        MoreHeaderCard(accent: MoreSectionColor.account) {
            HStack(alignment: .center, spacing: 14) {
                MoreHeaderTextBlock(
                    eyebrow: "Account",
                    title: profile?.displayTitle ?? snapshot.identityTitle,
                    subtitle: accountSummaryLine,
                    accent: MoreSectionColor.account,
                    subtitleFont: .footnote
                )

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
        }
    }

    private var accountSummaryLine: String {
        let squadronTitle = AccountProfile.squadronTitle(for: profile?.squadronID)
        let syllabusTitle = profile?.selectedSyllabus.title

        let accountLine = [profile?.displayName == nil ? nil : squadronTitle, syllabusTitle]
            .compactMap { value in
                guard let value, !value.isEmpty, value != "Not Sure Yet", value != "Not Set" else { return nil }
                return value
            }
            .joined(separator: " • ")

        return accountLine.isEmpty ? snapshot.currentFocusLine : accountLine
    }
}

private struct MorePremiumPromoCard: View {
    let isSubscribed: Bool

    var body: some View {
        MoreHeaderCard(accent: AppTheme.warning, supportingSpacing: 12) {
            HStack(alignment: .center, spacing: 14) {
                MoreHeaderTextBlock(
                    eyebrow: "Premium",
                    title: isSubscribed ? "Premium marked active" : "Go Premium",
                    subtitle: isSubscribed ? "See your premium status and manage it here." : "Unlock the premium study experience when subscriptions open.",
                    accent: AppTheme.warning,
                    subtitleFont: .footnote
                )

                Spacer(minLength: 12)

                StatusBadge(
                    title: isSubscribed ? "Subscribed" : "Upgrade",
                    iconName: isSubscribed ? "checkmark.circle.fill" : "star.fill",
                    color: isSubscribed ? AppTheme.success : AppTheme.warning
                )
            }
        } supportingContent: {
            HStack(spacing: 10) {
                Text(isSubscribed ? "Manage premium status" : "See premium options")
                    .font(.footnote.weight(.semibold))
                    .foregroundStyle(AppTheme.prominentText(AppTheme.warning))

                Spacer(minLength: 8)

                Image(systemName: "chevron.right")
                    .font(.system(size: 12, weight: .bold))
                    .foregroundStyle(AppTheme.accessoryTint(AppTheme.warning))
            }
        }
    }
}

struct MoreHeaderCard<Header: View, SupportingContent: View>: View {
    let accent: Color
    let contentPadding: CGFloat
    let supportingSpacing: CGFloat
    let showsSupportingContent: Bool
    @ViewBuilder let header: Header
    @ViewBuilder let supportingContent: SupportingContent

    init(
        accent: Color,
        contentPadding: CGFloat = 18,
        @ViewBuilder header: () -> Header
    ) where SupportingContent == EmptyView {
        self.accent = accent
        self.contentPadding = contentPadding
        self.supportingSpacing = 0
        self.showsSupportingContent = false
        self.header = header()
        self.supportingContent = EmptyView()
    }

    init(
        accent: Color,
        contentPadding: CGFloat = 18,
        supportingSpacing: CGFloat = 12,
        @ViewBuilder header: () -> Header,
        @ViewBuilder supportingContent: () -> SupportingContent
    ) {
        self.accent = accent
        self.contentPadding = contentPadding
        self.supportingSpacing = supportingSpacing
        self.showsSupportingContent = true
        self.header = header()
        self.supportingContent = supportingContent()
    }

    var body: some View {
        SectionContainer(style: .rootSummary, accent: accent, contentPadding: contentPadding) {
            VStack(alignment: .leading, spacing: showsSupportingContent ? supportingSpacing : 0) {
                header
                    .frame(maxWidth: .infinity, alignment: .leading)

                if showsSupportingContent {
                    supportingContent
                }
            }
        }
    }
}

struct MoreHeaderTextBlock: View {
    let eyebrow: String
    let title: String
    let subtitle: String?
    let accent: Color
    let titleFont: Font
    let subtitleFont: Font

    init(
        eyebrow: String,
        title: String,
        subtitle: String? = nil,
        accent: Color,
        titleFont: Font = .title3.weight(.semibold),
        subtitleFont: Font = .subheadline
    ) {
        self.eyebrow = eyebrow
        self.title = title
        self.subtitle = subtitle
        self.accent = accent
        self.titleFont = titleFont
        self.subtitleFont = subtitleFont
    }

    var body: some View {
        VStack(alignment: .leading, spacing: subtitle == nil ? 4 : 5) {
            Text(eyebrow.uppercased())
                .font(.caption.weight(.semibold))
                .foregroundStyle(accent)
                .tracking(0.7)

            Text(title)
                .font(titleFont)
                .foregroundStyle(AppTheme.textPrimary)
                .fixedSize(horizontal: false, vertical: true)

            if let subtitle, !subtitle.isEmpty {
                Text(subtitle)
                    .font(subtitleFont)
                    .foregroundStyle(AppTheme.textSecondary)
                    .fixedSize(horizontal: false, vertical: true)
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

struct MoreSectionContainer<Content: View>: View {
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
        Group {
            if let iconName = style.iconName {
                Label(style.title, systemImage: iconName)
            } else {
                Text(style.title)
            }
        }
            .font(.caption2.weight(.semibold))
            .foregroundStyle(style.color)
            .lineLimit(1)
            .fixedSize(horizontal: true, vertical: false)
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
                MoreHeaderCard(accent: item.accent) {
                    HStack(alignment: .center, spacing: 14) {
                        ZStack {
                            RoundedRectangle(cornerRadius: 18, style: .continuous)
                                .fill(AppTheme.semanticTint(item.accent, opacity: 0.12))
                                .frame(width: 50, height: 50)

                            Image(systemName: item.iconName)
                                .font(.system(size: 20, weight: .semibold))
                                .foregroundStyle(item.accent)
                        }

                        VStack(alignment: .leading, spacing: 5) {
                            HStack(spacing: 8) {
                                Text(item.title)
                                    .font(.system(.title3, design: .rounded, weight: .bold))
                                    .foregroundStyle(AppTheme.textPrimary)
                                    .fixedSize(horizontal: false, vertical: true)

                                if let badge = item.badge {
                                    MoreRowBadge(style: badge)
                                }
                            }

                            if !detailSummary.isEmpty {
                                Text(detailSummary)
                                    .font(.system(.subheadline, design: .rounded, weight: .semibold))
                                    .foregroundStyle(AppTheme.textSecondary)
                                    .fixedSize(horizontal: false, vertical: true)
                            }
                        }
                    }
                } supportingContent: {
                    Text(message)
                        .font(.system(.body, design: .rounded))
                        .foregroundStyle(AppTheme.textSecondary)
                        .fixedSize(horizontal: false, vertical: true)
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

enum MoreSectionColor {
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
    case profile
    case settings
    case notifications
    case premium
    case quiz
    case myInstructorReviews
    case statsDashboard
    case recentBriefs
    case recentFlashcardSets
    case generalLibrary
    case community(category: CommunitySubmissionCategory)
    case article(MoreArticlePageID)
    case version
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

    var iconName: String? {
        switch self {
        case .planned:
            return "sparkles"
        case .premium, .beta, .new:
            return nil
        }
    }

    var color: Color {
        switch self {
        case .planned:
            return AppTheme.accent
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
