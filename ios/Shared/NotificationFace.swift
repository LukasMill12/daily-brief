import SwiftUI

/// The expanded (long-press) morning notification: the widget's curved headline on ultramarine with plenty
/// of room around it, the next two stories at the foot, and the figures as a signature.
struct NotificationFace: View {
    var brief: Brief

    var body: some View {
        GeometryReader { proxy in
            let s = proxy.size.width / 340
            ZStack(alignment: .topLeading) {
                Theme.blue

                HStack {
                    Text("THE BRIEF")
                    Spacer()
                    Text(brief.weather.map { "\($0.min)…\($0.max)°" } ?? brief.dayMonth)
                }
                .font(Theme.helvetica(11 * s))
                .tracking(0.5 * s)
                .foregroundStyle(.white)
                .padding(.horizontal, 24 * s)
                .padding(.top, 24 * s)

                CurvedText(text: brief.shortHeadline, radius: 300 * s, top: 132 * s, size: 24 * s, medium: true,
                           tracking: -0.5 * s)
                CurvedText(text: "Vilnius · " + Theme.coordinates, radius: 285 * s, top: 166 * s, size: 12 * s,
                           tracking: 0.2 * s)

                HStack(alignment: .bottom, spacing: 20 * s) {
                    VStack(alignment: .leading, spacing: 8 * s) {
                        ForEach(lines, id: \.self) { line in
                            Text(line.uppercased()).fixedSize(horizontal: false, vertical: true)
                        }
                    }
                    .font(Theme.helvetica(10 * s))
                    .tracking(0.3 * s)
                    .foregroundStyle(.white)
                    Spacer(minLength: 0)
                    FiguresMark(color: .white).frame(width: 52 * s)
                }
                .padding(.horizontal, 24 * s)
                .padding(.bottom, 24 * s)
                .frame(maxHeight: .infinity, alignment: .bottom)
            }
        }
        .aspectRatio(Self.aspect, contentMode: .fit)
    }

    /// Width ÷ height of the expanded notification.
    static let aspect: CGFloat = 340 / 380

    /// The two most important stories after the lead, which the curved headline already shows.
    private var lines: [String] {
        let lead = brief.lead
        return Array((brief.lithuania + brief.world).filter { $0 != lead }.prefix(2).map(\.headline))
    }
}
