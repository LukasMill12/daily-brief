import SwiftUI

/// The 2×2 widget's design, without the widget plumbing so the app can preview it too.
/// Laid out on a 190pt design canvas, then scaled to the real widget size.
struct WidgetFace: View {
    var brief: Brief

    var body: some View {
        GeometryReader { proxy in
            let s = proxy.size.width / 190
            let temperature = brief.weather.map { " · \($0.min)…\($0.max)°" } ?? ""

            ZStack {
                CurvedText(text: brief.shortHeadline, radius: 175 * s, top: 74 * s, size: 15 * s, medium: true,
                           tracking: -0.3 * s)
                CurvedText(text: Theme.coordinates + temperature, radius: 163 * s, top: 96 * s, size: 11.5 * s,
                           tracking: 0.1 * s)
                VStack {
                    Spacer()
                    HStack {
                        Text(brief.dayMonth)
                        Spacer()
                        Text("+\(max(brief.storyCount - 1, 0))")
                    }
                    .font(Theme.helvetica(11 * s))
                    .tracking(0.4 * s)
                    .foregroundStyle(.white)
                    .padding(.horizontal, 18 * s)
                    .padding(.bottom, 14 * s)
                }
            }
        }
    }
}
