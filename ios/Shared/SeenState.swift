import Foundation
import WidgetKit

/// Remembers which day's brief has been opened, shared between the app and the widget through the App Group,
/// so the widget can show its "new brief" face until the reader opens the app.
enum SeenState {
    private static let defaults = UserDefaults(suiteName: "group.lt.lukas.dailybrief") ?? .standard
    private static let key = "seenBriefDate"

    static func isNew(_ brief: Brief) -> Bool {
        defaults.string(forKey: key) != brief.date
    }

    static func markSeen(_ brief: Brief) {
        guard isNew(brief) else { return }
        defaults.set(brief.date, forKey: key)
        WidgetCenter.shared.reloadAllTimelines()
    }
}
