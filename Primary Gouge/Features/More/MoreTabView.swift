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
            accent: AppTheme.accent,
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
            accent: AppTheme.accent,
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
                color: AppTheme.accentSoft,
                items: [
                    profileItem,
                    MoreHubItem(
                        title: "Premium",
                        subtitle: "Upgrade path for future perks",
                        iconName: "star.circle.fill",
                        accent: AppTheme.warning,
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
                        accent: AppTheme.warning,
                        badge: .planned,
                        destination: .placeholder(
                            message: "Notification controls will cover reminders, releases, and useful study nudges."
                        )
                    )
                ]
            ),
            MoreHubSection(
                title: "Study Tools",
                color: AppTheme.success,
                items: [
                    MoreHubItem(
                        title: "Quiz Mode",
                        subtitle: snapshot.quizSubtitle,
                        iconName: "checkmark.circle.fill",
                        accent: AppTheme.accent,
                        destination: .quiz
                    ),
                    MoreHubItem(
                        title: "TOLD Calculator",
                        subtitle: "Field performance inputs and outputs",
                        iconName: "function",
                        accent: AppTheme.accent,
                        badge: .planned,
                        destination: .placeholder(
                            message: "The TOLD calculator is reserved for a future utility pass."
                        )
                    ),
                    MoreHubItem(
                        title: "Fuel Planning",
                        subtitle: "Bingo, burn, and reserve helpers",
                        iconName: "fuelpump.fill",
                        accent: AppTheme.warning,
                        badge: .planned,
                        destination: .placeholder(
                            message: "Fuel planning tools will consolidate reserve math, route planning, and quick checks."
                        )
                    ),
                    MoreHubItem(
                        title: "Jet Log Helpers",
                        subtitle: "Timing, legs, and planning aids",
                        iconName: "list.clipboard.fill",
                        accent: AppTheme.success,
                        badge: .planned,
                        destination: .placeholder(
                            message: "Jet log helpers will gather reusable planning shortcuts and reference calculators."
                        )
                    ),
                    MoreHubItem(
                        title: "Flashcard Performance Stats",
                        subtitle: snapshot.flashcardStatsSubtitle,
                        iconName: "chart.bar.fill",
                        accent: AppTheme.success,
                        badge: .planned,
                        destination: .placeholder(
                            message: "A fuller stats view is planned, but the row already reflects your real flashcard and quiz activity."
                        )
                    )
                ]
            ),
            MoreHubSection(
                title: "Saved",
                color: AppTheme.warning,
                items: [
                    MoreHubItem(
                        title: "Saved Briefs",
                        subtitle: snapshot.savedBriefsSubtitle,
                        iconName: "bookmark.fill",
                        accent: AppTheme.warning,
                        badge: .planned,
                        destination: .placeholder(
                            message: "Saved briefs will eventually collect the references you return to most often."
                        )
                    ),
                    MoreHubItem(
                        title: "Saved Flashcard Sets",
                        subtitle: snapshot.savedFlashcardSetsSubtitle,
                        iconName: "rectangle.stack.fill.badge.plus",
                        accent: AppTheme.accent,
                        badge: .planned,
                        destination: .placeholder(
                            message: "Saved flashcard sets will eventually pin your highest-use decks for faster access."
                        )
                    ),
                    MoreHubItem(
                        title: "Saved Instructor Reviews",
                        subtitle: savedInstructorReviewSubtitle,
                        iconName: "person.2.crop.square.stack.fill",
                        accent: AppTheme.success,
                        destination: .instructorReviews
                    )
                ]
            ),
            MoreHubSection(
                title: "Community & Support",
                color: AppTheme.accent,
                items: [
                    MoreHubItem(
                        title: "Feedback",
                        subtitle: "Share what is working",
                        iconName: "bubble.left.and.text.bubble.right.fill",
                        accent: AppTheme.accent,
                        destination: .placeholder(
                            message: "Feedback intake will live here once the support workflow is wired up."
                        )
                    ),
                    MoreHubItem(
                        title: "Request a Feature",
                        subtitle: "Tell us what you need next",
                        iconName: "lightbulb.fill",
                        accent: AppTheme.warning,
                        destination: .placeholder(
                            message: "Feature requests will eventually route into a dedicated product feedback flow."
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
                    ),
                    MoreHubItem(
                        title: "FAQ",
                        subtitle: "Common answers and guidance",
                        iconName: "questionmark.circle.fill",
                        accent: AppTheme.accent,
                        destination: .placeholder(
                            message: "An FAQ surface is reserved for common app and study workflow questions."
                        )
                    ),
                    MoreHubItem(
                        title: "Support",
                        subtitle: "Get help with the app",
                        iconName: "lifepreserver.fill",
                        accent: AppTheme.success,
                        destination: .placeholder(
                            message: "Support options will land here once a real help channel is connected."
                        )
                    )
                ]
            ),
            MoreHubSection(
                title: "About",
                color: AppTheme.textMuted,
                items: [
                    MoreHubItem(
                        title: "Version",
                        subtitle: snapshot.versionSubtitle,
                        iconName: "number.circle.fill",
                        accent: AppTheme.accent,
                        destination: .placeholder(
                            message: "Build metadata is available now, and a fuller release details view can grow here later."
                        )
                    ),
                    MoreHubItem(
                        title: "Changelog",
                        subtitle: "What changed recently",
                        iconName: "clock.arrow.circlepath",
                        accent: AppTheme.accent,
                        badge: .planned,
                        destination: .placeholder(
                            message: "A release log is planned for future app updates."
                        )
                    ),
                    MoreHubItem(
                        title: "Privacy",
                        subtitle: "How data is handled",
                        iconName: "lock.shield.fill",
                        accent: AppTheme.success,
                        destination: .placeholder(
                            message: "Privacy details will live here once the app publishes its policy surface."
                        )
                    ),
                    MoreHubItem(
                        title: "Terms",
                        subtitle: "Usage and access terms",
                        iconName: "doc.text.fill",
                        accent: AppTheme.warning,
                        destination: .placeholder(
                            message: "Terms and access details will live here once they are ready to ship."
                        )
                    )
                ]
            )
        ]
    }

    private var savedInstructorReviewSubtitle: String {
        let instructorCount = reviewSummary.instructors
        let reviewCount = reviewSummary.reviews

        guard reviewCount > 0 else {
            return "Browse published instructor gouge"
        }

        return "\(instructorCount) instructors • \(reviewCount) reviews"
    }

    var body: some View {
        AppScrollScreen(topPadding: 16, bottomPadding: 28) {
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
        .navigationTitle("More")
        .navigationBarTitleDisplayMode(.large)
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
        case let .placeholder(message):
            MorePlaceholderDetailView(item: item, message: message, snapshot: snapshot)
        }
    }
}

