import SwiftUI

/// Redent's colors.
///
/// Chrome text is tuned by hand rather than taken from `.primary`: the chrome
/// sits on a dark, heavily blurred slab in both appearances, so system label
/// colors come out either washed or harsh.
public enum Palette {
    public static var accent: Color { .accentColor }

    public static var chromeText: Color {
        Color(nsColor: NSColor(name: nil) { appearance in
            appearance.isDark ? NSColor(white: 1, alpha: 0.93) : NSColor(white: 0.08, alpha: 0.92)
        })
    }

    public static var chromeSecondaryText: Color {
        Color(nsColor: NSColor(name: nil) { appearance in
            appearance.isDark ? NSColor(white: 1, alpha: 0.52) : NSColor(white: 0.1, alpha: 0.52)
        })
    }

    /// The stroke that keeps a glass edge legible against a bright page.
    public static var hairline: Color {
        Color(nsColor: NSColor(name: nil) { appearance in
            appearance.isDark ? NSColor(white: 1, alpha: 0.13) : NSColor(white: 0, alpha: 0.10)
        })
    }

    /// Fill for a hovered or selected chrome control.
    public static var chromeFill: Color {
        Color(nsColor: NSColor(name: nil) { appearance in
            appearance.isDark ? NSColor(white: 1, alpha: 0.10) : NSColor(white: 0, alpha: 0.06)
        })
    }

    /// The page card's own surface: the toolbar row sits on it, and the corners
    /// the web view cannot reach are filled with it. Opaque, because the page
    /// below is opaque — a glass strip on top of it reads as a separate slab
    /// floating above the page rather than as the top of the same body.
    public static var pageChrome: Color {
        Color(nsColor: NSColor(name: nil) { appearance in
            appearance.isDark ? NSColor(white: 0.09, alpha: 1) : NSColor(white: 0.97, alpha: 1)
        })
    }

    /// Behind the page card — visible only at the rounded corners.
    public static var canvas: Color {
        Color(nsColor: NSColor(name: nil) { appearance in
            appearance.isDark ? NSColor(white: 0.07, alpha: 1) : NSColor(white: 0.93, alpha: 1)
        })
    }

    public static var danger: Color { Color(nsColor: .systemRed) }

    /// Fully opaque pill while a tab is being dragged, so glass does not
    /// bleed through the lifted row.
    public static var liftedChrome: Color {
        Color(nsColor: NSColor(name: nil) { appearance in
            appearance.isDark ? NSColor(white: 0.16, alpha: 1) : NSColor(white: 0.97, alpha: 1)
        })
    }

    /// Opaque base for menus and dropdowns, which must stay readable over
    /// whatever they happen to overhang.
    public static var dropdownBase: Color {
        Color(nsColor: NSColor(name: nil) { appearance in
            appearance.isDark ? NSColor(white: 0.13, alpha: 0.97) : NSColor(white: 0.99, alpha: 0.97)
        })
    }

    /// The default ambient hue, used until a page reports a theme color.
    public static var defaultAmbient: Color { Color(red: 0.36, green: 0.34, blue: 0.92) }

    /// A private window keeps this hue whatever it is showing, so it can never
    /// be mistaken for an ordinary one.
    public static var privateAmbient: Color { Color(red: 0.30, green: 0.24, blue: 0.40) }
}

extension NSAppearance {
    var isDark: Bool {
        bestMatch(from: [.aqua, .darkAqua]) == .darkAqua
    }
}
