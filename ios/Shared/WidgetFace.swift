import SwiftUI

/// The 2×2 widget's design, without the widget plumbing so the app can preview it too.
/// Laid out on a 190pt design canvas, then scaled to the real widget size.
struct WidgetFace: View {
    var brief: Brief
    var isNew = false

    var body: some View {
        if isNew { newFace } else { baseFace }
    }

    /// Shown from the moment a new brief lands until it's opened.
    private var newFace: some View {
        GeometryReader { proxy in
            let s = proxy.size.width / 190
            ZStack {
                CurvedText(text: "Today's brief is ready", radius: 175 * s, top: 74 * s, size: 15 * s, medium: true,
                           tracking: -0.3 * s)
                CurvedText(text: "\(brief.dayMonth) · \(Theme.coordinates)", radius: 163 * s, top: 96 * s,
                           size: 11.5 * s, tracking: 0.1 * s)
                Text("1")
                    .font(Theme.helvetica(13 * s, medium: true))
                    .foregroundStyle(Theme.blue)
                    .frame(width: 22 * s, height: 22 * s)
                    .background(.white, in: Circle())
                    .position(x: 160 * s, y: 30 * s)
                VStack {
                    Spacer()
                    HStack {
                        Text("THE BRIEF")
                        Spacer()
                        Text("\(brief.storyCount) STORIES")
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

    private var baseFace: some View {
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
