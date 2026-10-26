import SwiftUI

/// The expanded (long-press) morning notification: the widget's curved headline on ultramarine,
/// then the day's top lines as a small uppercase index, and the figures as a signature.
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
                    Text(brief.date.split(separator: "-").reversed().joined(separator: "."))
                    Spacer()
                    Text(brief.weather.map { "\($0.min)…\($0.max)°" } ?? " ")
                }
                .font(Theme.helvetica(11 * s))
                .tracking(0.5 * s)
                .foregroundStyle(.white)
                .padding(.horizontal, 18 * s)
                .padding(.top, 18 * s)

                CurvedText(text: brief.shortHeadline, radius: 300 * s, top: 74 * s, size: 24 * s, medium: true,
                           tracking: -0.5 * s)
                CurvedText(text: "Vilnius · " + Theme.coordinates, radius: 285 * s, top: 108 * s, size: 12 * s,
                           tracking: 0.2 * s)

                VStack(alignment: .leading, spacing: 7 * s) {
                    ForEach(lines, id: \.self) { line in
                        Text(line.uppercased())
                            .lineLimit(2)
                    }
                }
                .font(Theme.helvetica(11 * s))
                .tracking(0.3 * s)
                .foregroundStyle(.white)
                .padding(.horizontal, 18 * s)
                .padding(.top, 164 * s)
                .padding(.trailing, 40 * s)

                HStack(alignment: .bottom) {
                    Text("+\(max(brief.storyCount - lines.count, 0)) MORE")
                        .font(Theme.helvetica(11 * s))
                        .tracking(0.4 * s)
                        .foregroundStyle(.white)
                    Spacer()
                    FiguresMark(color: .white).frame(width: 64 * s)
                }
                .padding(.horizontal, 18 * s)
                .padding(.bottom, 16 * s)
                .frame(maxHeight: .infinity, alignment: .bottom)
            }
        }
        .aspectRatio(Self.aspect, contentMode: .fit)
    }

    /// Width ÷ height of the expanded notification.
    static let aspect: CGFloat = 340 / 362

    /// The lead plus the next most important stories, one line each.
    private var lines: [String] {
        let lead = brief.lead
        let rest = (brief.lithuania + brief.world).filter { $0 != lead }
        return Array(([lead].compactMap { $0 } + rest).prefix(4).map(\.headline))
    }
}
