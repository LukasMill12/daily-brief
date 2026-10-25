import SwiftUI
import WidgetKit

struct BriefEntry: TimelineEntry {
    var date: Date
    var brief: Brief?
}

struct BriefProvider: TimelineProvider {
    func placeholder(in context: Context) -> BriefEntry {
        BriefEntry(date: .now, brief: .sample)
    }

    func getSnapshot(in context: Context, completion: @escaping (BriefEntry) -> Void) {
        completion(BriefEntry(date: .now, brief: BriefLoader.cached() ?? .sample))
    }

    func getTimeline(in context: Context, completion: @escaping (Timeline<BriefEntry>) -> Void) {
        Task {
            let brief = await BriefLoader.load()
            completion(Timeline(entries: [BriefEntry(date: .now, brief: brief)], policy: .after(nextRefresh(for: brief))))
        }
    }

    /// Today's brief lands around 09:00 Vilnius time: check again shortly after, or soon if it's still yesterday's.
    private func nextRefresh(for brief: Brief?) -> Date {
        let calendar = Calendar.current
        let today = DateFormatter.briefDate.string(from: .now)
        if brief?.date != today, calendar.component(.hour, from: .now) >= 9 {
            return .now.addingTimeInterval(30 * 60)
        }
        let nineTen = calendar.date(bySettingHour: 9, minute: 10, second: 0, of: .now)!
        return nineTen > .now ? nineTen : calendar.date(byAdding: .day, value: 1, to: nineTen)!
    }
}

struct BriefWidgetView: View {
    var entry: BriefEntry

    var body: some View {
        let brief = entry.brief ?? .sample
        WidgetFace(brief: brief, isNew: entry.brief != nil && SeenState.isNew(brief))
            .containerBackground(Theme.blue, for: .widget)
    }
}

@main
struct BriefWidget: Widget {
    var body: some WidgetConfiguration {
        StaticConfiguration(kind: "BriefWidget", provider: BriefProvider()) { entry in
            BriefWidgetView(entry: entry)
        }
        .configurationDisplayName("The Brief")
        .description("Today's lead story.")
        .supportedFamilies([.systemSmall])
        .contentMarginsDisabled()
    }
}

extension DateFormatter {
    static let briefDate: DateFormatter = {
        let formatter = DateFormatter()
        formatter.dateFormat = "yyyy-MM-dd"
        formatter.timeZone = TimeZone(identifier: "Europe/Vilnius")
        return formatter
    }()
}

#Preview(as: .systemSmall) {
    BriefWidget()
} timeline: {
    BriefEntry(date: .now, brief: .sample)
}
