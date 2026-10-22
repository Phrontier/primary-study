import SwiftUI

struct MoreTabView: View {
    @EnvironmentObject private var accountStore: AccountStore
    @EnvironmentObject private var appModel: StudyAppModel
    @EnvironmentObject private var subscriptionStore: SubscriptionStore
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
        var sections = [
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
                        badge: .premium,
                        accessRequirement: .premium,
                        destination: .quiz
                    ),
                    MoreHubItem(
                        title: "Flashcard Performance Stats",
                        subtitle: nil,
                        iconName: "chart.bar.fill",
                        accent: MoreSectionColor.studyTools,
                        badge: .premium,
                        accessRequirement: .premium,
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
                        badge: .premium,
                        accessRequirement: .premium,
                        destination: .recentBriefs
                    ),
                    MoreHubItem(
                        title: "Recent Flashcard Sets",
                        subtitle: nil,
                        iconName: "rectangle.stack.fill.badge.plus",
                        accent: MoreSectionColor.saved,
                        badge: .premium,
                        accessRequirement: .premium,
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

        if accountStore.hasPermission(.instructorGougeModerator) {
            sections.insert(
                MoreHubSection(
                    title: "Moderation",
                    color: AppTheme.statusColor(.pending),
                    items: [
                        MoreHubItem(
                            title: "Moderation",
                            subtitle: "Approve or deny submissions",
                            iconName: "checkmark.shield.fill",
                            accent: AppTheme.statusColor(.pending),
                            destination: .moderation
                        )
                    ]
                ),
                at: sections.count - 1
            )
        }

        return sections
    }

    private var isPremiumSubscribed: Bool {
        subscriptionStore.hasPremiumAccess
    }

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 0) {
                MoreHeroCard(snapshot: snapshot, profile: accountStore.profile)
                VStack(alignment: .leading, spacing: 0) {
                    NavigationLink { MorePremiumView(snapshot: snapshot) } label: { MorePremiumPromoCard(isSubscribed: isPremiumSubscribed) }.buttonStyle(.plain).padding(.top, 21).padding(.bottom, 28)
                    ForEach(sections) { section in
                        VStack(alignment: .leading, spacing: 10) {
                            MoreSectionHeader(title: section.title, color: section.color)
                            MoreSectionContainer {
                                ForEach(Array(section.items.enumerated()), id: \.element.id) { index, item in
                                    NavigationLink { destinationView(for: item) } label: { MoreUtilityRow(item: item) }.buttonStyle(.plain)
                                    if index < section.items.count - 1 { Rectangle().fill(StudyDesign.line).frame(height: 1).padding(.horizontal, 16) }
                                }
                            }
                        }.padding(.bottom, 26)
                    }
                }.padding(.horizontal, 22).padding(.bottom, 20)
            }
        }.background(SelectedHeroPageBackground()).toolbarColorScheme(.dark, for: .navigationBar).pilotNavigation()
        .onAppear {
            searchChrome.updateScope(.home)
        }
    }

    @ViewBuilder
    private func destinationView(for item: MoreHubItem) -> some View {
        PremiumContentGate(requirement: item.accessRequirement, title: item.title) {
            rawDestinationView(for: item)
        }
    }

    @ViewBuilder
    private func rawDestinationView(for item: MoreHubItem) -> some View {
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
        case .moderation:
            ModerationQueueView()
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
            videoGroups: appModel.generalLibraryVideoGroups
        )
    }
}

private struct MoreHeroCard: View {
    let snapshot: MoreHubSnapshot
    let profile: AccountProfile?
    @Environment(\.dynamicTypeSize) private var typeSize

