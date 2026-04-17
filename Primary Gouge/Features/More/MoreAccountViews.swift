import SwiftUI
import UserNotifications
import UIKit

struct MoreProfileView: View {
    let snapshot: MoreHubSnapshot

    @EnvironmentObject private var appModel: StudyAppModel

    private var pinnedTopics: [HomeFocusTopicSnapshot] {
        appModel.homeScreenSnapshot.currentFocus.pinnedTopics
    }

    var body: some View {
        AppScrollScreen(topPadding: 20, bottomPadding: 32) {
            VStack(alignment: .leading, spacing: 18) {
                SectionContainer(style: .rootSummary, accent: MoreSectionColor.account, contentPadding: 20) {
                    VStack(alignment: .leading, spacing: 14) {
                        HStack(alignment: .center, spacing: 14) {
                            ZStack {
                                Circle()
                                    .fill(AppTheme.badgeFill(MoreSectionColor.account))
                                    .frame(width: 54, height: 54)
                                    .overlay(
                                        Circle()
                                            .stroke(AppTheme.badgeStroke(MoreSectionColor.account), lineWidth: 1)
                                    )

                                Text(snapshot.avatarInitials)
                                    .font(.title3.weight(.bold))
                                    .foregroundStyle(AppTheme.iconTint(MoreSectionColor.account))
                            }

                            VStack(alignment: .leading, spacing: 6) {
                                Text("ACCOUNT")
                                    .font(.caption.weight(.semibold))
                                    .foregroundStyle(MoreSectionColor.account)
                                    .tracking(0.7)

                                Text(snapshot.identityTitle)
                                    .font(.title3.weight(.semibold))
                                    .foregroundStyle(AppTheme.textPrimary)

                                Text(snapshot.currentFocusLine)
                                    .font(.subheadline)
                                    .foregroundStyle(AppTheme.textSecondary)
                            }

                            Spacer(minLength: 0)
                        }

                        HStack(spacing: 12) {
                            CompactMetricChip(
                                label: "Quizzes",
                                value: "\(snapshot.recentQuizCount)",
                                color: AppTheme.domainColor(.quizzes),
                                iconName: "checkmark.circle.fill"
                            )

                            CompactMetricChip(
                                label: "Briefs",
                                value: "\(snapshot.recentBriefCount)",
                                color: MoreSectionColor.saved,
                                iconName: "bookmark.fill"
                            )

                            CompactMetricChip(
                                label: "Decks",
                                value: "\(snapshot.recentDeckCount)",
                                color: AppTheme.domainColor(.flashcards),
                                iconName: "rectangle.stack.fill"
                            )
                        }
                    }
                }

                VStack(alignment: .leading, spacing: 12) {
                    SectionHeader(
                        eyebrow: "Focus",
                        title: "Pinned priorities",
                        subtitle: nil
                    )

                    if pinnedTopics.isEmpty {
                        EmptyStateCard(
                            icon: "pin.slash.fill",
                            title: "No pinned focus topics",
                            message: "Use Settings to choose a few focus areas and keep Home centered on what matters most."
                        )
                    } else {
                        SectionContainer {
                            VStack(alignment: .leading, spacing: 12) {
                                ForEach(pinnedTopics) { topic in
                                    InsetListRow(title: topic.title) {
                                        Image(systemName: topic.iconName)
                                            .foregroundStyle(AppTheme.accent)
                                            .frame(width: 20, height: 20)
                                    }
                                }
                            }
                        }
                    }
                }

                VStack(alignment: .leading, spacing: 12) {
                    SectionHeader(
                        eyebrow: "App",
                        title: "Current access",
                        subtitle: nil
                    )

                    SectionContainer {
                        VStack(alignment: .leading, spacing: 12) {
                            StatusBadge(title: "Standard Access", iconName: "checkmark.circle.fill", color: AppTheme.success)

                            Text(snapshot.versionSubtitle)
                                .font(.subheadline.weight(.semibold))
                                .foregroundStyle(AppTheme.textPrimary)

                            Text("This profile is local to the device right now and reflects your current study preferences and activity.")
                                .font(.footnote)
                                .foregroundStyle(AppTheme.textSecondary)
                                .fixedSize(horizontal: false, vertical: true)
                        }
                    }
                }
            }
        }
        .detailNavigationChrome(title: "Profile")
    }
}

