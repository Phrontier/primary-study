import AuthenticationServices
import StoreKit
import SwiftUI
import UserNotifications
import UIKit

struct MoreProfileView: View {
    let snapshot: MoreHubSnapshot

    @EnvironmentObject private var accountStore: AccountStore
    @EnvironmentObject private var appModel: StudyAppModel
    @EnvironmentObject private var subscriptionStore: SubscriptionStore
    @State private var draftDisplayName = ""
    @State private var draftSquadronID = AccountProfile.notSureSquadronID
    @State private var draftSyllabus = SyllabusTrack.echo
    @State private var accountStatusMessage: String?
    @State private var showingDeleteConfirmation = false
    @State private var needsAppleDeleteAuthorization = false
    @State private var didLoadAccountDraft = false

    private var pinnedTopics: [HomeFocusTopicSnapshot] {
        appModel.homeScreenSnapshot.currentFocus.pinnedTopics
    }

    var body: some View {
        AppScrollScreen(topPadding: 20, bottomPadding: 32) {
            VStack(alignment: .leading, spacing: 18) {
                MoreHeaderCard(accent: MoreSectionColor.account, supportingSpacing: 14) {
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

                        MoreHeaderTextBlock(
                            eyebrow: "Account",
                            title: accountStore.profile?.displayTitle ?? snapshot.identityTitle,
                            subtitle: profileSummaryLine,
                            accent: MoreSectionColor.account
                        )

                        Spacer(minLength: 0)
                    }
                } supportingContent: {
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

                cloudAccountSection

                VStack(alignment: .leading, spacing: 12) {
                    SectionHeader(
                        eyebrow: "Focus",
                        title: "Pinned Priorities",
                        subtitle: nil
                    )

                    if pinnedTopics.isEmpty {
                        EmptyStateCard(
                            icon: "pin.slash.fill",
                            title: "No Pinned Focus Topics",
                            message: "Pick a few focus areas in Settings to keep Home centered on what matters most."
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
                        title: "Current Access",
                        subtitle: nil
                    )

                    SectionContainer {
                        VStack(alignment: .leading, spacing: 12) {
                            StatusBadge(
                                title: subscriptionStore.hasPremiumAccess ? "Premium Access" : "Standard Access",
                                iconName: "checkmark.circle.fill",
                                color: AppTheme.success
                            )

                            Text(snapshot.versionSubtitle)
                                .font(.subheadline.weight(.semibold))
                                .foregroundStyle(AppTheme.textPrimary)
                        }
                    }
                }

                accountDeletionSection
            }
        }
        .detailNavigationChrome(title: "Profile")
        .task {
            loadAccountDraftIfNeeded()
        }
        .onChange(of: draftSquadronID) { _, newValue in
            if newValue == AccountProfile.notSureSquadronID {
                draftSyllabus = .echo
            }
        }
        .alert("Delete Account?", isPresented: $showingDeleteConfirmation) {
            Button("Cancel", role: .cancel) {}
            Button("Delete", role: .destructive) {
                beginDeleteAccount()
            }
        } message: {
            Text("This deletes your cloud account and account-linked data. Deleting Primary Gouge does not cancel an active App Store subscription; manage or cancel it through Apple first if needed.")
        }
    }

    private var cloudAccountSection: some View {
        VStack(alignment: .leading, spacing: 12) {
            SectionHeader(
                eyebrow: "Your info",
                title: "Account Details",
                subtitle: nil
            )

            SectionContainer {
                VStack(alignment: .leading, spacing: 14) {
                    if let profile = accountStore.profile {
                        InsetListRow(
                            title: "Email",
                            subtitle: profile.email ?? "Private relay or Apple-only account",
                            detail: profile.emailVerified ? "Verified" : "Unverified",
                            detailColor: profile.emailVerified ? AppTheme.success : AppTheme.warning
                        ) {
                            Image(systemName: "envelope.fill")
                                .foregroundStyle(AppTheme.accent)
                                .frame(width: 20, height: 20)
                        }

                        if profile.hasPermission(.instructorGougeModerator) {
                            StatusBadge(title: "Moderator Access", iconName: "checkmark.shield.fill", color: AppTheme.statusColor(.pending))
                        }
                    }

                    AccountTextField(
                        title: "Display Name",
                        placeholder: "Optional",
                        text: $draftDisplayName,
                        textContentType: .name,
                        keyboardType: .default
                    )

                    AccountSquadronPicker(selection: $draftSquadronID)
                    AccountSyllabusPicker(selection: $draftSyllabus)

                    if let accountStatusMessage {
                        Text(accountStatusMessage)
                            .font(.footnote.weight(.semibold))
                            .foregroundStyle(AppTheme.textSecondary)
                            .fixedSize(horizontal: false, vertical: true)
                    }

                    Button {
                        saveAccountProfile()
                    } label: {
                        StudyActionButton(
                            title: accountStore.isWorking ? "Saving..." : "Save Profile",
                            icon: "checkmark.circle.fill",
                            tint: AppTheme.accent,
                            isProminent: false
                        )
                    }
                    .buttonStyle(.plain)
                    .disabled(accountStore.isWorking)
                }
            }
        }
    }

    private var accountDeletionSection: some View {
        VStack(alignment: .leading, spacing: 12) {
            SectionHeader(
                eyebrow: "Account",
                title: "Delete Account",
                subtitle: nil,
                accent: AppTheme.danger
            )

            SectionContainer(style: .standard, accent: AppTheme.danger, contentPadding: 18) {
                VStack(alignment: .leading, spacing: 14) {
                    Text("Permanently remove your Primary Gouge account and account-linked submissions. Any App Store subscription continues until you cancel it with Apple.")
                        .font(.footnote)
                        .foregroundStyle(AppTheme.textSecondary)
                        .fixedSize(horizontal: false, vertical: true)

                    if needsAppleDeleteAuthorization {
                        Text("Confirm with Apple to finish account deletion.")
                            .font(.footnote.weight(.semibold))
                            .foregroundStyle(AppTheme.textSecondary)
                            .fixedSize(horizontal: false, vertical: true)

                        appleDeletionButton
                    }

                    Button(role: .destructive) {
                        showingDeleteConfirmation = true
                    } label: {
                        StudyActionButton(
                            title: "Delete Account",
                            icon: "trash.fill",
                            tint: AppTheme.danger,
                            isProminent: false
                        )
                    }
                    .buttonStyle(.plain)
                }
            }
        }
    }

    private var profileSummaryLine: String {
        let squadronTitle = AccountProfile.squadronTitle(for: accountStore.profile?.squadronID)
        let syllabusTitle = accountStore.profile?.selectedSyllabus.title
        let details: [String] = [squadronTitle, syllabusTitle]
            .compactMap { value in
                guard let value, !value.isEmpty, value != "Not Sure Yet", value != "Not Set" else { return nil }
                return value
            }
        return details.isEmpty ? snapshot.currentFocusLine : details.joined(separator: " • ")
    }

    private var appleDeletionButton: some View {
        SignInWithAppleButton(.continue) { request in
            request.requestedScopes = []
        } onCompletion: { result in
            switch result {
            case .success(let authorization):
                guard
                    let credential = authorization.credential as? ASAuthorizationAppleIDCredential,
                    let codeData = credential.authorizationCode,
                    let authorizationCode = String(data: codeData, encoding: .utf8)
                else {
                    accountStatusMessage = "Apple did not return a deletion authorization code."
                    return
                }
                deleteAccount(appleAuthorizationCode: authorizationCode)
            case .failure(let error):
                accountStatusMessage = error.localizedDescription
            }
        }
        .signInWithAppleButtonStyle(.black)
        .frame(height: 48)
        .clipShape(RoundedRectangle(cornerRadius: 8, style: .continuous))
    }

    private func loadAccountDraftIfNeeded() {
        guard !didLoadAccountDraft else { return }
        didLoadAccountDraft = true
        let profile = accountStore.profile
        draftDisplayName = profile?.displayName ?? ""
        draftSquadronID = AccountProfile.normalizedProfileSquadronID(profile?.squadronID)
        draftSyllabus = profile?.syllabusID ?? .echo
    }

    private func saveAccountProfile() {
        accountStatusMessage = nil
        Task { @MainActor in
            do {
                try await accountStore.updateProfile(
                    displayName: draftDisplayName.nilIfEmpty,
                    squadronID: AccountProfile.normalizedProfileSquadronID(draftSquadronID),
                    syllabusID: draftSyllabus
                )
                accountStatusMessage = "Profile saved."
            } catch {
                accountStatusMessage = error.localizedDescription
            }
        }
    }

    private func beginDeleteAccount() {
        if accountStore.profile?.usesAppleSignIn == true {
            needsAppleDeleteAuthorization = true
            accountStatusMessage = "Apple confirmation is required before deletion."
            return
        }

        deleteAccount()
    }

    private func deleteAccount(appleAuthorizationCode: String? = nil) {
        Task { @MainActor in
            do {
                try await accountStore.deleteAccount(appleAuthorizationCode: appleAuthorizationCode)
            } catch {
                accountStatusMessage = error.localizedDescription
            }
        }
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
                        title: "Current Focus Topics",
                        subtitle: nil
                    )

                    SectionContainer(style: .standard, accent: MoreSectionColor.account, contentPadding: 18) {
                        VStack(alignment: .leading, spacing: 14) {
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
                MoreHeaderCard(accent: MoreSectionColor.account, supportingSpacing: 14) {
                    HStack(alignment: .center, spacing: 14) {
                        MoreHeaderTextBlock(
                            eyebrow: "Notifications",
                        title: "Daily Study Reminder",
                            subtitle: statusDescription,
                            accent: MoreSectionColor.account
                        )

                        Spacer(minLength: 12)

                        StatusBadge(
                            title: statusTitle,
                            iconName: statusIconName,
                            color: statusColor
                        )
                        .accessibilityIdentifier("premium-status")
                    }
                } supportingContent: {
                    Toggle(isOn: Binding(
                            get: { reminderEnabled },
                            set: { newValue in
                                reminderEnabled = newValue
                                guard didLoadPreferences else { return }
                                Task { await saveReminderPreferences(requestingPermission: newValue) }
                            }
                    )) {
                        VStack(alignment: .leading, spacing: 4) {
                            Text("Enable Daily Reminder")
                                .font(.headline.weight(.semibold))
                                .foregroundStyle(AppTheme.textPrimary)

                            Text("Get one daily nudge to check in on studying.")
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

                if notificationService.authorizationStatus == .denied {
                    SectionContainer {
                        VStack(alignment: .leading, spacing: 12) {
                            Text("Notifications are turned off in iPhone Settings.")
                                .font(.headline.weight(.semibold))
                                .foregroundStyle(AppTheme.textPrimary)

                            Text("Allow notifications for Primary Gouge, then come back here to turn your daily reminder back on.")
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
            return "Your reminder is set for \(reminderTime.formatted(date: .omitted, time: .shortened))."
        }

        switch notificationService.authorizationStatus {
        case .authorized, .provisional, .ephemeral:
            return reminderEnabled
                ? "Your reminder is ready to send each day."
                : "Turn this on whenever you want a daily reminder."
        case .denied:
            return reminderEnabled
                ? "Your reminder is on, but iPhone Settings are blocking notifications."
                : "Notifications are currently blocked for Primary Gouge."
        case .notDetermined:
            return "Turn this on to ask for notification permission."
        @unknown default:
            return "Notification status is unavailable right now."
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
    var lockedFeatureTitle: String? = nil
    @EnvironmentObject private var subscriptionStore: SubscriptionStore
    @State private var showingManageSubscriptions = false

    var body: some View {
        AppScrollScreen(topPadding: 20, bottomPadding: 32) {
            VStack(alignment: .leading, spacing: 18) {
                MoreHeaderCard(accent: AppTheme.warning) {
                    HStack(alignment: .center, spacing: 14) {
                        MoreHeaderTextBlock(
                            eyebrow: "Premium",
                            title: headerTitle,
                            subtitle: statusDescription,
                            accent: AppTheme.warning
                        )

                        Spacer(minLength: 12)

                        StatusBadge(
                            title: statusTitle,
                            iconName: statusIcon,
                            color: statusColor
                        )
                        .accessibilityIdentifier("premium-status")
                    }
                } supportingContent: {
                    VStack(alignment: .leading, spacing: 12) {
                        Button {
                            if subscriptionStore.hasPremiumAccess {
                                showingManageSubscriptions = true
                            } else {
                                Task { await subscriptionStore.purchase() }
                            }
                        } label: {
                            StudyActionButton(
                                title: primaryButtonTitle,
                                icon: subscriptionStore.hasPremiumAccess ? "gearshape.fill" : "star.fill",
                                tint: AppTheme.warning,
                                isProminent: true
                            )
                        }
                        .buttonStyle(.plain)
                        .disabled(
                            subscriptionStore.isWorking ||
                            subscriptionStore.purchaseIsPending ||
                            (!subscriptionStore.hasPremiumAccess && !subscriptionStore.isPurchaseLaunchEnabled)
                        )
                        .opacity(subscriptionStore.isWorking ? 0.65 : 1)

                        Button {
                            Task { await subscriptionStore.restorePurchases() }
                        } label: {
                            StudyActionButton(
                                title: "Restore Purchases",
                                icon: "arrow.clockwise.circle.fill",
                                tint: AppTheme.accent,
                                isProminent: false
                            )
                        }
                        .buttonStyle(.plain)
                        .disabled(subscriptionStore.isWorking)

                        if subscriptionStore.isWorking {
                            HStack(spacing: 10) {
                                ProgressView()
                                Text("Checking with the App Store…")
                                    .font(.footnote.weight(.semibold))
                                    .foregroundStyle(AppTheme.textSecondary)
                            }
                        }

                        if let errorMessage = subscriptionStore.errorMessage {
                            Text(errorMessage)
                                .font(.footnote.weight(.semibold))
                                .foregroundStyle(AppTheme.danger)
                                .fixedSize(horizontal: false, vertical: true)
                        }
                    }
                }

                if let lockedFeatureTitle, !subscriptionStore.hasPremiumAccess {
                    SectionContainer(style: .primary, accent: AppTheme.warning, contentPadding: 18) {
                        HStack(alignment: .top, spacing: 14) {
                            Image(systemName: "lock.fill")
                                .font(.headline.weight(.semibold))
                                .foregroundStyle(AppTheme.warning)

                            VStack(alignment: .leading, spacing: 6) {
                                Text("Unlock \(lockedFeatureTitle)")
                                    .font(.headline.weight(.semibold))
                                    .foregroundStyle(AppTheme.textPrimary)

                                Text("Start your 7-day free trial to open this and the complete Premium study library.")
                                    .font(.footnote)
                                    .foregroundStyle(AppTheme.textSecondary)
                                    .fixedSize(horizontal: false, vertical: true)
                            }
                        }
                    }
                }

                SectionContainer {
                    VStack(alignment: .leading, spacing: 12) {
                        Text("Premium Monthly")
                            .font(.headline.weight(.semibold))
                            .foregroundStyle(AppTheme.textPrimary)

                        InsetListRow(
                            title: "\(subscriptionStore.displayPrice) per month",
                            subtitle: "Eligible new subscribers receive a 7-day free trial."
                        ) {
                            Image(systemName: "calendar.badge.clock")
                                .foregroundStyle(AppTheme.warning)
                                .frame(width: 20, height: 20)
                        }

                        InsetListRow(
                            title: "Automatic Renewal",
                            subtitle: "Payment is charged to your Apple Account. The subscription renews unless cancelled at least 24 hours before the current period ends."
                        ) {
                            Image(systemName: "arrow.trianglehead.2.clockwise.rotate.90")
                                .foregroundStyle(AppTheme.warning)
                                .frame(width: 20, height: 20)
                        }

                        InsetListRow(
                            title: "Full Study Access",
                            subtitle: "Premium unlocks the complete event pipeline, study library, quizzes, videos, progress tools, and advanced preparation resources. Home, instructor gouge, emergency-reference flashcards, Contacts ground school, FAM2101, and FAM2102 remain free."
                        ) {
                            Image(systemName: "lock.open.fill")
                                .foregroundStyle(AppTheme.warning)
                                .frame(width: 20, height: 20)
                        }
                    }
                }

                SectionContainer {
                    VStack(alignment: .leading, spacing: 12) {
                        Text("Subscription Details")
                            .font(.headline.weight(.semibold))
                            .foregroundStyle(AppTheme.textPrimary)

                        NavigationLink {
                            MoreArticleView(
                                page: MoreArticleContentLoader.page(.privacy),
                                accent: MoreSectionColor.about,
                                iconName: "lock.shield.fill"
                            )
                        } label: {
                            InsetListRow(title: "Privacy Policy") {
                                Image(systemName: "lock.shield.fill")
                                    .foregroundStyle(MoreSectionColor.about)
                                    .frame(width: 20, height: 20)
                            }
                        }
                        .buttonStyle(.plain)

                        NavigationLink {
                            MoreArticleView(
                                page: MoreArticleContentLoader.page(.terms),
                                accent: MoreSectionColor.about,
                                iconName: "doc.text.fill"
                            )
                        } label: {
                            InsetListRow(title: "Terms of Use") {
                                Image(systemName: "doc.text.fill")
                                    .foregroundStyle(MoreSectionColor.about)
                                    .frame(width: 20, height: 20)
                            }
                        }
                        .buttonStyle(.plain)
                    }
                }
            }
        }
        .detailNavigationChrome(title: "Premium")
        .manageSubscriptionsSheet(isPresented: $showingManageSubscriptions)
        .task {
            await subscriptionStore.refresh()
        }
    }

    private var headerTitle: String {
        switch subscriptionStore.entitlement.phase {
        case .active, .gracePeriod: "Premium Is Active"
        case .billingRetry: "Payment Needs Attention"
        case .expired: "Premium Has Expired"
        case .loading: "Checking Premium"
        case .error, .notSubscribed: "Upgrade to Premium"
        }
    }

    private var statusDescription: String {
        switch subscriptionStore.entitlement.phase {
        case .active:
            if let date = subscriptionStore.entitlement.expirationDate {
                return "Your subscription is active through \(date.formatted(date: .abbreviated, time: .omitted))."
            }
            return "Your Premium subscription is active."
        case .gracePeriod:
            return "Premium remains available during Apple’s billing grace period."
        case .billingRetry:
            return "Apple could not renew your subscription. Update your payment method to continue."
        case .expired:
            return "Your previous Premium subscription is no longer active."
        case .loading:
            return "Checking your App Store and account entitlement."
        case .error:
            return subscriptionStore.entitlement.message ?? "Premium status could not be verified."
        case .notSubscribed:
            return "Start with a 7-day free trial, then \(subscriptionStore.displayPrice) per month."
        }
    }

    private var statusTitle: String {
        switch subscriptionStore.entitlement.phase {
        case .active: "Subscribed"
        case .gracePeriod: "Grace Period"
        case .billingRetry: "Billing Retry"
        case .expired: "Expired"
        case .loading: "Checking"
        case .error: "Unavailable"
        case .notSubscribed: "Not Subscribed"
        }
    }

    private var statusIcon: String {
        switch subscriptionStore.entitlement.phase {
        case .active, .gracePeriod: "checkmark.circle.fill"
        case .billingRetry, .error: "exclamationmark.triangle.fill"
        case .expired: "clock.badge.xmark.fill"
        case .loading: "arrow.clockwise.circle.fill"
        case .notSubscribed: "star.fill"
        }
    }

    private var statusColor: Color {
        switch subscriptionStore.entitlement.phase {
        case .active, .gracePeriod: AppTheme.success
        case .billingRetry, .error: AppTheme.danger
        case .expired, .notSubscribed, .loading: AppTheme.warning
        }
    }

    private var primaryButtonTitle: String {
        if subscriptionStore.hasPremiumAccess { return "Manage Subscription" }
        if !subscriptionStore.isPurchaseLaunchEnabled { return "Premium Launch Pending" }
        if subscriptionStore.purchaseIsPending { return "Awaiting Approval" }
        if subscriptionStore.isWorking { return "Working…" }
        return "Start 7-Day Free Trial"
    }
}

struct MoreMyInstructorReviewsView: View {
    @EnvironmentObject private var reviewStore: InstructorReviewStore
    @State private var reviews: [OwnedInstructorReview] = []
    @State private var isLoading = true
    @State private var errorMessage: String?
    @State private var reviewToEdit: OwnedInstructorReview?
    @State private var reviewToDelete: OwnedInstructorReview?
    @State private var isProcessingDelete = false

    var body: some View {
        AppScrollScreen(topPadding: 20, bottomPadding: 32) {
            VStack(alignment: .leading, spacing: 18) {
                MoreHeaderCard(accent: MoreSectionColor.saved) {
                    HStack(alignment: .center, spacing: 14) {
                        MoreHeaderTextBlock(
                            eyebrow: "Library",
                            title: "My Instructor Reviews",
                            subtitle: "View, update, or remove the reviews tied to your account.",
                            accent: MoreSectionColor.saved
                        )

                        Spacer(minLength: 12)

                        StatusBadge(
                            title: reviews.isEmpty ? "No Reviews" : "\(reviews.count)",
                            iconName: "person.2.crop.square.stack.fill",
                            color: MoreSectionColor.saved
                        )
                    }
                }

                if let errorMessage {
                    SectionContainer(style: .standard, accent: AppTheme.warning, contentPadding: 16) {
                        Text(errorMessage)
                            .font(.subheadline.weight(.semibold))
                            .foregroundStyle(AppTheme.textPrimary)
                            .fixedSize(horizontal: false, vertical: true)
                    }
                }

                if isLoading {
                    SectionContainer {
                        HStack(spacing: 12) {
                            ProgressView()
                                .tint(MoreSectionColor.saved)
                            Text("Loading your reviews...")
                                .font(.subheadline.weight(.semibold))
                                .foregroundStyle(AppTheme.textPrimary)
                        }
                        .padding(18)
                    }
                } else if reviews.isEmpty {
                    EmptyStateCard(
                        icon: "square.and.pencil",
                        title: "No Instructor Reviews Yet",
                        message: "Once you submit a review, it will show up here so you can track it, edit it, or remove it later."
                    )
                } else {
                    VStack(alignment: .leading, spacing: 14) {
                        ForEach(reviews) { review in
                            ownedReviewCard(review)
                        }
                    }
                }
            }
        }
        .detailNavigationChrome(title: "My Instructor Reviews")
        .task {
            await loadReviews()
        }
        .refreshable {
            await loadReviews()
        }
        .sheet(item: $reviewToEdit) { review in
            ReviewSubmissionView(editingReview: review) {
                Task { await loadReviews() }
            }
        }
        .alert("Delete review?", isPresented: Binding(
            get: { reviewToDelete != nil },
            set: { if !$0 { reviewToDelete = nil } }
        )) {
            Button("Cancel", role: .cancel) {
                reviewToDelete = nil
            }
            Button(isProcessingDelete ? "Removing..." : "Delete", role: .destructive) {
                guard let review = reviewToDelete else { return }
                Task { await deleteReview(review) }
            }
            .disabled(isProcessingDelete)
        } message: {
            Text("This removes the review from the public list right away and sends the delete request through moderation.")
        }
    }

    @ViewBuilder
    private func ownedReviewCard(_ review: OwnedInstructorReview) -> some View {
        SectionContainer {
            VStack(alignment: .leading, spacing: 16) {
                HStack(alignment: .top, spacing: 12) {
                    VStack(alignment: .leading, spacing: 6) {
                        Text(review.instructorName)
                            .font(.headline.weight(.semibold))
                            .foregroundStyle(AppTheme.textPrimary)

                        Text(review.squadron.displayName)
                            .font(.subheadline)
                            .foregroundStyle(AppTheme.textSecondary)

                        if let eventName = review.eventName {
                            Text(eventName)
                                .font(.footnote.weight(.semibold))
                                .foregroundStyle(AppTheme.prominentText(review.eventKind.domainColor))
                        }
                    }

                    Spacer(minLength: 12)

                    VStack(alignment: .trailing, spacing: 8) {
                        StatusBadge(
                            title: review.status.title,
                            iconName: reviewStatusIconName(review.status),
                            color: review.status.color
                        )

                        Text(review.updatedAt.formatted(date: .abbreviated, time: .omitted))
                            .font(.caption.weight(.semibold))
                            .foregroundStyle(AppTheme.textSecondary)
                    }
                }

                HStack(spacing: 12) {
                    InstructorRatingBadge(
                        title: "Chill Factor",
                        label: InstructorRatingScale.label(for: review.chillScore, category: .chillFactor),
                        subtitle: InstructorRatingScale.formatOutOfTen(score: review.chillScore),
                        score: review.chillScore,
                        style: .individual
                    )

                    InstructorRatingBadge(
                        title: "Grading Style",
                        label: InstructorRatingScale.label(for: review.gradingScore, category: .gradingStyle),
                        subtitle: InstructorRatingScale.formatOutOfTen(score: review.gradingScore),
                        score: review.gradingScore,
                        style: .individual
                    )
                }

                Text(review.reviewText)
                    .font(.body)
                    .foregroundStyle(AppTheme.textSecondary)
                    .fixedSize(horizontal: false, vertical: true)

                Text(review.status.helperText)
                    .font(.footnote)
                    .foregroundStyle(AppTheme.textSecondary)
                    .fixedSize(horizontal: false, vertical: true)

                if review.status.allowsEdit || review.status.allowsDelete {
                    HStack(spacing: 12) {
                        if review.status.allowsEdit {
                            Button {
                                reviewToEdit = review
                            } label: {
                                StudyActionButton(
                                    title: "Edit",
                                    icon: "square.and.pencil",
                                    tint: MoreSectionColor.saved,
                                    isProminent: false
                                )
                            }
                            .buttonStyle(.plain)
                        }

                        if review.status.allowsDelete {
                            Button(role: .destructive) {
                                reviewToDelete = review
                            } label: {
                                StudyActionButton(
                                    title: "Delete",
                                    icon: "trash.fill",
                                    tint: AppTheme.danger,
                                    isProminent: false
                                )
                            }
                            .buttonStyle(.plain)
                        }
                    }
                }
            }
            .padding(18)
        }
    }

    private func loadReviews() async {
        isLoading = true
        errorMessage = nil

        do {
            reviews = try await reviewStore.fetchOwnedReviews()
        } catch {
            errorMessage = error.localizedDescription
        }

        isLoading = false
    }

    private func deleteReview(_ review: OwnedInstructorReview) async {
        guard let reviewID = review.publicReviewID else { return }
        isProcessingDelete = true
        errorMessage = nil

        defer {
            isProcessingDelete = false
            reviewToDelete = nil
        }

        do {
            try await reviewStore.requestOwnedReviewDeletion(reviewID: reviewID)
            await loadReviews()
        } catch {
            errorMessage = error.localizedDescription
        }
    }

    private func reviewStatusIconName(_ status: OwnedInstructorReviewStatus) -> String {
        switch status {
        case .approved:
            return "checkmark.circle.fill"
        case .pendingCreate, .pendingEdit, .pendingDelete:
            return "clock.badge.fill"
        case .rejectedCreate, .rejectedEdit, .rejectedDelete:
            return "xmark.circle.fill"
        case .removed:
            return "trash.fill"
        }
    }
}
