import CoreImage
import SwiftUI

/// Decorative blue elements in the reading view. The footer figures are the chosen look; the other concepts
/// stay available in debug builds with the `-decor N` launch argument (0 = none, 1–7).
enum Decor: Int, CaseIterable {
    case none, grainGlow, giantDate, giantCurve, blueCover, weekdaySpine, issueGrain, liquidFigures

    static var current: Decor {
        #if DEBUG
        let args = ProcessInfo.processInfo.arguments
        if let i = args.firstIndex(of: "-decor"), i + 1 < args.count, let n = Int(args[i + 1]), let decor = Decor(rawValue: n) {
            return decor
        }
        #endif
        return .liquidFigures
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
        LiquidFigures().frame(width: 84, height: 48)
    }
}

/// Three liquid figures (traced from Lukas's reference image, `figures.png`) in solid blue.
private struct LiquidFigures: View {
    private static let shape = UIImage(named: "figures")

    var body: some View {
        Theme.blue.mask {
            if let shape = Self.shape {
                Image(uiImage: shape).resizable().scaledToFit()
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
