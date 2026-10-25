import CoreImage
import SwiftUI

/// Decorative blue elements behind the reading view's text. Concepts under evaluation;
/// a debug build picks one with the `-decor N` launch argument (1–6), release builds use `Decor.current`.
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
            LiquidFigures()
                .scaleEffect(0.78)
                .offset(x: 80, y: -70)
                .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .topTrailing)
        }
    }
}

/// Two liquid figures reaching for each other: blue with grain, dissolving into the dark at their edges.
private struct LiquidFigures: View {
    var body: some View {
        ZStack {
            RadialGradient(colors: [Color(red: 0.25, green: 0.38, blue: 1), Theme.blue],
                           center: .center, startRadius: 0, endRadius: 240)
            Grain(opacity: 0.3)
        }
        // Crisp silhouette, with the colour sinking back into the dark towards its edges.
        .mask(LiquidShape().blur(radius: 22))
        .mask(LiquidShape())
        .frame(width: 420, height: 420)
    }
}

/// Rounded limbs and heads drawn, blurred and thresholded so that touching parts melt together.
private struct LiquidShape: View {
    private struct Limb { var from: CGPoint; var to: CGPoint; var width: CGFloat }

    private static let heads: [(CGPoint, CGFloat)] = [
        (CGPoint(x: 90, y: 84), 20), (CGPoint(x: 205, y: 60), 19), (CGPoint(x: 320, y: 56), 20),
    ]
    private static let limbs: [Limb] = [
        // left figure, bent forward
        Limb(from: CGPoint(x: 105, y: 168), to: CGPoint(x: 150, y: 250), width: 78),
        Limb(from: CGPoint(x: 140, y: 250), to: CGPoint(x: 70, y: 345), width: 30),
        Limb(from: CGPoint(x: 160, y: 255), to: CGPoint(x: 175, y: 350), width: 26),
        Limb(from: CGPoint(x: 120, y: 170), to: CGPoint(x: 205, y: 128), width: 30),
        // middle figure, stretched between the two
        Limb(from: CGPoint(x: 207, y: 128), to: CGPoint(x: 230, y: 245), width: 46),
        Limb(from: CGPoint(x: 230, y: 245), to: CGPoint(x: 205, y: 330), width: 24),
        Limb(from: CGPoint(x: 230, y: 250), to: CGPoint(x: 290, y: 235), width: 26),
        // right figure, leaping away
        Limb(from: CGPoint(x: 315, y: 132), to: CGPoint(x: 290, y: 235), width: 58),
        Limb(from: CGPoint(x: 300, y: 130), to: CGPoint(x: 360, y: 108), width: 22),
        Limb(from: CGPoint(x: 360, y: 108), to: CGPoint(x: 385, y: 85), width: 20),
        Limb(from: CGPoint(x: 290, y: 235), to: CGPoint(x: 330, y: 300), width: 28),
        Limb(from: CGPoint(x: 330, y: 300), to: CGPoint(x: 320, y: 345), width: 22),
        Limb(from: CGPoint(x: 300, y: 135), to: CGPoint(x: 250, y: 150), width: 22),
    ]

    var body: some View {
        Canvas { context, _ in
            context.addFilter(.alphaThreshold(min: 0.5, color: .white))
            context.addFilter(.blur(radius: 9))
            context.drawLayer { layer in
                for (center, radius) in Self.heads {
                    layer.fill(Path(ellipseIn: CGRect(x: center.x - radius, y: center.y - radius,
                                                      width: radius * 2, height: radius * 2)), with: .color(.white))
                }
                for limb in Self.limbs {
                    var path = Path()
                    path.move(to: limb.from)
                    path.addLine(to: limb.to)
                    layer.stroke(path, with: .color(.white),
                                 style: StrokeStyle(lineWidth: limb.width, lineCap: .round))
                }
            }
        }
    }
}

/// Fine film grain: white noise rendered once and tiled.
private struct Grain: View {
    var opacity: Double

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
            Image(uiImage: tile).resizable(resizingMode: .tile).opacity(opacity).blendMode(.screen)
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