private struct MoreHeroCard: View {
    let snapshot: MoreHubSnapshot
    let profileDestination: MoreHubItem
    let settingsDestination: MoreHubItem

    var body: some View {
        HeroCard(
            eyebrow: "Account",
            title: snapshot.identityTitle,
            subtitle: snapshot.currentFocusLine
        ) {
            HStack(spacing: 14) {
                ZStack {
                    Circle()
                        .fill(AppTheme.accent.opacity(0.14))
                        .frame(width: 52, height: 52)
                        .overlay(
                            Circle()
                                .stroke(AppTheme.accent.opacity(0.12), lineWidth: 1)
                        )

                    Text(snapshot.avatarInitials)
                        .font(.headline.weight(.bold))
                        .foregroundStyle(AppTheme.accent)
                }

                VStack(alignment: .leading, spacing: 4) {
                    Text("Primary Gouge profile")
                        .font(.headline.weight(.semibold))
                        .foregroundStyle(AppTheme.textPrimary)

                    Text("Quick access to app identity, defaults, and your current study posture.")
                        .font(.footnote)
                        .foregroundStyle(AppTheme.textSecondary)
                }

                Spacer(minLength: 0)
            }

            HStack(spacing: 12) {
                MetricChip(label: "Decks", value: "\(snapshot.recentDeckCount)", color: AppTheme.accent)
                MetricChip(label: "Briefs", value: "\(snapshot.recentBriefCount)", color: AppTheme.accent)
                MetricChip(label: "Quizzes", value: "\(snapshot.recentQuizCount)", color: AppTheme.accent)
            }

            HStack(spacing: 10) {
                NavigationLink {
                    MorePlaceholderDetailView(
                        item: profileDestination,
                        message: "Profile controls will eventually centralize identity, stage preferences, and saved defaults.",
                        snapshot: snapshot
                    )
                } label: {
                    MoreHeroActionButton(title: "Profile", iconName: "person.crop.circle")
                }
                .buttonStyle(.plain)

                NavigationLink {
                    MorePlaceholderDetailView(
                        item: settingsDestination,
                        message: "Settings will collect preferences, downloads, and app-level behavior in one place.",
                        snapshot: snapshot
                    )
                } label: {
                    MoreHeroActionButton(title: "Settings", iconName: "gearshape")
                }
                .buttonStyle(.plain)
            }
        }
    }
}

