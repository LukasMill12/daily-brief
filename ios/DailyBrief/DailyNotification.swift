import UserNotifications

/// A local notification every morning shortly after the routine publishes the brief (around 09:00).
enum DailyNotification {
    static let hour = 9
    static let minute = 15
    private static let id = "daily-brief"

    #if DEBUG
    /// Sends the morning notification in 10 seconds, to try it without waiting until 09:15.
    /// Also triggered by launching with `-sendTestNotification` (e.g. from the Mac with devicectl).
    static func sendTest() {
        let content = UNMutableNotificationContent()
        content.title = "The Brief"
        content.body = "Your brief is ready"
        content.sound = .default
        let trigger = UNTimeIntervalNotificationTrigger(timeInterval: 10, repeats: false)
        UNUserNotificationCenter.current().add(UNNotificationRequest(identifier: "test", content: content, trigger: trigger))
    }
    #endif

    static func schedule() async {
        let center = UNUserNotificationCenter.current()
        guard (try? await center.requestAuthorization(options: [.alert, .sound])) == true else { return }

        center.setNotificationCategories([])

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
