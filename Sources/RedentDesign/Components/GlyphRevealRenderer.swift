import SwiftUI

/// Draws text arriving one glyph at a time, left to right: each glyph rises
/// out of a blur into place. `elapsedTime` is what animates, so a plain linear
/// animation of it drives the whole sweep while every glyph keeps its own curve.
public struct GlyphRevealRenderer: TextRenderer, Animatable {
    public var elapsedTime: TimeInterval
    private let glyphDuration: TimeInterval
    private let totalDuration: TimeInterval

    public var animatableData: Double {
        get { elapsedTime }
        set { elapsedTime = newValue }
    }

    public init(elapsedTime: TimeInterval, totalDuration: TimeInterval, glyphDuration: TimeInterval = 0.45) {
        self.elapsedTime = min(elapsedTime, totalDuration)
        self.glyphDuration = min(glyphDuration, totalDuration)
        self.totalDuration = totalDuration
    }

    public func draw(layout: Text.Layout, in context: inout GraphicsContext) {
        let slices = layout.flatMap { line in line.flatMap { run in run } }
        let delay = glyphDelay(count: slices.count)
        for (index, slice) in slices.enumerated() {
            let start = TimeInterval(index) * delay
            let time = max(0, min(elapsedTime - start, glyphDuration))
            var glyphContext = context
            draw(slice, at: time, in: &glyphContext)
        }
    }

    private func draw(_ slice: Text.Layout.RunSlice, at time: TimeInterval, in context: inout GraphicsContext) {
        let progress = time / glyphDuration
        let height = slice.typographicBounds.rect.height
        let rise = Spring.snappy(duration: glyphDuration, extraBounce: 0.25)
            .value(fromValue: height * 0.35, toValue: 0, initialVelocity: 0, time: time)
        context.opacity = UnitCurve.easeOut.value(at: min(1, progress * 1.6))
        context.addFilter(.blur(radius: height / 5 * UnitCurve.easeIn.value(at: 1 - progress)))
        context.translateBy(x: 0, y: rise)
        context.draw(slice, options: .disablesSubpixelQuantization)
    }

    /// Spreads the glyphs' starts over the time the last one does not need.
    private func glyphDelay(count: Int) -> TimeInterval {
        guard count > 1 else { return 0 }
        return (totalDuration - glyphDuration) / TimeInterval(count - 1)
    }
}
