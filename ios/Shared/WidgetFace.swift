import SwiftUI

/// The 2×2 widget's design, without the widget plumbing so the app can preview it too.
/// Laid out on a 190pt design canvas, then scaled to the real widget size.
struct WidgetFace: View {
    var brief: Brief
    var isNew = false
    var figures: WidgetFigures = .none

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
            ZStack {
                CurvedText(text: brief.shortHeadline, radius: 175 * s, top: 74 * s, size: 15 * s, medium: true,
                           tracking: -0.3 * s)
                CurvedText(text: "Vilnius · " + Theme.coordinates, radius: 163 * s, top: 96 * s, size: 11.5 * s,
                           tracking: 0.1 * s)
                let temperature = brief.weather.map { "\($0.min)…\($0.max)°" } ?? "+\(max(brief.storyCount - 1, 0))"
                // The large figures take the bottom, so the date and temperature move to the top corners.
                VStack {
                    if figures == .large { Spacer().frame(height: 14 * s) } else { Spacer() }
                    HStack {
                        if figures == .replaceDate { Spacer().frame(width: 1) } else { Text(brief.dayMonth) }
                        Spacer()
                        Text(temperature)
                    }
                    .font(Theme.helvetica(11 * s))
                    .tracking(0.4 * s)
                    .foregroundStyle(.white)
                    .padding(.horizontal, 18 * s)
                    .padding(.bottom, 14 * s)
                    if figures == .large { Spacer() }
                }
                if let placement = figures.placement {
                    FiguresMark(color: .white)
                        .frame(width: placement.width * s)
                        .position(x: placement.x * s, y: placement.y * s)
                }
            }
        }
    }
}

/// Where the white figures sit on the widget, if anywhere. Positions are on the 190pt canvas.
enum WidgetFigures: Int, CaseIterable {
    case none, topLeft, topCenter, bottomCenter, replaceDate, large

    var placement: (x: CGFloat, y: CGFloat, width: CGFloat)? {
        switch self {
        case .none: nil
        case .topLeft: (40, 30, 44)
        case .topCenter: (95, 36, 56)
        case .bottomCenter: (95, 166, 46)
        case .replaceDate: (40, 166, 44)
        case .large: (95, 150, 118)
        }
    }

    var label: String {
        switch self {
        case .none: "Now"
        case .topLeft: "1 — Top left"
        case .topCenter: "2 — Top centre"
        case .bottomCenter: "3 — Bottom centre"
        case .replaceDate: "4 — Instead of date"
        case .large: "5 — Large"
        }
    }
}
