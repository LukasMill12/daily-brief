import SwiftUI

@main
struct DailyBriefApp: App {
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
            WidgetFace(brief: brief)
                .frame(width: 170, height: 170)
                .background(Theme.blue, in: RoundedRectangle(cornerRadius: 26, style: .continuous))
            WidgetFace(brief: .sample)
                .frame(width: 170, height: 170)
                .background(Theme.blue, in: RoundedRectangle(cornerRadius: 26, style: .continuous))
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .background(Color(white: 0.85))
        .task { if let fresh = await BriefLoader.load() { brief = fresh } }
    }
}
#endif
