import SwiftUI

/// App icon concepts built on the three figures: ultramarine with the figures in white.
/// Drawn on a 1024pt canvas and scaled, so the same view can preview the icon and export it.
enum IconConcept: Int, CaseIterable {
    case small = 1, medium, withName, onArc, bleed, inverted

    var label: String {
        switch self {
        case .small: "1 — Small"
        case .medium: "2 — Medium"
        case .withName: "3 — With name"
        case .onArc: "4 — Under an arc"
        case .bleed: "5 — Large, cropped"
        case .inverted: "6 — Inverted"
        }
    }
}

struct IconFace: View {
    var concept: IconConcept

    var body: some View {
        GeometryReader { proxy in
            let s = proxy.size.width / 1024
            ZStack {
                (concept == .inverted ? Color.white : Theme.blue)
                switch concept {
                case .small:
                    FiguresMark(color: .white).frame(width: 360 * s)
                case .medium:
                    FiguresMark(color: .white).frame(width: 560 * s)
                case .withName:
                    VStack(spacing: 70 * s) {
                        FiguresMark(color: .white).frame(width: 420 * s)
                        Text("THE BRIEF")
                            .font(Theme.helvetica(64 * s, medium: true))
                            .tracking(6 * s)
                            .foregroundStyle(.white)
                    }
                    .offset(y: 20 * s)
                case .onArc:
                    CurvedText(text: "VILNIUS · 54°41′N 25°17′E", radius: 470 * s, top: 250 * s, size: 50 * s,
                               tracking: 2 * s)
                    FiguresMark(color: .white).frame(width: 420 * s).offset(y: 60 * s)
                case .bleed:
                    FiguresMark(color: .white).frame(width: 1250 * s).offset(x: 40 * s, y: 160 * s)
                case .inverted:
                    FiguresMark(color: Theme.blue).frame(width: 420 * s)
                }
            }
            .clipped()
        }
        .aspectRatio(1, contentMode: .fit)
    }
}

#if DEBUG
/// The icon concepts at large and home-screen size, with iOS's rounded mask. Launch with `-iconPreview`.
struct IconPreview: View {
    var body: some View {
        VStack(spacing: 34) {
            LazyVGrid(columns: Array(repeating: GridItem(.fixed(112)), count: 3), spacing: 24) {
                ForEach(IconConcept.allCases, id: \.self) { concept in
                    VStack(spacing: 8) {
                        IconFace(concept: concept)
                            .frame(width: 112, height: 112)
                            .clipShape(RoundedRectangle(cornerRadius: 25, style: .continuous))
                        Text(concept.label).font(.caption).foregroundStyle(.black)
                    }
                }
            }
            VStack(spacing: 8) {
                HStack(spacing: 12) {
                    ForEach(IconConcept.allCases, id: \.self) { concept in
                        IconFace(concept: concept)
                            .frame(width: 52, height: 52)
                            .clipShape(RoundedRectangle(cornerRadius: 12, style: .continuous))
                    }
                }
                Text("Actual home-screen size").font(.caption).foregroundStyle(.black)
            }
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .background(Color(white: 0.85))
    }
}
#endif