    var body: some View {
        VStack(alignment: .leading, spacing: 0) {
            Text("More").selectedText(30, line: 34.5, weight: .bold, tracking: -1).padding(.top, 8).padding(.bottom, 9)
            Text("Your training, tools, and account.").selectedText(12, line: 18).foregroundStyle(.white.opacity(0.88))
            HStack(spacing: 12) {
                Text(snapshot.avatarInitials).font(.system(size: 17, weight: .semibold)).frame(width: 47, height: 47).accessibilityHidden(true)
                    .background(.white.opacity(0.14), in: Circle()).overlay(Circle().strokeBorder(.white.opacity(0.22)))
                VStack(alignment: .leading, spacing: 5) {
                    Text(profile?.displayTitle ?? snapshot.identityTitle).selectedText(17, weight: .bold, tracking: -0.3)
                    Text(accountSummaryLine).selectedText(11, line: 15.4).foregroundStyle(.white.opacity(0.88))
                }.frame(maxWidth: typeSize.isAccessibilitySize ? .infinity : 180, alignment: .leading)
                Spacer(minLength: 0)
            }.padding(.top, 28)
        }.frame(maxWidth: .infinity, alignment: .leading)
            .padding(.horizontal, 22).padding(.top, 15).padding(.bottom, 27).frame(minHeight: 219, alignment: .topLeading)
            .background(alignment: .bottomTrailing) { if !typeSize.isAccessibilitySize { Image("StudyAviation").resizable().scaledToFit().frame(width: 204, height: 142).offset(x: 26, y: -9).opacity(0.95).accessibilityHidden(true) } }
            .background(StudyDesign.action.ignoresSafeArea(edges: .top)).foregroundStyle(.white)
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
    @EnvironmentObject private var subscriptionStore: SubscriptionStore
    let isSubscribed: Bool
    @Environment(\.dynamicTypeSize) private var typeSize

    var body: some View {
        VStack(alignment: .leading, spacing: 14) {
            HStack(spacing: 8) { Image(systemName: "checkmark.shield").font(.system(size: 19)); Text("PRIMARY GOUGE PREMIUM").selectedText(9, line: 13, weight: .bold, tracking: 1) }.frame(minHeight: 19)
            if typeSize.isAccessibilitySize {
                VStack(alignment: .leading, spacing: 14) { membershipText; manageLabel }
            } else {
                HStack(spacing: 9) { membershipText; Spacer(minLength: 0); manageLabel }
            }
        }.foregroundStyle(StudyDesign.color(0x5F431A, 0xF5DEAD)).padding(.vertical, 16).padding(.horizontal, 17)
            .frame(maxWidth: .infinity, alignment: .leading)
            .background(LinearGradient(colors: [StudyDesign.color(0xFFF6DE, 0x443623), StudyDesign.color(0xF1D99F, 0x59442A)], startPoint: .topLeading, endPoint: .bottomTrailing), in: RoundedRectangle(cornerRadius: 22))
            .overlay(RoundedRectangle(cornerRadius: 22).strokeBorder(StudyDesign.color(0xE5CC92, 0x8E7349), lineWidth: 1))
            .accessibilityElement(children: .combine).accessibilityLabel(isSubscribed ? "Premium, active. Manage subscription" : "Premium. See Premium options")
    }
    private var membershipCaption: String {
        switch subscriptionStore.entitlement.phase {
        case .active: "Premium is active"
        case .gracePeriod: "Billing grace period"
        case .billingRetry: "Payment needs attention"
        case .expired: "Previous subscription expired"
        case .loading: "Checking membership"
        case .error: "Membership could not be verified"
        case .notSubscribed: "Unlock your full study cockpit"
        }
    }
    private var membershipText: some View {
        VStack(alignment: .leading, spacing: 4) {
            Text("Current plan").selectedText(10, line: 14)
            Text(isSubscribed ? "Premium Monthly" : "Free access").selectedText(18, line: 23.4, weight: .bold, tracking: -0.35)
            Text(membershipCaption).selectedText(10, line: 16)
        }
    }
    private var manageLabel: some View {
        HStack(spacing: 6) { Text(isSubscribed ? "Manage" : "Explore"); Image(systemName: "arrow.right") }
            .selectedText(11, weight: .semibold).foregroundStyle(StudyDesign.color(0x74551F, 0x62451C))
            .padding(.horizontal, 11).padding(.vertical, 10).frame(minHeight: 38)
            .background(StudyDesign.color(0xFFF9ED, 0xF3DFAD), in: RoundedRectangle(cornerRadius: 13))
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
        Group {
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
                .pilotText(.code)
                .foregroundStyle(accent)
                .tracking(0.7)

            Text(title)
                .pilotText(.title)
                .foregroundStyle(AppTheme.textPrimary)
                .fixedSize(horizontal: false, vertical: true)

            if let subtitle, !subtitle.isEmpty {
                Text(subtitle)
                    .pilotText(.subtitle)
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
        Text(title).selectedText(14, weight: .semibold).foregroundStyle(StudyDesign.secondary)
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
            RoundedRectangle(cornerRadius: 24, style: .continuous)
                .fill(StudyDesign.surface)
                .overlay(
                    RoundedRectangle(cornerRadius: 24, style: .continuous)
                        .stroke(StudyDesign.cardLine, lineWidth: 1)
                )
        )
    }
}

private struct MoreUtilityRow: View {
    let item: MoreHubItem
    @EnvironmentObject private var subscriptionStore: SubscriptionStore

    var body: some View {
        HStack(spacing: 12) {
            Image(systemName: item.iconName.replacingOccurrences(of: ".fill", with: "")).font(.system(size: 18, weight: .regular)).foregroundStyle(StudyDesign.blue).frame(width: 22)
            Text(item.title).selectedText(14, line: 20, weight: .semibold).foregroundStyle(StudyDesign.ink).frame(maxWidth: .infinity, alignment: .leading)
            if ContentAccessPolicy.isLocked(item.accessRequirement, subscriptionStore: subscriptionStore) { Image(systemName: "lock").font(.system(size: 11)).foregroundStyle(StudyDesign.amberInk) }
            Image(systemName: "chevron.right").font(.system(size: 12)).foregroundStyle(StudyDesign.secondary).accessibilityHidden(true)
        }.padding(.horizontal, 16).padding(.vertical, 18).frame(minHeight: 55).contentShape(Rectangle())
            .accessibilityLabel(ContentAccessPolicy.isLocked(item.accessRequirement, subscriptionStore: subscriptionStore) ? "\(item.title), Premium locked" : item.title)
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
                            title: "Study Snapshot",
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
                                title: "Weak Areas to Tighten",
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
                        title: "No Performance History Yet",
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
                    .designText(.body)
                    .foregroundStyle(AppTheme.textPrimary)

                Text(signal.detail)
                    .designText(.subtitle)
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
                        title: "No Recent Briefs Yet",
                        message: "Open a brief or reference from the General Library and it will show up here."
                    )
                } else {
                    VStack(alignment: .leading, spacing: 12) {
                        SectionHeader(
                            eyebrow: "Library",
                            title: "Recently Opened Briefs",
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
                title: "Brief Unavailable",
                message: "This recent brief could not be reopened right now."
            )
        }
    }

    private var generalLibraryShortcut: some View {
        NavigationLink {
            GeneralLibraryView(
                hubs: appModel.generalLibraryStudyHubs,
                resourceGroups: appModel.generalLibraryGroupedResources,
                videoGroups: appModel.generalLibraryVideoGroups
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
                        title: "No Recent Flashcard Sets Yet",
                        message: "Open a deck from the General Library or an event card deck and it will show up here."
                    )
                } else {
                    VStack(alignment: .leading, spacing: 12) {
                        SectionHeader(
                            eyebrow: "Library",
                            title: "Recently Opened Flashcard Sets",
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
                videoGroups: appModel.generalLibraryVideoGroups
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
            title: "Deck Unavailable",
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
                    .designText(.body)
                    .foregroundStyle(AppTheme.textPrimary)

                Text(subtitle)
                    .designText(.subtitle)
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
                    videoGroups: appModel.generalLibraryVideoGroups
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
    let accessRequirement: ContentAccessRequirement
    let destination: MoreHubDestination

    var id: String { title }

    init(
        title: String,
        subtitle: String? = nil,
        iconName: String,
        accent: Color,
        badge: MoreRowBadgeStyle? = nil,
        accessRequirement: ContentAccessRequirement = .free,
        destination: MoreHubDestination
    ) {
        self.title = title
        self.subtitle = subtitle
        self.iconName = iconName
        self.accent = accent
        self.badge = badge
        self.accessRequirement = accessRequirement
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
    case moderation
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
