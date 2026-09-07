import SwiftUI

/// The colored light the chrome picks up from the page in front of it.
///
/// A page's `theme-color` bleeds into the surrounding glass as a soft mesh, so
/// the browser takes on the character of whatever site is open instead of
/// staying a neutral grey box. Static by construction — a continuously
/// animated gradient behind every tab is a battery bug, not a delight.
public struct AmbientWash: View {
    private let tint: Color
    private let intensity: Double

    public init(tint: Color?, intensity: Double = 1) {
        self.tint = tint ?? Palette.defaultAmbient
        self.intensity = intensity
    }

    public var body: some View {
        MeshGradient(
            width: 3,
            height: 3,
            points: Self.points,
            colors: colors,
            smoothsColors: true
        )
        .opacity(intensity)
        .animation(.easeInOut(duration: 0.6), value: tint)
        .allowsHitTesting(false)
    }

    /// Light enters from the top-left and pools again, weaker, at the bottom
    /// right — one source plus its bounce, which is what stops a flat wash from
    /// looking like a colored filter laid over the window.
    private var colors: [Color] {
        let strong = tint.opacity(0.85)
        let mid = tint.opacity(0.45)
        let faint = tint.opacity(0.16)
        return [strong, mid, faint,
                mid, faint.opacity(0.5), faint,
                faint, faint, mid.opacity(0.7)]
    }

    private static let points: [SIMD2<Float>] = [
        [0.0, 0.0], [0.5, 0.0], [1.0, 0.0],
        [0.0, 0.45], [0.62, 0.38], [1.0, 0.5],
        [0.0, 1.0], [0.5, 1.0], [1.0, 1.0]
    ]
}
