import SwiftUI

/// The three liquid figures (traced from Lukas's reference image, `figures.png`) as a single-colour mark,
/// used in the reading view's footer and on the widget.
struct FiguresMark: View {
    var color: Color

    private static let shape = UIImage(named: "figures")
    /// Width ÷ height of the traced figures.
    static let aspect: CGFloat = 678 / 390

    var body: some View {
        color.mask {
            if let shape = Self.shape {
                Image(uiImage: shape).resizable().scaledToFit()
            }
        }
        .aspectRatio(Self.aspect, contentMode: .fit)
    }
}
