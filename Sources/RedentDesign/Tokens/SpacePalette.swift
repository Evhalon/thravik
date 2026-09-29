import SwiftUI

/// Saturated Space hues. Tuned to sit on glass, not on opaque chrome.
public enum SpacePalette {
    public static func color(_ token: String) -> Color {
        switch token {
        case "amber": Color(red: 0.98, green: 0.62, blue: 0.22)
        case "rose": Color(red: 0.96, green: 0.42, blue: 0.55)
        case "indigo": Color(red: 0.48, green: 0.44, blue: 0.96)
        case "teal": Color(red: 0.22, green: 0.78, blue: 0.72)
        case "violet": Color(red: 0.64, green: 0.40, blue: 0.96)
        case "lime": Color(red: 0.52, green: 0.82, blue: 0.34)
        case "coral": Color(red: 0.98, green: 0.46, blue: 0.36)
        case "sky": Color(red: 0.34, green: 0.68, blue: 0.98)
        case "blue": Color(red: 0.36, green: 0.52, blue: 0.98)
        default: Palette.defaultAmbient
        }
    }
}
