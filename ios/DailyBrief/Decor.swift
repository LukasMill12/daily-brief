import CoreImage
import SwiftUI

/// Decorative blue elements behind the reading view's text. Concepts under evaluation;
/// a debug build picks one with the `-decor N` launch argument (1–7), release builds use `Decor.current`.
enum Decor: Int, CaseIterable {
    case none, grainGlow, giantDate, giantCurve, blueCover, weekdaySpine, issueGrain, liquidFigures

    static var current: Decor {
        #if DEBUG
        let args = ProcessInfo.processInfo.arguments
        if let i = args.firstIndex(of: "-decor"), i + 1 < args.count, let n = Int(args[i + 1]), let decor = Decor(rawValue: n) {
            return decor
        }
        #endif
        return .none
    }

    /// The liquid figures' colour, kept away from the blue accents. Debug builds choose with `-liquidColor N`.
    static var liquidColor: (core: Color, edge: Color) {
        var choice = 1
        #if DEBUG
        let args = ProcessInfo.processInfo.arguments
        if let i = args.firstIndex(of: "-liquidColor"), i + 1 < args.count, let n = Int(args[i + 1]) { choice = n }
        #endif
        switch choice {
        case 2: return (Color(red: 0.62, green: 0.36, blue: 1), Color(red: 0.42, green: 0.18, blue: 0.85))  // violet
        case 3: return (Color(red: 0.78, green: 0.79, blue: 0.82), Color(red: 0.5, green: 0.52, blue: 0.56))  // silver grey
        default: return (Color(red: 1, green: 0.45, blue: 0.16), Color(red: 0.85, green: 0.27, blue: 0.08))  // burnt orange
        }
    }

    /// Extra room the text needs so it doesn't collide with the decoration.
    var contentInsets: EdgeInsets {
        switch self {
        case .blueCover: EdgeInsets(top: 190, leading: 0, bottom: 0, trailing: 0)
        case .weekdaySpine: EdgeInsets(top: 0, leading: 34, bottom: 0, trailing: 0)
        case .issueGrain: EdgeInsets(top: 0, leading: 0, bottom: 130, trailing: 0)
        default: EdgeInsets()
        }
    }
}

/// Drawn behind the reading view's content, scrolling with it.
struct DecorView: View {
    var decor: Decor
    var brief: Brief

    var body: some View {
        switch decor {
        case .none:
            EmptyView()

        case .grainGlow:
            ZStack {
                RadialGradient(colors: [Theme.blue.opacity(0.85), Theme.blue.opacity(0.3), .clear],
                               center: UnitPoint(x: 0.95, y: 0.3), startRadius: 0, endRadius: 480)
                Grain(opacity: 0.22)
                    .mask(RadialGradient(colors: [.white, .clear], center: UnitPoint(x: 0.95, y: 0.3),
                                         startRadius: 0, endRadius: 520))
            }
            .frame(height: 880)
            .padding(.top, -160)
            .frame(maxHeight: .infinity, alignment: .top)

        case .giantDate:
            Text(brief.date.split(separator: "-").last.map(String.init) ?? "")
                .font(Theme.helvetica(330, medium: true))
                .tracking(-22)
                .foregroundStyle(Theme.blue.opacity(0.6))
                .fixedSize()
                .offset(x: 40, y: 10)
                .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .topTrailing)

        case .giantCurve:
            CurvedText(text: "VILNIUS " + Theme.coordinates, radius: 460, top: 170, size: 54, medium: true,
                       tracking: -1.5, color: Theme.blue.opacity(0.65))
                .frame(height: 760)
                .frame(maxHeight: .infinity, alignment: .top)

        case .blueCover:
            ZStack(alignment: .bottom) {
                Theme.blue
                Text(brief.weekday)
                    .font(Theme.helvetica(11))
                    .tracking(0.6)
                    .foregroundStyle(.white)
                    .padding(.bottom, 26)
            }
            .frame(height: 330)
            .padding(.top, -110)
            .frame(maxHeight: .infinity, alignment: .top)

        case .weekdaySpine:
            GeometryReader { _ in
                Text(brief.weekday.uppercased())
                    .font(Theme.helvetica(118, medium: true))
                    .tracking(-6)
                    .foregroundStyle(Theme.blue.opacity(0.55))
                    .fixedSize()
                    .rotationEffect(.degrees(-90))
                    .position(x: 36, y: 470)
            }

        case .issueGrain:
            ZStack(alignment: .bottomLeading) {
                LinearGradient(colors: [.clear, Theme.blue.opacity(0.9)], startPoint: .top, endPoint: .bottom)
                Grain(opacity: 0.25)
                    .mask(LinearGradient(colors: [.clear, .white], startPoint: .top, endPoint: .bottom))
                Text("№\(brief.dayOfYear)")
                    .font(Theme.helvetica(110, medium: true))
                    .tracking(-6)
                    .foregroundStyle(Theme.accent.opacity(0.7))
                    .padding(.leading, 14)
                    .padding(.bottom, 4)
            }
            .frame(height: 520)
            .frame(maxHeight: .infinity, alignment: .bottom)

        case .liquidFigures:
            EmptyView()  // shown in the footer instead, see FooterFigures
        }
    }
}

