import Foundation
import Combine
import UserNotifications

@MainActor
final class NotificationService: ObservableObject {
    static let dailyReminderIdentifier = "primary-gouge-daily-study-reminder"

    @Published private(set) var authorizationStatus: UNAuthorizationStatus = .notDetermined
    @Published private(set) var hasScheduledDailyReminder = false

    private let center: UNUserNotificationCenter
    private var accountGeneration = 0

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
        await refreshStatus()
        guard generation == accountGeneration else { return }

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
        guard generation == accountGeneration else { return }
        await withCheckedContinuation { continuation in
            center.add(request) { _ in
                continuation.resume()
            }
        }
        guard generation == accountGeneration else {
            center.removePendingNotificationRequests(withIdentifiers: [Self.dailyReminderIdentifier])
            return
        }
        await refreshStatus()
    }

    func removeDailyStudyReminder() async {
        clearAccountReminders()
        await refreshStatus()
    }

    func clearAccountReminders() {
        accountGeneration += 1
        center.removePendingNotificationRequests(withIdentifiers: [Self.dailyReminderIdentifier])
        center.removeDeliveredNotifications(withIdentifiers: [Self.dailyReminderIdentifier])
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
