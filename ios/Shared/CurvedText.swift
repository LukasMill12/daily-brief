import SwiftUI

/// Text set along the top of a circle, centred horizontally, like type around a badge.
/// `radius` is the circle's radius and `top` the y position of the arc's highest point, both in points.
struct CurvedText: View {
    var text: String
    var radius: CGFloat
    var top: CGFloat
    var size: CGFloat
    var medium = false
    var tracking: CGFloat = 0
    var color: Color = .white

    var body: some View {
        GeometryReader { proxy in
            let font = Theme.uiHelvetica(size, medium: medium)
            let glyphs = text.map { String($0) }
            let widths = glyphs.map { ($0 as NSString).size(withAttributes: [.font: font]).width + tracking }
            let total = widths.reduce(0, +)
            let center = CGPoint(x: proxy.size.width / 2, y: top + radius)

            ZStack {
                ForEach(Array(glyphs.enumerated()), id: \.offset) { index, glyph in
                    let before = widths[..<index].reduce(0, +)
                    let angle = (before + widths[index] / 2 - total / 2) / radius
                    Text(glyph)
                        .font(Theme.helvetica(size, medium: medium))
                        .foregroundStyle(color)
                        .fixedSize()
                        .rotationEffect(.radians(angle))
                        .position(x: center.x + radius * sin(angle), y: center.y - radius * cos(angle))
                }
            }
        }
    }
}
