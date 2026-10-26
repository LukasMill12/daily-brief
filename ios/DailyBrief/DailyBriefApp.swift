import SwiftUI

@main
struct DailyBriefApp: App {
    init() {
        // Room for a day's photos, so preloaded images are still there when a story opens.
        URLCache.shared = URLCache(memoryCapacity: 50_000_000, diskCapacity: 300_000_000)
    }

    var body: some Scene {
        WindowGroup {
            #if DEBUG
            if ProcessInfo.processInfo.arguments.contains("-widgetPreview") {
                WidgetPreview()
            } else if ProcessInfo.processInfo.arguments.contains("-iconPreview") {
                IconPreview()
            } else if ProcessInfo.processInfo.arguments.contains("-notificationPreview") {
                NotificationPreview()
            } else {
                main
            }
            #else
            main
            #endif
        }
    }

    private var main: some View {
        BriefView()
            .preferredColorScheme(.dark)
            .task { await DailyNotification.schedule() }
    }
}

#if DEBUG
/// The widget at its real 2×2 size, for checking the design without the home screen widget gallery.
/// Launch with the `-widgetPreview` argument.
private struct WidgetPreview: View {
    @State private var brief = BriefLoader.cached() ?? .sample

    var body: some View {
        LazyVGrid(columns: [GridItem(.fixed(160)), GridItem(.fixed(160))], spacing: 22) {
            ForEach(WidgetFigures.allCases, id: \.self) { figures in
                VStack(spacing: 6) {
                    WidgetFace(brief: brief, figures: figures)
                        .frame(width: 160, height: 160)
                        .background(Theme.blue, in: RoundedRectangle(cornerRadius: 24, style: .continuous))
                    Text(figures.label).font(.caption).foregroundStyle(.black)
                }
            }
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .background(Color(white: 0.85))
        .task {
            if let fresh = await BriefLoader.load() { brief = fresh }
            if let weather = await WeatherLoader.load() { brief.weather = weather }
        }
    }
}

/// The long-press notification design at phone width. Launch with `-notificationPreview`.
private struct NotificationPreview: View {
    @State private var brief = BriefLoader.cached() ?? .sample

    var body: some View {
        NotificationFace(brief: brief)
            .clipShape(RoundedRectangle(cornerRadius: 22, style: .continuous))
            .padding(.horizontal, 10)
            .frame(maxWidth: .infinity, maxHeight: .infinity)
            .background(Color(white: 0.25))
            .task {
                if let fresh = await BriefLoader.load() { brief = fresh }
                if let weather = await WeatherLoader.load() { brief.weather = weather }
            }
    }
}
#endif