/// The figures as a small mark at the end of the footer, level with its lines.
struct FooterFigures: View {
    var body: some View {
        LiquidFigures().frame(width: 84, height: 56)
    }
}

/// Three small people holding hands, in grainy blue with a hand-drawn wobble.
private struct LiquidFigures: View {
    var body: some View {
        ZStack {
            Theme.blue
            Grain(opacity: 1, blend: .softLight)
            Grain(opacity: 0.15)
        }
        .mask(LiquidShape())
    }
}

/// Limbs drawn as chains of slightly uneven circles, then blurred and thresholded so joints and joined
/// hands melt together into one soft silhouette. Coordinates are on a 300×200 canvas.
private struct LiquidShape: View {
    /// A limb: points along its centre line with the thickness at each point.
    private struct Stroke { var points: [(CGFloat, CGFloat, CGFloat)] }

    private static let heads: [(CGFloat, CGFloat, CGFloat)] = [(64, 16, 12), (158, 10, 12), (258, 8, 12)]

    // Three people holding hands: one walking in from the left, one jumping, one running off to the right.
    private static let strokes: [Stroke] = [
        // walking
        Stroke(points: [(68, 52, 32), (62, 104, 26)]),
        Stroke(points: [(66, 60, 14), (46, 82, 12), (38, 100, 11)]),
        Stroke(points: [(72, 60, 14), (96, 72, 12), (118, 64, 11)]),
        Stroke(points: [(60, 104, 17), (44, 138, 14), (30, 166, 12)]),
        Stroke(points: [(66, 104, 17), (84, 136, 14), (88, 170, 12)]),
        // jumping
        Stroke(points: [(158, 44, 30), (160, 96, 24)]),
        Stroke(points: [(154, 54, 14), (134, 64, 12), (118, 64, 11)]),
        Stroke(points: [(164, 54, 14), (186, 46, 12), (204, 40, 11)]),
        Stroke(points: [(156, 96, 16), (138, 124, 14), (144, 156, 12)]),
        Stroke(points: [(164, 96, 16), (182, 122, 14), (188, 150, 12)]),
        // running
        Stroke(points: [(254, 42, 30), (242, 94, 24)]),
        Stroke(points: [(250, 52, 14), (226, 48, 12), (204, 40, 11)]),
        Stroke(points: [(258, 52, 14), (280, 66, 12), (294, 52, 11)]),
        Stroke(points: [(240, 94, 16), (222, 114, 14), (218, 140, 12)]),
        Stroke(points: [(246, 94, 16), (268, 120, 14), (262, 162, 12)]),
    ]

    private static let holes: [CGRect] = []
    /// Bodies are drawn this much lower than listed, leaving a clear gap between head and shoulders.
    private static let bodyDrop: CGFloat = 12