struct MoreSettingsView: View {
    let snapshot: MoreHubSnapshot

    @EnvironmentObject private var appModel: StudyAppModel
    @State private var showingFocusManager = false

    private var pinnedTopics: [HomeFocusTopicSnapshot] {
        appModel.homeScreenSnapshot.currentFocus.pinnedTopics
    }

    var body: some View {
        AppScrollScreen(topPadding: 20, bottomPadding: 32) {
            VStack(alignment: .leading, spacing: 18) {
                VStack(alignment: .leading, spacing: 12) {
                    SectionHeader(
                        eyebrow: "Preferences",
                        title: "Current focus topics",
                        subtitle: nil
                    )

                    SectionContainer(style: .standard, accent: MoreSectionColor.account, contentPadding: 18) {
                        VStack(alignment: .leading, spacing: 14) {
                            Text("Your pinned focus topics drive what Home keeps front and center.")
                                .font(.footnote)
                                .foregroundStyle(AppTheme.textSecondary)
                                .fixedSize(horizontal: false, vertical: true)

                            if pinnedTopics.isEmpty {
                                Text("No pinned focus topics yet.")
                                    .font(.subheadline.weight(.semibold))
                                    .foregroundStyle(AppTheme.textPrimary)
                            } else {
                                VStack(alignment: .leading, spacing: 10) {
                                    ForEach(pinnedTopics) { topic in
                                        InsetListRow(title: topic.title) {
                                            Image(systemName: topic.iconName)
                                                .foregroundStyle(AppTheme.accent)
                                                .frame(width: 20, height: 20)
                                        }
                                    }
                                }
                            }

                            Button {
                                showingFocusManager = true
                            } label: {
                                StudyActionButton(
                                    title: pinnedTopics.isEmpty ? "Choose Focus Topics" : "Edit Focus Topics",
                                    icon: "pin.fill",
                                    tint: MoreSectionColor.account,
                                    isProminent: false
                                )
                            }
                            .buttonStyle(.plain)
                        }
                    }
                }

                VStack(alignment: .leading, spacing: 12) {
                    SectionHeader(
                        eyebrow: "Behavior",
                        title: "Settings direction",
                        subtitle: nil
                    )

                    EmptyStateCard(
                        icon: "gearshape.2.fill",
                        title: "Focused for MVP",
                        message: "This first settings pass is centered on study priorities. Notification timing lives in the Notifications row, and additional app-level controls can grow here later."
                    )
                }
            }
        }
        .sheet(isPresented: $showingFocusManager) {
            FocusTopicManagerSheet(
                selectedTopicIDs: appModel.homePreferences.pinnedTopicIDs,
                topics: appModel.studyTopics.filter(\.isUserFocusable)
            ) { topicIDs in
                appModel.setPinnedTopicIDs(topicIDs)
            }
        }
        .detailNavigationChrome(title: "Settings")
    }
}

struct MoreNotificationsView: View {
    @EnvironmentObject private var appModel: StudyAppModel
    @EnvironmentObject private var notificationService: NotificationService
    @Environment(\.openURL) private var openURL
    @Environment(\.scenePhase) private var scenePhase

    @State private var reminderEnabled = false
    @State private var reminderTime = Date()
    @State private var didLoadPreferences = false

