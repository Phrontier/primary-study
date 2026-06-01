import SwiftUI
import UserNotifications

enum MoreArticlePageID: String {
    case faq
    case changelog
    case privacy
    case terms
}

struct MoreArticlePage: Decodable, Hashable {
    let id: String
    let title: String
    let eyebrow: String
    let summary: String
    let sections: [MoreArticleSection]
}

struct MoreArticleSection: Decodable, Hashable {
    let title: String
    let paragraphs: [String]
    let bullets: [String]?
}

private struct MoreArticleManifest: Decodable {
    let pages: [MoreArticlePage]
}

enum MoreArticleContentLoader {
    static func page(_ id: MoreArticlePageID, repository: ContentRepository = .preview) -> MoreArticlePage {
        guard
            let url = repository.fileURL(for: "AppContent/MoreArticles.json"),
            let data = try? Data(contentsOf: url),
            let manifest = try? JSONDecoder().decode(MoreArticleManifest.self, from: data),
            let page = manifest.pages.first(where: { $0.id == id.rawValue })
        else {
            return MoreArticlePage(
                id: id.rawValue,
                title: id.rawValue.capitalized,
                eyebrow: "About",
                summary: "Content unavailable.",
                sections: []
            )
        }

        return page
    }
}

struct MoreArticleView: View {
    let page: MoreArticlePage
    let accent: Color
    let iconName: String

    var body: some View {
        AppScrollScreen(topPadding: 20, bottomPadding: 32) {
            VStack(alignment: .leading, spacing: 18) {
                MoreHeaderCard(accent: accent) {
                    HStack(alignment: .center, spacing: 14) {
                        ZStack {
                            RoundedRectangle(cornerRadius: 16, style: .continuous)
                                .fill(AppTheme.badgeFill(accent))
                                .frame(width: 46, height: 46)
                                .overlay(
                                    RoundedRectangle(cornerRadius: 16, style: .continuous)
                                        .stroke(AppTheme.badgeStroke(accent), lineWidth: 1)
                                )

                            Image(systemName: iconName)
                                .font(.system(size: 18, weight: .semibold))
                                .foregroundStyle(AppTheme.iconTint(accent))
                        }

                        MoreHeaderTextBlock(
                            eyebrow: page.eyebrow,
                            title: page.title,
                            subtitle: page.summary,
                            accent: accent
                        )
                    }
                }

                ForEach(page.sections.indices, id: \.self) { index in
                    let section = page.sections[index]
                    VStack(alignment: .leading, spacing: 12) {
                        SectionHeader(
                            eyebrow: page.eyebrow,
                            title: section.title,
                            subtitle: nil,
                            accent: accent
                        )

                        MoreArticleViewSection(section: section, accent: accent)
                    }
                }
            }
        }
        .detailNavigationChrome(title: page.title)
    }
}

private struct MoreArticleViewSection: View {
    let section: MoreArticleSection
    let accent: Color

    var body: some View {
        SectionContainer {
            VStack(alignment: .leading, spacing: 14) {
                ForEach(section.paragraphs.indices, id: \.self) { index in
                    Text(section.paragraphs[index])
                        .font(.body)
                        .foregroundStyle(AppTheme.textSecondary)
                        .fixedSize(horizontal: false, vertical: true)
                }

                if let bullets = section.bullets, !bullets.isEmpty {
                    VStack(alignment: .leading, spacing: 12) {
                        ForEach(bullets.indices, id: \.self) { index in
                            HStack(alignment: .top, spacing: 10) {
                                Circle()
                                    .fill(accent)
                                    .frame(width: 7, height: 7)
                                    .padding(.top, 7)

                                Text(bullets[index])
                                    .font(.body)
                                    .foregroundStyle(AppTheme.textSecondary)
                                    .fixedSize(horizontal: false, vertical: true)
                            }
                        }
                    }
                }
            }
            .padding(18)
        }
    }
}

struct MoreVersionView: View {
    let snapshot: MoreHubSnapshot

    @EnvironmentObject private var reviewStore: InstructorReviewStore
    @EnvironmentObject private var communityStore: CommunitySubmissionStore
    @EnvironmentObject private var notificationService: NotificationService
    @EnvironmentObject private var appModel: StudyAppModel

    private var buildNumber: String {
        Bundle.main.object(forInfoDictionaryKey: "CFBundleVersion") as? String ?? "Unavailable"
    }

    private var marketingVersion: String {
        Bundle.main.object(forInfoDictionaryKey: "CFBundleShortVersionString") as? String ?? "Unavailable"
    }

    private var reminderStatus: String {
        let preferences = appModel.homePreferences
        guard preferences.dailyReminderEnabled else {
            return "Daily reminder is off."
        }

        let formatter = DateFormatter()
        formatter.timeStyle = .short
        let date = Calendar.current.date(
            bySettingHour: preferences.dailyReminderHour,
            minute: preferences.dailyReminderMinute,
            second: 0,
            of: .now
        ) ?? .now
        return "Daily reminder set for \(formatter.string(from: date))."
    }

