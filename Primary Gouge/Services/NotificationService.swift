import Foundation
import Combine
import UserNotifications

@MainActor
final class NotificationService: ObservableObject {
    static let trialReminderIdentifier = "primary-gouge-trial-ending-reminder"
    static let dailyReminderIdentifier = "primary-gouge-daily-study-reminder"

    @Published private(set) var authorizationStatus: UNAuthorizationStatus = .notDetermined
    @Published private(set) var hasScheduledDailyReminder = false

    private let center: UNUserNotificationCenter
    private var accountGeneration = 0
    private var dailyGeneration = 0

    init(center: UNUserNotificationCenter = .current()) {
        self.center = center
    }

    func refreshStatus() async {
        let settings = await notificationSettings()
        authorizationStatus = settings.authorizationStatus
        let requests = await pendingRequests()
        hasScheduledDailyReminder = requests.contains { $0.identifier == Self.dailyReminderIdentifier }
    }

    @discardableResult
    func requestAuthorization() async -> Bool {
        let granted = await withCheckedContinuation { continuation in
            center.requestAuthorization(options: [.alert, .badge, .sound]) { granted, _ in
                continuation.resume(returning: granted)
            }
        }
        await refreshStatus()
        return granted
    }

    func syncDailyStudyReminder(with preferences: HomePreferencesRecord) async {
        let generation = accountGeneration
        let dailyRevision = dailyGeneration
        await refreshStatus()
        guard generation == accountGeneration && dailyRevision == dailyGeneration else { return }

        guard preferences.dailyReminderEnabled else {
            await removeDailyStudyReminder()
            return
        }

        guard authorizationStatus == .authorized || authorizationStatus == .provisional || authorizationStatus == .ephemeral else {
            hasScheduledDailyReminder = false
            return
        }

        let content = UNMutableNotificationContent()
        content.title = "Daily study reminder"
        content.body = "Open Primary Gouge and knock out a quick review session."
        content.sound = .default

        var components = DateComponents()
        components.hour = preferences.dailyReminderHour
        components.minute = preferences.dailyReminderMinute

        let trigger = UNCalendarNotificationTrigger(dateMatching: components, repeats: true)
        let request = UNNotificationRequest(
            identifier: Self.dailyReminderIdentifier,
            content: content,
            trigger: trigger
        )

        await removePendingRequests(for: [Self.dailyReminderIdentifier])
        guard generation == accountGeneration && dailyRevision == dailyGeneration else { return }
        await withCheckedContinuation { continuation in
            center.add(request) { _ in
                continuation.resume()
            }
        }
        guard generation == accountGeneration && dailyRevision == dailyGeneration else {
            center.removePendingNotificationRequests(withIdentifiers: [Self.dailyReminderIdentifier])
            return
        }
        await refreshStatus()
    }

    /// Schedule only after a verified eligible trial purchase; use Apple's actual expiration.
    @discardableResult
    func scheduleTrialEndingReminder(endsAt: Date) async -> Bool {
        let generation = accountGeneration
        await refreshStatus()
        guard generation == accountGeneration,
              authorizationStatus == .authorized || authorizationStatus == .provisional else { return false }
        guard let request = TrialReminderPlan.request(endsAt: endsAt, now: .now, authorization: authorizationStatus) else { return false }
        do {
            try await center.add(request)
            guard generation == accountGeneration else {
                center.removePendingNotificationRequests(withIdentifiers: [Self.trialReminderIdentifier])
                return false
            }
            return true
        } catch { return false }
    }

    func removeDailyStudyReminder() async {
        dailyGeneration += 1
        center.removePendingNotificationRequests(withIdentifiers: [Self.dailyReminderIdentifier])
        center.removeDeliveredNotifications(withIdentifiers: [Self.dailyReminderIdentifier])
        hasScheduledDailyReminder = false
        await refreshStatus()
    }

    func clearAccountReminders() {
        accountGeneration += 1
        dailyGeneration += 1
        center.removePendingNotificationRequests(withIdentifiers: [Self.dailyReminderIdentifier, Self.trialReminderIdentifier])
        center.removeDeliveredNotifications(withIdentifiers: [Self.dailyReminderIdentifier, Self.trialReminderIdentifier])
        hasScheduledDailyReminder = false
    }

    private func removePendingRequests(for identifiers: [String]) async {
        center.removePendingNotificationRequests(withIdentifiers: identifiers)
    }

    private func notificationSettings() async -> UNNotificationSettings {
        await withCheckedContinuation { continuation in
            center.getNotificationSettings { settings in
                continuation.resume(returning: settings)
            }
        }
    }

    private func pendingRequests() async -> [UNNotificationRequest] {
        await withCheckedContinuation { continuation in
            center.getPendingNotificationRequests { requests in
                continuation.resume(returning: requests)
            }
        }
    }
}

/// Shared scheduling policy: no past trigger and no claim without notification permission.
enum TrialReminderPlan {
    static func request(endsAt: Date, now: Date, authorization: UNAuthorizationStatus) -> UNNotificationRequest? {
        guard authorization == .authorized || authorization == .provisional else { return nil }
        let fireDate = endsAt.addingTimeInterval(-2 * 24 * 60 * 60)
        guard fireDate > now else { return nil }
        let content = UNMutableNotificationContent()
        content.title = "Your Primary Gouge trial is ending soon"
        content.body = "Your trial ends in two days. Manage or cancel renewal in your Apple subscription settings."
        content.sound = .default
        let trigger = UNCalendarNotificationTrigger(dateMatching: Calendar.current.dateComponents([.year, .month, .day, .hour, .minute], from: fireDate), repeats: false)
        return UNNotificationRequest(identifier: "primary-gouge-trial-ending-reminder", content: content, trigger: trigger)
    }
}
