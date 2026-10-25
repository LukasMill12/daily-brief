import UserNotifications

/// A local notification every morning shortly after the routine publishes the brief (around 09:00).
enum DailyNotification {
    static let hour = 9
    static let minute = 15
    private static let id = "daily-brief"

    static func schedule() async {
        let center = UNUserNotificationCenter.current()
        guard (try? await center.requestAuthorization(options: [.alert, .sound])) == true else { return }

        let content = UNMutableNotificationContent()
        content.title = "The Brief"
        content.body = "Your brief is ready"
        content.sound = .default

        var time = DateComponents()
        time.hour = hour
        time.minute = minute
        let trigger = UNCalendarNotificationTrigger(dateMatching: time, repeats: true)
        center.removePendingNotificationRequests(withIdentifiers: [id])
        try? await center.add(UNNotificationRequest(identifier: id, content: content, trigger: trigger))
    }
}
