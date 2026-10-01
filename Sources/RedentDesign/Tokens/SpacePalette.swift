import SwiftUI

/// Saturated Space hues. Tuned to sit on glass, not on opaque chrome.
public enum SpacePalette {
    public static func color(_ token: String) -> Color {
        switch token {
        case "amber": Color(red: 1.00, green: 0.60, blue: 0.10)
        case "rose": Color(red: 0.98, green: 0.30, blue: 0.48)
        case "indigo": Color(red: 0.40, green: 0.34, blue: 1.00)
        case "teal": Color(red: 0.06, green: 0.74, blue: 0.68)
        case "violet": Color(red: 0.60, green: 0.30, blue: 1.00)
        case "lime": Color(red: 0.46, green: 0.84, blue: 0.16)
        case "coral": Color(red: 1.00, green: 0.40, blue: 0.28)
        case "sky": Color(red: 0.20, green: 0.64, blue: 1.00)
        case "blue": Color(red: 0.24, green: 0.44, blue: 1.00)
        case "red": Color(red: 0.96, green: 0.20, blue: 0.22)
        case "orange": Color(red: 1.00, green: 0.48, blue: 0.04)
        case "yellow": Color(red: 1.00, green: 0.80, blue: 0.04)
        case "green": Color(red: 0.16, green: 0.78, blue: 0.32)
        case "mint": Color(red: 0.24, green: 0.88, blue: 0.62)
        case "cyan": Color(red: 0.06, green: 0.80, blue: 0.96)
        case "purple": Color(red: 0.74, green: 0.22, blue: 0.92)
        case "pink": Color(red: 1.00, green: 0.44, blue: 0.74)
        case "magenta": Color(red: 0.92, green: 0.12, blue: 0.64)
        case "brown": Color(red: 0.68, green: 0.42, blue: 0.24)
        case "slate": Color(red: 0.40, green: 0.50, blue: 0.68)
        default: Palette.defaultAmbient
        }
    }
}