    var body: some View {
        AppScrollScreen(topPadding: 20, bottomPadding: 32) {
            VStack(alignment: .leading, spacing: 18) {
                SectionContainer(style: .rootSummary, accent: MoreSectionColor.account, contentPadding: 18) {
                    VStack(alignment: .leading, spacing: 14) {
                        HStack {
                            VStack(alignment: .leading, spacing: 6) {
                                Text("NOTIFICATIONS")
                                    .font(.caption.weight(.semibold))
                                    .foregroundStyle(MoreSectionColor.account)
                                    .tracking(0.7)

                                Text("Daily study reminder")
                                    .font(.title3.weight(.semibold))
                                    .foregroundStyle(AppTheme.textPrimary)

                                Text(statusDescription)
                                    .font(.subheadline)
                                    .foregroundStyle(AppTheme.textSecondary)
                            }

                            Spacer(minLength: 12)

                            StatusBadge(
                                title: statusTitle,
                                iconName: statusIconName,
                                color: statusColor
                            )
                        }

                        Toggle(isOn: Binding(
                            get: { reminderEnabled },
                            set: { newValue in
                                reminderEnabled = newValue
                                guard didLoadPreferences else { return }
                                Task { await saveReminderPreferences(requestingPermission: newValue) }
                            }
                        )) {
                            VStack(alignment: .leading, spacing: 4) {
                                Text("Enable daily reminder")
                                    .font(.headline.weight(.semibold))
                                    .foregroundStyle(AppTheme.textPrimary)

                                Text("Use one local reminder to nudge a quick study check-in each day.")
                                    .font(.footnote)
                                    .foregroundStyle(AppTheme.textSecondary)
                                    .fixedSize(horizontal: false, vertical: true)
                            }
                        }
                        .tint(MoreSectionColor.account)

                        DatePicker(
                            "Reminder time",
                            selection: Binding(
                                get: { reminderTime },
                                set: { newValue in
                                    reminderTime = newValue
                                    guard didLoadPreferences else { return }
                                    Task { await saveReminderPreferences(requestingPermission: false) }
                                }
                            ),
                            displayedComponents: .hourAndMinute
                        )
                        .disabled(!reminderEnabled)
                    }
                }

                if notificationService.authorizationStatus == .denied {
                    SectionContainer {
                        VStack(alignment: .leading, spacing: 12) {
                            Text("Notifications are blocked in iOS Settings.")
                                .font(.headline.weight(.semibold))
                                .foregroundStyle(AppTheme.textPrimary)

                            Text("Open system settings to allow notifications for Primary Gouge, then come back here and your saved reminder preference will be ready to schedule.")
                                .font(.footnote)
                                .foregroundStyle(AppTheme.textSecondary)
                                .fixedSize(horizontal: false, vertical: true)

                            Button {
                                if let url = URL(string: UIApplication.openSettingsURLString) {
                                    openURL(url)
                                }
                            } label: {
                                StudyActionButton(
                                    title: "Open iOS Settings",
                                    icon: "arrow.up.right.square.fill",
                                    tint: AppTheme.warning,
                                    isProminent: false
                                )
                            }
                            .buttonStyle(.plain)
                        }
                    }
                }

                SectionContainer {
                    VStack(alignment: .leading, spacing: 10) {
                        Text("How it works")
                            .font(.headline.weight(.semibold))
                            .foregroundStyle(AppTheme.textPrimary)

                        Text("This MVP supports one local daily study reminder. There are no push notifications, multiple reminder types, or cloud-backed schedules yet.")
                            .font(.footnote)
                            .foregroundStyle(AppTheme.textSecondary)
                            .fixedSize(horizontal: false, vertical: true)
                    }
                }
            }
        }
        .task {
            syncFromPreferences()
            await notificationService.refreshStatus()
        }
        .onChange(of: scenePhase) { _, newValue in
            guard newValue == .active else { return }
            Task { await notificationService.refreshStatus() }
        }
        .detailNavigationChrome(title: "Notifications")
    }

    private var statusTitle: String {
        if reminderEnabled && notificationService.hasScheduledDailyReminder {
            return "Scheduled"
        }

        switch notificationService.authorizationStatus {
        case .authorized, .provisional, .ephemeral:
            return reminderEnabled ? "Ready" : "Available"
        case .denied:
            return "Blocked"
        case .notDetermined:
            return "Permission Needed"
        @unknown default:
            return "Unavailable"
        }
    }

    private var statusDescription: String {
        if reminderEnabled && notificationService.hasScheduledDailyReminder {
            return "A local reminder is scheduled for \(reminderTime.formatted(date: .omitted, time: .shortened))."
        }

        switch notificationService.authorizationStatus {
        case .authorized, .provisional, .ephemeral:
            return reminderEnabled
                ? "Reminder is enabled in the app and ready to schedule."
                : "Notifications are available whenever you want to turn on a daily reminder."
        case .denied:
            return reminderEnabled
                ? "Daily reminders are turned on in the app, but iOS is blocking delivery."
                : "iOS is currently blocking notifications for Primary Gouge."
        case .notDetermined:
            return "Enable the reminder to request notification permission."
        @unknown default:
            return "Notification availability could not be determined."
        }
    }

