import SwiftUI

enum Theme {
    static let blue = Color(red: 0x16 / 255, green: 0x31 / 255, blue: 0xD8 / 255)
    /// Blue accent readable on the dark background.
    static let accent = Color(red: 0x5C / 255, green: 0x74 / 255, blue: 0xFF / 255)
    static let background = Color(red: 0x14 / 255, green: 0x14 / 255, blue: 0x14 / 255)
    static let text = Color(red: 0xF2 / 255, green: 0xF2 / 255, blue: 0xF2 / 255)
    static let muted = Color(red: 0x8C / 255, green: 0x8C / 255, blue: 0x8C / 255)

    static let coordinates = "54°41′N 25°17′E"

    static func helvetica(_ size: CGFloat, medium: Bool = false) -> Font {
        .custom(medium ? "HelveticaNeue-Medium" : "HelveticaNeue", fixedSize: size)
    }

    static func uiHelvetica(_ size: CGFloat, medium: Bool = false) -> UIFont {
        UIFont(name: medium ? "HelveticaNeue-Medium" : "HelveticaNeue", size: size) ?? .systemFont(ofSize: size)
    }
}
