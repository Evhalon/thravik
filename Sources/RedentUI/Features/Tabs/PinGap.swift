import RedentDesign
import SwiftUI

/// The empty cell a dragged tab would be pinned into.
struct PinGap: View {
    private static let corner: CGFloat = 11

    var body: some View {
        let shape = RoundedRectangle(cornerRadius: Self.corner, style: .continuous)
        shape
            .fill(Palette.liftedChrome)
            .overlay { shape.strokeBorder(Palette.chromeSecondaryText, style: StrokeStyle(lineWidth: 1, dash: [4, 3])) }
            .transition(.opacity.combined(with: .scale(scale: 0.8)))
            .accessibilityHidden(true)
    }
}
