import SwiftUI

/// Text that appears glyph by glyph and leaves with a plain fade, so a label
/// replaced by a new one never plays the reveal backwards.
public struct TextRevealTransition: Transition {
    public static let duration: TimeInterval = 0.8

    public static var properties: TransitionProperties { TransitionProperties(hasMotion: true) }

    public init() {}

    public func body(content: Content, phase: TransitionPhase) -> some View {
        let renderer = GlyphRevealRenderer(
            elapsedTime: phase == .willAppear ? 0 : Self.duration,
            totalDuration: Self.duration
        )
        content
            .transaction { transaction in
                guard !transaction.disablesAnimations, phase != .didDisappear else { return }
                transaction.animation = .linear(duration: Self.duration)
            } body: { view in
                view.textRenderer(renderer)
            }
            .opacity(phase == .didDisappear ? 0 : 1)
    }
}

extension Transition where Self == TextRevealTransition {
    /// A label arriving glyph by glyph, rising out of a blur.
    public static var textReveal: TextRevealTransition { TextRevealTransition() }
}