    private var statusIconName: String {
        if reminderEnabled && notificationService.hasScheduledDailyReminder {
            return "bell.badge.fill"
        }

        switch notificationService.authorizationStatus {
        case .authorized, .provisional, .ephemeral:
            return "checkmark.circle.fill"
        case .denied:
            return "bell.slash.fill"
        case .notDetermined:
            return "bell.fill"
        @unknown default:
            return "questionmark.circle.fill"
        }
    }

    private var statusColor: Color {
        if reminderEnabled && notificationService.hasScheduledDailyReminder {
            return AppTheme.success
        }

        switch notificationService.authorizationStatus {
        case .authorized, .provisional, .ephemeral:
            return MoreSectionColor.account
        case .denied:
            return AppTheme.warning
        case .notDetermined:
            return AppTheme.accent
        @unknown default:
            return AppTheme.textMuted
        }
    }

    private func syncFromPreferences() {
        let preferences = appModel.homePreferences
        reminderEnabled = preferences.dailyReminderEnabled
        reminderTime = reminderDate(hour: preferences.dailyReminderHour, minute: preferences.dailyReminderMinute)
        didLoadPreferences = true
    }

    private func saveReminderPreferences(requestingPermission: Bool) async {
        if requestingPermission && reminderEnabled && notificationService.authorizationStatus == .notDetermined {
            _ = await notificationService.requestAuthorization()
        }

        let components = Calendar.current.dateComponents([.hour, .minute], from: reminderTime)
        let hour = components.hour ?? 19
        let minute = components.minute ?? 0
        appModel.updateDailyReminder(enabled: reminderEnabled, hour: hour, minute: minute)
        await notificationService.syncDailyStudyReminder(with: appModel.homePreferences)
    }

    private func reminderDate(hour: Int, minute: Int) -> Date {
        let calendar = Calendar.current
        let now = Date()
        return calendar.date(
            bySettingHour: hour,
            minute: minute,
            second: 0,
            of: now
        ) ?? now
    }
}

struct MorePremiumView: View {
    let snapshot: MoreHubSnapshot

    var body: some View {
        AppScrollScreen(topPadding: 20, bottomPadding: 32) {
            VStack(alignment: .leading, spacing: 18) {
                SectionContainer(style: .rootSummary, accent: AppTheme.warning, contentPadding: 18) {
                    VStack(alignment: .leading, spacing: 14) {
                        HStack {
                            VStack(alignment: .leading, spacing: 6) {
                                Text("PREMIUM")
                                    .font(.caption.weight(.semibold))
                                    .foregroundStyle(AppTheme.warning)
                                    .tracking(0.7)

                                Text("Standard access")
                                    .font(.title3.weight(.semibold))
                                    .foregroundStyle(AppTheme.textPrimary)

                                Text("Everything in Primary Gouge is currently available without a paid tier.")
                                    .font(.subheadline)
                                    .foregroundStyle(AppTheme.textSecondary)
                                    .fixedSize(horizontal: false, vertical: true)
                            }

                            Spacer(minLength: 12)

                            StatusBadge(title: "Included", iconName: "checkmark.circle.fill", color: AppTheme.success)
                        }
                    }
                }

                SectionContainer {
                    VStack(alignment: .leading, spacing: 12) {
                        Text("Potential future premium direction")
                            .font(.headline.weight(.semibold))
                            .foregroundStyle(AppTheme.textPrimary)

                        InsetListRow(title: "Advanced planner tools", subtitle: "Expanded utility flows like TOLD, fuel planning, or jet-log support.") {
                            Image(systemName: "function")
                                .foregroundStyle(AppTheme.warning)
                                .frame(width: 20, height: 20)
                        }

                        InsetListRow(title: "Heavier personalization", subtitle: "Deeper preference and study setup controls across devices.") {
                            Image(systemName: "slider.horizontal.3")
                                .foregroundStyle(AppTheme.warning)
                                .frame(width: 20, height: 20)
                        }

                        InsetListRow(title: "Enhanced reminder workflows", subtitle: "More reminder types and schedule flexibility beyond the MVP daily reminder.") {
                            Image(systemName: "bell.badge.fill")
                                .foregroundStyle(AppTheme.warning)
                                .frame(width: 20, height: 20)
                        }
                    }
                }
            }
        }
        .detailNavigationChrome(title: "Premium")
    }
}