private struct MoreHeroActionButton: View {
    let title: String
    let iconName: String

    var body: some View {
        HStack(spacing: 8) {
            Image(systemName: iconName)
                .font(.system(size: 13, weight: .semibold))

            Text(title)
                .font(.footnote.weight(.semibold))
        }
        .foregroundStyle(AppTheme.accent)
        .padding(.horizontal, 14)
        .padding(.vertical, 10)
        .background(
            Capsule()
                .fill(AppTheme.accent.opacity(0.12))
                .overlay(
                    Capsule()
                        .stroke(AppTheme.accent.opacity(0.18), lineWidth: 1)
                )
        )
    }
}

private struct MoreSectionHeader: View {
    let title: String
    let color: Color

    var body: some View {
        Text(title.uppercased())
            .font(.caption.weight(.semibold))
            .foregroundStyle(AppTheme.accent)
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

    var body: some View {
        HStack(spacing: 14) {
            ZStack {
                RoundedRectangle(cornerRadius: 12, style: .continuous)
                    .fill(AppTheme.accent.opacity(0.10))
                    .frame(width: 36, height: 36)

                Image(systemName: item.iconName)
                    .font(.system(size: 15, weight: .semibold))
                    .foregroundStyle(AppTheme.accent)
            }

            VStack(alignment: .leading, spacing: 4) {
                HStack(spacing: 8) {
                    Text(item.title)
                        .font(.body.weight(.semibold))
                        .foregroundStyle(AppTheme.textPrimary)

                    if let badge = item.badge {
                        MoreRowBadge(style: badge)
                    }
                }

                if let subtitle = item.subtitle, !subtitle.isEmpty {
                    Text(subtitle)
                        .font(.footnote)
                        .foregroundStyle(AppTheme.textSecondary)
                        .lineLimit(1)
                }
            }

            Spacer(minLength: 8)

            Image(systemName: "chevron.right")
                .font(.system(size: 12, weight: .bold))
                .foregroundStyle(AppTheme.textMuted)
        }
        .padding(.horizontal, 14)
        .padding(.vertical, 12)
        .frame(minHeight: 68, alignment: .leading)
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

private struct MorePlaceholderDetailView: View {
    let item: MoreHubItem
    let message: String
    let snapshot: MoreHubSnapshot

    private var detailSummary: String {
        switch item.title {
        case "Flashcard Performance Stats":
            return snapshot.flashcardStatsSubtitle
        case "Saved Briefs":
            return snapshot.savedBriefsSubtitle
        case "Saved Flashcard Sets":
            return snapshot.savedFlashcardSetsSubtitle
        case "Version":
            return snapshot.versionSubtitle
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
                                    .fill(AppTheme.accent.opacity(0.10))
                                    .frame(width: 50, height: 50)

                                Image(systemName: item.iconName)
                                    .font(.system(size: 20, weight: .semibold))
                                    .foregroundStyle(AppTheme.accent)
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
        .navigationTitle(item.title)
        .navigationBarTitleDisplayMode(.inline)
    }
}

private struct MoreHubSection: Identifiable {
    let title: String
    let color: Color
    let items: [MoreHubItem]

    var id: String { title }
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