    var body: some View {
        AppScrollScreen(topPadding: 20, bottomPadding: 32) {
            VStack(alignment: .leading, spacing: 18) {
                MoreHeaderCard(accent: MoreSectionColor.about) {
                    HStack(alignment: .center, spacing: 14) {
                        ZStack {
                            RoundedRectangle(cornerRadius: 16, style: .continuous)
                                .fill(AppTheme.badgeFill(MoreSectionColor.about))
                                .frame(width: 46, height: 46)
                                .overlay(
                                    RoundedRectangle(cornerRadius: 16, style: .continuous)
                                        .stroke(AppTheme.badgeStroke(MoreSectionColor.about), lineWidth: 1)
                                )

                            Image(systemName: "number.circle.fill")
                                .font(.system(size: 18, weight: .semibold))
                                .foregroundStyle(AppTheme.iconTint(MoreSectionColor.about))
                        }

                        MoreHeaderTextBlock(
                            eyebrow: "About",
                            title: snapshot.versionSubtitle,
                            subtitle: "Build \(buildNumber) • iOS",
                            accent: MoreSectionColor.about
                        )
                    }
                }

                VStack(alignment: .leading, spacing: 12) {
                    SectionHeader(
                        eyebrow: "Release",
                        title: "App details",
                        subtitle: nil,
                        accent: MoreSectionColor.about
                    )

                    MoreSectionContainer {
                        MoreInfoRow(title: "Marketing Version", value: marketingVersion, iconName: "tag.fill", accent: MoreSectionColor.about)
                        Divider()
                            .overlay(AppTheme.cardStroke.opacity(0.9))
                            .padding(.leading, 62)
                        MoreInfoRow(title: "Build", value: buildNumber, iconName: "hammer.fill", accent: MoreSectionColor.about)
                    }
                }

                VStack(alignment: .leading, spacing: 12) {
                    SectionHeader(
                        eyebrow: "Backend",
                        title: "Cloudflare status",
                        subtitle: nil,
                        accent: MoreSectionColor.support
                    )

                    SectionContainer {
                        VStack(alignment: .leading, spacing: 14) {
                            StatusBadge(
                                title: reviewStore.isRemoteConfigured ? "Configured" : "Not Configured",
                                iconName: reviewStore.isRemoteConfigured ? "checkmark.circle.fill" : "xmark.circle.fill",
                                color: reviewStore.isRemoteConfigured ? AppTheme.success : AppTheme.warning
                            )

                            Text(communityStore.syncStatus.configurationDetail ?? reviewStore.syncStatus.configurationDetail ?? "No backend detail available.")
                                .font(.subheadline)
                                .foregroundStyle(AppTheme.textSecondary)
                                .fixedSize(horizontal: false, vertical: true)

                            if let lastSyncedAt = communityStore.syncStatus.lastSyncedAt ?? reviewStore.syncStatus.lastSyncedAt {
                                Text("Last sync: \(lastSyncedAt.formatted(date: .abbreviated, time: .shortened))")
                                    .font(.footnote.weight(.semibold))
                                    .foregroundStyle(AppTheme.textPrimary)
                            }
                        }
                    }
                }

                VStack(alignment: .leading, spacing: 12) {
                    SectionHeader(
                        eyebrow: "Local services",
                        title: "Notifications",
                        subtitle: nil,
                        accent: MoreSectionColor.account
                    )

                    SectionContainer {
                        VStack(alignment: .leading, spacing: 14) {
                            StatusBadge(
                                title: notificationService.hasScheduledDailyReminder ? "Scheduled" : "Not Scheduled",
                                iconName: notificationService.hasScheduledDailyReminder ? "bell.badge.fill" : "bell.slash.fill",
                                color: notificationService.hasScheduledDailyReminder ? AppTheme.success : AppTheme.warning
                            )

                            Text(reminderStatus)
                                .font(.subheadline)
                                .foregroundStyle(AppTheme.textSecondary)
                                .fixedSize(horizontal: false, vertical: true)

                            Text("Notification authorization: \(notificationService.authorizationStatus.displayName)")
                                .font(.footnote.weight(.semibold))
                                .foregroundStyle(AppTheme.textPrimary)
                        }
                    }
                }
            }
        }
        .detailNavigationChrome(title: "Version")
        .task {
            await notificationService.refreshStatus()
        }
    }
}

private struct MoreInfoRow: View {
    let title: String
    let value: String
    let iconName: String
    let accent: Color

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

                Text(value)
                    .font(.subheadline)
                    .foregroundStyle(AppTheme.textSecondary)
            }

            Spacer(minLength: 0)
        }
        .padding(.horizontal, 14)
        .padding(.vertical, 13)
    }
}

private extension UNAuthorizationStatus {
    var displayName: String {
        switch self {
        case .notDetermined:
            return "Not Determined"
        case .denied:
            return "Denied"
        case .authorized:
            return "Authorized"
        case .provisional:
            return "Provisional"
        case .ephemeral:
            return "Ephemeral"
        @unknown default:
            return "Unknown"
        }
    }
}
