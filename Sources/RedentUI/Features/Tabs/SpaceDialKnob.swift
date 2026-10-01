import RedentDesign
import RedentKit
import SwiftUI

/// A rotary dial for one 0…1 quality of a Space's color. Drag up or right to
/// turn it up; double-click to snap back to its resting value.
struct SpaceDialKnob: View {
    let title: String
    @Binding var value: Double
    let resting: Double
    let color: Color

    @State private var dragOrigin: Double?

    private static let sweep = 270.0
    private static let tickCount = 21
    private static let dragTravel = 140.0

    var body: some View {
        VStack(spacing: 3) {
            ZStack {
                ticks
                dial
            }
            .frame(width: 52, height: 52)
            .contentShape(.circle)
            .gesture(turn)
            .onTapGesture(count: 2) { withAnimation(.spring(duration: 0.3)) { value = resting } }
            Text(title)
                .font(.system(size: 9, weight: .semibold))
                .foregroundStyle(Palette.chromeSecondaryText)
        }
        .help("\(title) — drag to turn, double-click to reset")
        .accessibilityElement()
        .accessibilityLabel(title)
        .accessibilityValue("\(Int((value * 100).rounded())) percent")
        .accessibilityAdjustableAction { direction in
            value = clamped(value + (direction == .increment ? 0.05 : -0.05))
        }
    }

    /// One canvas instead of twenty-one rotated views, so turning the dial
    /// repaints a single layer.
    private var ticks: some View {
        Canvas { canvas, size in
            let center = CGPoint(x: size.width / 2, y: size.height / 2)
            let lit = Palette.chromeSecondaryText.opacity(0.3)
            for index in 0..<Self.tickCount {
                let progress = Double(index) / Double(Self.tickCount - 1)
                let length = index % 5 == 0 ? 6.0 : 4.0
                var tick = canvas
                tick.translateBy(x: center.x, y: center.y)
                tick.rotate(by: angle(for: progress))
                let bar = CGRect(x: -0.75, y: -23 - length / 2, width: 1.5, height: length)
                tick.fill(Capsule().path(in: bar), with: .color(progress <= value + 0.001 ? color : lit))
            }
        }
    }

    /// Only the pointer turns; the shaded body and its shadow stay put, so
    /// the shadow is rendered once rather than on every step of a drag.
    private var dial: some View {
        Circle()
            .fill(
                RadialGradient(
                    colors: [Color.white.opacity(0.16), Color.black.opacity(0.35)],
                    center: .init(x: 0.35, y: 0.3), startRadius: 2, endRadius: 30
                )
            )
            .overlay { Circle().strokeBorder(.white.opacity(0.14), lineWidth: 1) }
            .frame(width: 36, height: 36)
            .shadow(color: .black.opacity(0.35), radius: 4, y: 2)
            .overlay { pointer }
    }

    private var pointer: some View {
        Capsule()
            .fill(color)
            .frame(width: 3, height: 9)
            .background { Capsule().fill(color.opacity(0.35)).frame(width: 7, height: 13) }
            .padding(.top, 4)
            .frame(width: 36, height: 36, alignment: .top)
            .rotationEffect(angle(for: value))
    }

    private var turn: some Gesture {
        DragGesture(minimumDistance: 1)
            .onChanged { drag in
                let origin = dragOrigin ?? value
                dragOrigin = origin
                let travel = (drag.translation.width - drag.translation.height) / Self.dragTravel
                value = clamped(origin + travel)
            }
            .onEnded { _ in dragOrigin = nil }
    }

    private func angle(for progress: Double) -> Angle {
        .degrees(-Self.sweep / 2 + Self.sweep * progress)
    }

    private func clamped(_ value: Double) -> Double {
        min(max(value, 0), 1)
    }
}
