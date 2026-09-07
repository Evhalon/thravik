import SwiftUI

/// Full-width glass band the window buttons sit on.
///
/// A corner bite hid the desktop behind an opaque slab. This strip is the same
/// height, edge to edge, and frosts whatever is actually behind the window.
public struct TitlebarStrip: View {
    @Environment(\.colorScheme) private var scheme

    public init() {}

    public var body: some View {
        ZStack {
            VisualEffectBackdrop(.titlebar)
            satin
            NoiseOverlay(opacity: 0.03)
        }
        .overlay(alignment: .bottom) { hairline }
        .frame(maxWidth: .infinity)
        .frame(height: Metric.titlebarInset)
        .allowsHitTesting(false)
    }

    /// Light fall from above, kept thin so the desktop still reads through.
    private var satin: some View {
        LinearGradient(
            colors: scheme == .dark
                ? [Color.white.opacity(0.10), Color.white.opacity(0.02)]
                : [Color.white.opacity(0.32), Color.white.opacity(0.08)],
            startPoint: .top,
            endPoint: .bottom
        )
    }

    private var hairline: some View {
        Rectangle()
            .fill(.white.opacity(scheme == .dark ? 0.10 : 0.28))
            .frame(height: Metric.hairWidth)
    }
}
