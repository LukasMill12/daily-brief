import Foundation

/// A tiny breadcrumb log in the App Group container, for diagnosing the notification extension on a real
/// phone, where the system log isn't readable. Copy it off with
/// `xcrun devicectl device copy from --domain-type appGroupDataContainer --domain-identifier group.lt.lukas.dailybrief`.
enum DebugLog {
    private static let url = FileManager.default
        .containerURL(forSecurityApplicationGroupIdentifier: "group.lt.lukas.dailybrief")?
        .appendingPathComponent("debug.log")

    static func write(_ message: String) {
        guard let url else { return }
        let line = "\(ISO8601DateFormatter().string(from: .now)) \(message)\n"
        if let handle = try? FileHandle(forWritingTo: url) {
            handle.seekToEndOfFile()
            handle.write(Data(line.utf8))
            try? handle.close()
        } else {
            try? Data(line.utf8).write(to: url)
        }
    }
}
