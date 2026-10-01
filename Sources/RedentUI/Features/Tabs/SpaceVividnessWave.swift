import RedentKit
import SwiftUI

/// A live read of the vividness dial: a calm, flat ripple when the color is
/// muted, a tall quick swell with a glow when it is pushed toward neon.
///
/// The glow is a few wide, faint strokes rather than a blur filter: a blur
/// re-rasterizes offscreen every frame, the stacked strokes are plain vector
/// fills, and at this size the eye cannot tell them apart.
struct SpaceVividnessWave: View {
    let tint: SpaceTint
    let color: Color
    @Environment(\.accessibilityReduceMotion) private var reduceMotion

    /// Room past the layout frame for the glow, so a tall swell's halo fades
    /// out on its own instead of being sliced flat by the canvas edge.
    private static let bleed: CGFloat = 12
    /// A ripple this slow reads as smooth at 30 fps; ProMotion's 120 would
    /// quadruple the work for nothing.
    private static let frameInterval = 1.0 / 30

    var body: some View {
        TimelineView(.animation(minimumInterval: Self.frameInterval, paused: reduceMotion)) { context in
            Canvas { canvas, size in
                canvas.translateBy(x: Self.bleed, y: Self.bleed)
                let inner = CGSize(width: size.width - 2 * Self.bleed, height: size.height - 2 * Self.bleed)
                draw(in: &canvas, size: inner, time: context.date.timeIntervalSinceReferenceDate)
            }
            .padding(-Self.bleed)
        }
        .frame(height: 44)
        .accessibilityHidden(true)
    }

    private func draw(in canvas: inout GraphicsContext, size: CGSize, time: TimeInterval) {
        let vividness = tint.vividness
        let wave = path(in: size, amplitude: 3 + 15 * vividness, phase: time * (1.2 + 3 * vividness))
        let fade = Gradient(stops: [
            .init(color: color.opacity(0), location: 0),
            .init(color: color, location: 0.18),
            .init(color: color, location: 0.82),
            .init(color: color.opacity(0), location: 1)
        ])
        let shading = GraphicsContext.Shading.linearGradient(
            fade, startPoint: .zero, endPoint: CGPoint(x: size.width, y: 0)
        )
        let glow = 0.1 + 0.3 * vividness
        for (width, strength) in [(16.0, 0.35), (10.0, 0.6), (6.0, 1.0)] {
            canvas.opacity = glow * strength
            canvas.stroke(wave, with: shading, style: StrokeStyle(lineWidth: width, lineCap: .round))
        }
        canvas.opacity = 1
        canvas.stroke(wave, with: shading, style: StrokeStyle(lineWidth: 2.5, lineCap: .round))
    }

    private func path(in size: CGSize, amplitude: Double, phase: Double) -> Path {
        let midline = size.height / 2
        let wavelength = max(size.width / 4.5, 1)
        return Path { path in
            path.move(to: CGPoint(x: 0, y: midline))
            for x in stride(from: 0, through: size.width, by: 2) {
                let swell = sin(Double(x) / wavelength * 2 * .pi - phase)
                path.addLine(to: CGPoint(x: x, y: midline + amplitude * swell))
            }
        }
    }
}
