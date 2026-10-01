import RedentDesign
import RedentKit
import SwiftUI

/// Any color, not just the swatches: drag along the spectrum for a hue, or
/// open the system picker at the end for an exact one.
struct SpaceHueStrip: View {
    @Binding var tint: SpaceTint

    private static let stops = stride(from: 0.0, through: 1.0, by: 1.0 / 12).map {
        SpaceTintColor.color(SpaceRGB(hue: $0, saturation: 0.85, brightness: 1))
    }

    /// The system well's own width; reserving less lets it spill past the edge.
    private static let wellWidth: CGFloat = 44

    var body: some View {
        HStack(spacing: 10) {
            spectrum
            ColorPicker("Custom color", selection: exactColor, supportsOpacity: false)
                .labelsHidden()
                .frame(width: Self.wellWidth)
        }
    }

    private var spectrum: some View {
        GeometryReader { proxy in
            Capsule()
                .fill(LinearGradient(colors: Self.stops, startPoint: .leading, endPoint: .trailing))
                .overlay { Capsule().strokeBorder(.white.opacity(0.18), lineWidth: 1) }
                .overlay(alignment: .leading) { thumb(in: proxy.size.width) }
                .contentShape(.rect)
                .gesture(
                    DragGesture(minimumDistance: 0)
                        .onChanged { pick(at: $0.location.x, width: proxy.size.width) }
                )
        }
        .frame(height: 16)
        .accessibilityElement()
        .accessibilityLabel("Hue")
        .accessibilityValue("\(Int(hue * 360)) degrees")
        .accessibilityAdjustableAction(adjust)
    }

    private func thumb(in width: CGFloat) -> some View {
        Circle()
            .fill(SpaceTintColor.color(SpaceRGB(hue: hue, saturation: 0.85, brightness: 1)))
            .overlay { Circle().strokeBorder(.white, lineWidth: 2.5) }
            .frame(width: 20, height: 20)
            .shadow(color: .black.opacity(0.3), radius: 3, y: 1)
            .offset(x: hue * max(width - 20, 0))
            .allowsHitTesting(false)
    }

    private var hue: Double { SpaceTintColor.baseRGB(tint.base).hue }

    private var exactColor: Binding<Color> {
        Binding(
            get: { SpaceTintColor.color(SpaceTintColor.baseRGB(tint.base)) },
            set: { tint.base = .custom(SpaceTintColor.rgb(of: $0)) }
        )
    }

    private func pick(at x: CGFloat, width: CGFloat) {
        let travel = max(width - 20, 1)
        let picked = min(max((x - 10) / travel, 0), 0.999)
        tint.base = .custom(SpaceRGB(hue: picked, saturation: 0.85, brightness: 1))
    }

    private func adjust(_ direction: AccessibilityAdjustmentDirection) {
        let step = direction == .increment ? 1.0 / 36 : -1.0 / 36
        let next = (hue + step + 1).truncatingRemainder(dividingBy: 1)
        tint.base = .custom(SpaceRGB(hue: next, saturation: 0.85, brightness: 1))
    }
}
