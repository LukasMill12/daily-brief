import SwiftUI

/// Text set along the top of a circle, centred horizontally, like type around a badge.
/// `radius` is the circle's radius and `top` the y position of the arc's highest point, both in points.
/// `emphasis` is appended in the medium weight, e.g. a temperature at the end of a line.
struct CurvedText: View {
    var text: String
    var emphasis = ""
    var radius: CGFloat
    var top: CGFloat
    var size: CGFloat
    var medium = false
    var tracking: CGFloat = 0
    var color: Color = .white

    var body: some View {
        GeometryReader { proxy in
            let glyphs = text.map { (String($0), medium) } + emphasis.map { (String($0), true) }
            let widths = glyphs.map { glyph, isMedium in
                (glyph as NSString).size(withAttributes: [.font: Theme.uiHelvetica(size, medium: isMedium)]).width + tracking
            }
            let total = widths.reduce(0, +)
            let center = CGPoint(x: proxy.size.width / 2, y: top + radius)

            ZStack {
                ForEach(Array(glyphs.enumerated()), id: \.offset) { index, glyph in
                    let before = widths[..<index].reduce(0, +)
                    let angle = (before + widths[index] / 2 - total / 2) / radius
                    Text(glyph.0)
                        .font(Theme.helvetica(size, medium: glyph.1))
                        .foregroundStyle(color)
                        .fixedSize()
                        .rotationEffect(.radians(angle))
                        .position(x: center.x + radius * sin(angle), y: center.y - radius * cos(angle))
                }
            }
        }
    }
}
