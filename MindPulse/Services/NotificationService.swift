import Foundation
import UserNotifications

/// 本地推送通知服务
final class NotificationService {
    static let shared = NotificationService()

    private let notificationCenter = UNUserNotificationCenter.current()

    private init() {}

    // MARK: - Permission

    func requestPermission() async -> Bool {
        do {
            return try await notificationCenter.requestAuthorization(
                options: [.alert, .sound, .badge]
            )
        } catch {
            return false
        }
    }

    func isAuthorized() async -> Bool {
        let settings = await notificationCenter.notificationSettings()
        return settings.authorizationStatus == .authorized
    }

    // MARK: - Daily Review Reminder

    func scheduleDailyReminder(at hour: Int = 9, minute: Int = 0, cardCount: Int) {
        // 移除旧的提醒
        notificationCenter.removePendingNotificationRequests(
            withIdentifiers: ["daily_review"]
        )

        let content = UNMutableNotificationContent()
        content.title = "MindPulse"

        if cardCount > 0 {
            content.body = "今天有 \(cardCount) 张卡片等你复习，大约 2 分钟就能搞定"
        } else {
            content.body = "来看看有没有新内容可以学习吧"
        }
        content.sound = .default

        var dateComponents = DateComponents()
        dateComponents.hour = hour
        dateComponents.minute = minute

        let trigger = UNCalendarNotificationTrigger(
            dateMatching: dateComponents,
            repeats: true
        )

        let request = UNNotificationRequest(
            identifier: "daily_review",
            content: content,
            trigger: trigger
        )

        notificationCenter.add(request)
    }

    // MARK: - Gentle Nudge (for inactive users)

    func scheduleGentleNudge(afterDays days: Int = 3) {
        notificationCenter.removePendingNotificationRequests(
            withIdentifiers: ["gentle_nudge"]
        )

        let content = UNMutableNotificationContent()
        content.title = "MindPulse"
        content.body = "有一张精华卡片想和你聊聊，只需要 30 秒"
        content.sound = .default

        let trigger = UNTimeIntervalNotificationTrigger(
            timeInterval: TimeInterval(days * 86400),
            repeats: false
        )

        let request = UNNotificationRequest(
            identifier: "gentle_nudge",
            content: content,
            trigger: trigger
        )

        notificationCenter.add(request)
    }

    // MARK: - Cancel

    func cancelAll() {
        notificationCenter.removeAllPendingNotificationRequests()
    }

    func cancelReminder() {
        notificationCenter.removePendingNotificationRequests(
            withIdentifiers: ["daily_review"]
        )
    }
}
