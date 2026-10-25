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
        VStack(spacing: 40) {
            WidgetFace(brief: brief, isNew: true)
                .frame(width: 170, height: 170)
                .background(Theme.blue, in: RoundedRectangle(cornerRadius: 26, style: .continuous))
            WidgetFace(brief: brief)
                .frame(width: 170, height: 170)
                .background(Theme.blue, in: RoundedRectangle(cornerRadius: 26, style: .continuous))
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .background(Color(white: 0.85))
        .task {
            if let fresh = await BriefLoader.load() { brief = fresh }
            if let weather = await WeatherLoader.load() { brief.weather = weather }
        }
    }
}
#endif