    var body: some View {
        Canvas { context, size in
            let k = size.width / 300
            context.addFilter(.alphaThreshold(min: 0.5, color: .white))
            context.addFilter(.blur(radius: 4 * k))
            context.drawLayer { layer in
                func dot(_ x: CGFloat, _ y: CGFloat, _ r: CGFloat) {
                    layer.fill(Path(ellipseIn: CGRect(x: (x - r) * k, y: (y - r) * k, width: 2 * r * k, height: 2 * r * k)),
                               with: .color(.white))
                }
                for (x, y, r) in Self.heads { dot(x, y, r) }
                for stroke in Self.strokes {
                    let points = stroke.points.map { ($0.0, $0.1 + Self.bodyDrop, $0.2) }
                    for (a, b) in zip(points, points.dropFirst()) {
                        let steps = max(Int(hypot(b.0 - a.0, b.1 - a.1) / 2), 1)
                        for i in 0...steps {
                            let t = CGFloat(i) / CGFloat(steps)
                            let x = a.0 + (b.0 - a.0) * t, y = a.1 + (b.1 - a.1) * t
                            // Uneven thickness, like a brush or a blob of ink, rather than a clean tube.
                            let wobble = 1 + 0.07 * sin(x * 0.37 + y * 0.23) + 0.03 * sin(x * 1.3 - y * 0.9)
                            dot(x, y, (a.2 + (b.2 - a.2) * t) / 2 * wobble)
                        }
                    }
                }
                layer.blendMode = .clear
                for hole in Self.holes {
                    layer.fill(Path(ellipseIn: CGRect(x: hole.minX * k, y: hole.minY * k,
                                                      width: hole.width * k, height: hole.height * k)), with: .color(.white))
                }
            }
        }
    }
}

/// Fine film grain: white noise rendered once and tiled.
private struct Grain: View {
    var opacity: Double
    /// `.screen` lifts dark areas; `.softLight` keeps a coloured shape saturated.
    var blend: BlendMode = .screen

    private static let tile: UIImage? = {
        guard let noise = CIFilter(name: "CIRandomGenerator")?.outputImage?
            .cropped(to: CGRect(x: 0, y: 0, width: 256, height: 256)) else { return nil }
        let white = noise.applyingFilter("CIColorMatrix", parameters: [
            "inputRVector": CIVector(x: 0, y: 0, z: 0, w: 0), "inputGVector": CIVector(x: 0, y: 0, z: 0, w: 0),
            "inputBVector": CIVector(x: 0, y: 0, z: 0, w: 0), "inputAVector": CIVector(x: 1, y: 0, z: 0, w: 0),
            "inputBiasVector": CIVector(x: 1, y: 1, z: 1, w: 0),
        ])
        guard let image = CIContext().createCGImage(white, from: white.extent) else { return nil }
        return UIImage(cgImage: image, scale: 2, orientation: .up)
    }()

    var body: some View {
        if let tile = Self.tile {
            Image(uiImage: tile).resizable(resizingMode: .tile).opacity(opacity).blendMode(blend)
        }
    }
}

extension Brief {
    /// "sekmadienis"
    var weekday: String {
        guard let day = DateFormatter.isoDay.date(from: date) else { return "" }
        let formatter = DateFormatter()
        formatter.locale = Locale(identifier: "lt_LT")
        formatter.dateFormat = "EEEE"
        return formatter.string(from: day)
    }

    var dayOfYear: Int {
        guard let day = DateFormatter.isoDay.date(from: date) else { return 0 }
        return Calendar(identifier: .gregorian).ordinality(of: .day, in: .year, for: day) ?? 0
    }
}

private extension DateFormatter {
    static let isoDay: DateFormatter = {
        let formatter = DateFormatter()
        formatter.dateFormat = "yyyy-MM-dd"
        formatter.timeZone = TimeZone(identifier: "Europe/Vilnius")
        return formatter
    }()
}
