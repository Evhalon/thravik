import RedentDesign
import SwiftUI

/// The new tab's own light. The chrome's ambient color is derived from the
/// current page, and a new tab has none — so this page brings its own, which
/// also makes opening one feel like arriving somewhere rather than at a void.
struct NewTabBackdrop: View {
    @Environment(\.colorScheme) private var scheme

    var body: some View {
        ZStack {
            Palette.canvas
            RadialGradient(
                colors: [Palette.accent.opacity(scheme == .dark ? 0.32 : 0.20), .clear],
                center: UnitPoint(x: 0.5, y: 0.12),
                startRadius: 10,
                endRadius: 520
            )
            RadialGradient(
                colors: [Palette.defaultAmbient.opacity(scheme == .dark ? 0.22 : 0.12), .clear],
                center: UnitPoint(x: 0.12, y: 0.9),
                startRadius: 10,
                endRadius: 460
            )
            NoiseOverlay(opacity: 0.04)
        }
        .ignoresSafeArea()
    }
}

/// A greeting that tracks the clock, because a browser opened at 2am and one
/// opened at 9am are not the same moment.
enum Greeting {
    static func current(at date: Date = .now, calendar: Calendar = .current) -> String {
        switch calendar.component(.hour, from: date) {
        case 5..<12: "Good morning"
        case 12..<18: "Good afternoon"
        case 18..<23: "Good evening"
        default: "Still up?"
        }
    }
}
