import RedentDesign
import RedentKit
import SwiftUI

/// Turns any Space color token — named, picked, or dialed in vividness —
/// into the color the chrome paints with.
enum SpaceTintColor {
    static func color(_ token: String) -> Color {
        let tint = SpaceTint(token: token)
        if case .named(let name) = tint.base, tint.vividness == SpaceTint.neutralVividness {
            return SpacePalette.color(name)
        }
        return color(baseRGB(tint.base).vivified(tint.vividness))
    }

    static func color(_ rgb: SpaceRGB) -> Color {
        Color(red: rgb.red, green: rgb.green, blue: rgb.blue)
    }

    static func baseRGB(_ base: SpaceTint.Base) -> SpaceRGB {
        switch base {
        case .custom(let rgb): rgb
        case .named(let name): rgb(of: SpacePalette.color(name))
        }
    }

    static func rgb(of color: Color) -> SpaceRGB {
        let resolved = color.resolve(in: EnvironmentValues())
        return SpaceRGB(red: Double(resolved.red), green: Double(resolved.green), blue: Double(resolved.blue))
    }
}
