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
        case "red": Color(red: 0.94, green: 0.30, blue: 0.30)
        case "orange": Color(red: 0.99, green: 0.52, blue: 0.16)
        case "yellow": Color(red: 0.96, green: 0.82, blue: 0.22)
        case "green": Color(red: 0.30, green: 0.78, blue: 0.40)
        case "mint": Color(red: 0.46, green: 0.88, blue: 0.68)
        case "cyan": Color(red: 0.24, green: 0.82, blue: 0.94)
        case "purple": Color(red: 0.76, green: 0.34, blue: 0.88)
        case "pink": Color(red: 0.98, green: 0.58, blue: 0.80)
        case "magenta": Color(red: 0.90, green: 0.24, blue: 0.68)
        case "brown": Color(red: 0.64, green: 0.46, blue: 0.34)
        case "slate": Color(red: 0.50, green: 0.56, blue: 0.66)
        default: Palette.defaultAmbient
        }
    }
}
