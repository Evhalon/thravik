import SwiftUI

/// The ring that drains as a one-time code approaches expiry.
///
/// Two arcs: a dim track so the ring is legible when nearly empty, and the
/// live arc over it. The color slides toward `danger` as time runs out rather
/// than snapping, so the change registers before it is urgent.
public struct CountdownRing: View {
    private let fraction: Double
    private let lineWidth: CGFloat
    private let tint: Color

    public init(fraction: Double, lineWidth: CGFloat = 2.5, tint: Color = Palette.accent) {
        self.fraction = min(max(fraction, 0), 1)
        self.lineWidth = lineWidth
        self.tint = tint
    }

    public var body: some View {
        ZStack {
            Circle()
                .strokeBorder(Palette.chromeSecondaryText.opacity(0.22), lineWidth: lineWidth)
            Circle()
                .inset(by: lineWidth / 2)
                .trim(from: 0, to: fraction)
                .stroke(
                    AngularGradient(
                        colors: [currentTint.opacity(0.7), currentTint],
                        center: .center
                    ),
                    style: StrokeStyle(lineWidth: lineWidth, lineCap: .round)
                )
                .rotationEffect(.degrees(-90))
                .shadow(color: currentTint.opacity(0.5), radius: 3)
        }
        .animation(.linear(duration: 0.9), value: fraction)
    }

    /// Blends toward the warning color over the last fifth of the window.
    private var currentTint: Color {
        let threshold = 0.2
        guard fraction < threshold else { return tint }
        return tint.mix(with: Palette.danger, by: 1 - fraction / threshold)
    }
}

#Preview("CountdownRing") {
    HStack(spacing: 16) {
        ForEach([1.0, 0.6, 0.3, 0.12], id: \.self) { value in
            CountdownRing(fraction: value, lineWidth: 3, tint: .accentColor)
                .frame(width: 34, height: 34)
        }
    }
    .padding(28)
    .background(.black)
}
