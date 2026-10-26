import UserNotifications

/// A local notification every morning shortly after the routine publishes the brief (around 09:00).
enum DailyNotification {
    static let hour = 9
    static let minute = 15
    private static let id = "daily-brief"
    /// Matches UNNotificationExtensionCategory in BriefNotification/Info.plist, which draws the long-press view.
    static let category = "daily-brief"

    #if DEBUG
    /// Sends the morning notification in 5 seconds, to try the long-press view without waiting until 09:15.
    static func sendTest() {
        let content = UNMutableNotificationContent()
        content.title = "The Brief"
        content.body = "Your brief is ready"
        content.sound = .default
        content.categoryIdentifier = category
        let trigger = UNTimeIntervalNotificationTrigger(timeInterval: 5, repeats: false)
        UNUserNotificationCenter.current().add(UNNotificationRequest(identifier: "test", content: content, trigger: trigger))
    }
    #endif

    static func schedule() async {
        let center = UNUserNotificationCenter.current()
        guard (try? await center.requestAuthorization(options: [.alert, .sound])) == true else { return }

        center.setNotificationCategories([UNNotificationCategory(identifier: category, actions: [], intentIdentifiers: [])])

        let content = UNMutableNotificationContent()
        content.title = "The Brief"
        content.body = "Your brief is ready"
        content.sound = .default
        content.categoryIdentifier = category

        var time = DateComponents()
        time.hour = hour
        time.minute = minute
        let trigger = UNCalendarNotificationTrigger(dateMatching: time, repeats: true)
        center.removePendingNotificationRequests(withIdentifiers: [id])
        try? await center.add(UNNotificationRequest(identifier: id, content: content, trigger: trigger))
    }
}
