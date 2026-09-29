import SwiftUI

/// A thin ring that fills as work completes, or spins while the total is
/// unknown. Unlike `CountdownRing` it never shifts toward a warning color: a
/// download near zero is starting, not running out.
public struct ProgressRing: View {
    private let fraction: Double?
    private let lineWidth: CGFloat

    public init(fraction: Double?, lineWidth: CGFloat = 1.8) {
        self.fraction = fraction.map { min(max($0, 0), 1) }
        self.lineWidth = lineWidth
    }

    public var body: some View {
        ZStack {
            Circle()
                .stroke(Palette.chromeSecondaryText.opacity(0.25), lineWidth: lineWidth)
            if let fraction {
                arc(to: max(fraction, 0.02))
                    .rotationEffect(.degrees(-90))
                    .animation(.smooth(duration: 0.45), value: fraction)
            } else {
                SpinningArc(lineWidth: lineWidth)
            }
        }
        .padding(lineWidth / 2)
    }

    private func arc(to end: Double) -> some View {
        Circle()
            .trim(from: 0, to: end)
            .stroke(Palette.accent, style: StrokeStyle(lineWidth: lineWidth, lineCap: .round))
    }
}

/// Its own view so the endless rotation belongs only to the unknown-size
/// state and stops the moment a total arrives.
private struct SpinningArc: View {
    let lineWidth: CGFloat
    @State private var isSpinning = false

    var body: some View {
        Circle()
            .trim(from: 0, to: 0.28)
            .stroke(Palette.accent, style: StrokeStyle(lineWidth: lineWidth, lineCap: .round))
            .rotationEffect(.degrees(isSpinning ? 270 : -90))
            .onAppear {
                withAnimation(.linear(duration: 0.9).repeatForever(autoreverses: false)) {
                    isSpinning = true
                }
            }
    }
}

#Preview("ProgressRing") {
    HStack(spacing: 16) {
        ForEach([0.1, 0.5, 0.9], id: \.self) { value in
            ProgressRing(fraction: value).frame(width: 18, height: 18)
        }
        ProgressRing(fraction: nil).frame(width: 18, height: 18)
    }
    .padding(28)
}
