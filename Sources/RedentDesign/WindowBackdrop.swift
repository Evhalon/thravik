import SwiftUI

/// The window's single continuous glass slab.
///
/// Five stacked layers rather than one blur. The behind-window blur alone is
/// hostage to the user's wallpaper — over a dark desktop it collapses to flat
/// grey — so a base gradient underneath guarantees the chrome always reads as
/// designed, with the blur adding depth on top of it rather than being it.
public struct WindowBackdrop: View, @MainActor Equatable {
    private let tint: Color?

    @Environment(\.colorScheme) private var scheme

    public init(tint: Color?) {
        self.tint = tint
    }

    public var body: some View {
        ZStack {
            base
            VisualEffectBackdrop(.chrome).opacity(0.55)
            wash
            vignette
            NoiseOverlay(opacity: 0.045)
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
    }

    /// The wash carries no detail finer than its own blur, so it is drawn small
    /// and stretched. At full window size the gaussian is one of the most
    /// expensive things on screen, and it has to be redrawn on every frame of a
    /// fullscreen transition or a window resize.
    private var wash: some View {
        AmbientWash(tint: tint, intensity: scheme == .dark ? 0.85 : 0.5)
            .frame(width: 320, height: 240)
            .blur(radius: 13)
            .drawingGroup()
            .scaledToFill()
            .frame(maxWidth: .infinity, maxHeight: .infinity)
            .clipped()
    }

    /// Only the tint changes what this draws; a window resize or a sidebar
    /// toggle must not send five compositing layers through it again.
    nonisolated public static func == (lhs: WindowBackdrop, rhs: WindowBackdrop) -> Bool {
        lhs.tint == rhs.tint
    }

    private var base: some View {
        LinearGradient(
            colors: scheme == .dark
                ? [Color(white: 0.13), Color(white: 0.075)]
                : [Color(white: 0.97), Color(white: 0.90)],
            startPoint: .topLeading,
            endPoint: .bottomTrailing
        )
    }

    /// Darkened corners pull the eye toward the page card in the middle.
    private var vignette: some View {
        RadialGradient(
            colors: [.clear, .black.opacity(scheme == .dark ? 0.34 : 0.10)],
            center: .center,
            startRadius: 200,
            endRadius: 900
        )
    }
}
