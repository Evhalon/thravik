import SwiftUI

/// Coordinates mirror the four pieces of Resources/ThravikMark.svg.
struct OnboardingPortal: View {
    @Environment(\.accessibilityReduceMotion) private var reduceMotion
    @State private var opened = false

    var body: some View {
        ZStack {
            ForEach(0..<4) { index in
                portalPiece
                    .fill(Color(red: 1, green: 0.23, blue: 0.07))
                    .offset(y: opened ? -15 : 0)
                    .rotationEffect(.degrees(Double(index) * 90))
            }
            Rectangle().fill(.white)
                .frame(width: 25, height: 25)
                .rotationEffect(.degrees(opened ? 135 : 45))
                .scaleEffect(opened ? 0.8 : 1)
        }
        .frame(width: 144, height: 144)
        .shadow(color: .orange.opacity(0.24), radius: opened ? 30 : 12)
        .accessibilityHidden(true)
        .onAppear {
            guard !reduceMotion else { return }
            withAnimation(.spring(duration: 1.6, bounce: 0.22).delay(0.15)) { opened = true }
        }
    }

    private var portalPiece: Path {
        let scale = 144.0 / 512.0
        let points: [CGPoint] = [
            CGPoint(x: 256, y: 58), CGPoint(x: 378, y: 128), CGPoint(x: 342, y: 190),
            CGPoint(x: 256, y: 140), CGPoint(x: 170, y: 190), CGPoint(x: 134, y: 128)
        ]
        return Path { path in
            path.addLines(points.map { CGPoint(x: $0.x * scale, y: $0.y * scale) })
            path.closeSubpath()
        }
    }
}
