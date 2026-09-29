import SwiftUI

/// Redent's glass, built by hand rather than taken off the shelf.
///
/// Five layers, in order: a real behind-window blur, the page's ambient color,
/// a vertical sheen that gives the slab a light source, grain to kill banding,
/// and a specular hairline so the edge stays crisp over any page.
public struct GlassSurface<S: InsettableShape>: ViewModifier {
    private let shape: S
    private let depth: VisualEffectBackdrop.Depth
    private let ambient: Double
    private let shadow: Bool

    @Environment(\.ambientTint) private var tint
    @Environment(\.colorScheme) private var scheme

    public init(shape: S, depth: VisualEffectBackdrop.Depth, ambient: Double, shadow: Bool) {
        self.shape = shape
        self.depth = depth
        self.ambient = ambient
        self.shadow = shadow
    }

    public func body(content: Content) -> some View {
        content
            .background {
                ZStack {
                    VisualEffectBackdrop(depth)
                    scrim
                    AmbientWash(tint: tint, intensity: ambient)
                    sheen
                    NoiseOverlay()
                }
                .clipShape(shape)
                .shadow(color: .black.opacity(shadow ? 0.28 : 0), radius: 22, y: 10)
            }
            .overlay { specularEdge }
    }

    /// A floating surface can end up over a black page or a white one. The
    /// scrim fixes its own base value so the glass reads the same either way.
    @ViewBuilder
    private var scrim: some View {
        if depth == .floating {
            (scheme == .dark ? Color.black.opacity(0.55) : Color.white.opacity(0.55))
        }
    }

    /// Light falls from above, so the top of the slab is brighter.
    private var sheen: some View {
        LinearGradient(
            colors: scheme == .dark
                ? [.white.opacity(0.10), .white.opacity(0.02), .black.opacity(0.12)]
                : [.white.opacity(0.55), .white.opacity(0.18), .black.opacity(0.04)],
            startPoint: .top,
            endPoint: .bottom
        )
    }

    /// A gradient stroke, not a flat one — a uniform border looks drawn on,
    /// a brighter top edge looks like a lit bevel.
    private var specularEdge: some View {
        shape.strokeBorder(
            LinearGradient(
                colors: [.white.opacity(scheme == .dark ? 0.28 : 0.9),
                         .white.opacity(scheme == .dark ? 0.06 : 0.25),
                         .black.opacity(0.10)],
                startPoint: .top,
                endPoint: .bottom
            ),
            lineWidth: Metric.hairWidth
        )
    }
}

public extension View {
    /// The standard chrome slab.
    func glassSurface<S: InsettableShape>(
        in shape: S,
        depth: VisualEffectBackdrop.Depth = .chrome,
        ambient: Double = 0.5,
        shadow: Bool = false
    ) -> some View {
        modifier(GlassSurface(shape: shape, depth: depth, ambient: ambient, shadow: shadow))
    }

    /// A slab that floats above the page: stronger blur, real shadow.
    func floatingGlass<S: InsettableShape>(in shape: S, ambient: Double = 0.35) -> some View {
        modifier(GlassSurface(shape: shape, depth: .floating, ambient: ambient, shadow: true))
    }
}
