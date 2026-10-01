import RedentDesign
import RedentKit
import SwiftUI

/// The pinned area while a Space has no pins: a dashed slot a tab can be
/// dragged into, so pinning is discoverable without the context menu.
struct PinDropZone: View {
    let target: PinDropTarget
    @State private var owner = UUID()

    private static let corner: CGFloat = 11

    var body: some View {
        glyph
            .frame(maxWidth: .infinity)
            .frame(height: PinnedTileGeometry.wideHeight)
            .background { fill }
            .overlay { outline }
            .scaleEffect(target.isTargeted ? 1.02 : 1)
            .animation(.easeOut(duration: 0.14), value: target.isTargeted)
            .onGeometryChange(for: CGRect.self) { $0.frame(in: .global) } action: {
                target.track(owner, frame: $0, pins: 0)
            }
            .onDisappear { target.forget(owner) }
            .help("Drag a tab here to pin it")
            .accessibilityLabel("Pinned tabs. Drag a tab here to pin it.")
    }

    private var glyph: some View {
        HStack(spacing: 6) {
            Image(systemName: target.isTargeted ? "pin.fill" : "pin")
                .font(.system(size: 13, weight: .semibold))
            Text(target.isTargeted ? "Drop to pin" : "Drag tabs here to pin")
                .font(.system(size: 12, weight: .medium))
                .lineLimit(1)
        }
        .foregroundStyle(target.isTargeted ? Palette.chromeText : Palette.chromeSecondaryText)
    }

    private var fill: some View {
        RoundedRectangle(cornerRadius: Self.corner, style: .continuous)
            .fill(target.isTargeted ? Palette.liftedChrome : Palette.chromeFill)
    }

    private var outline: some View {
        RoundedRectangle(cornerRadius: Self.corner, style: .continuous)
            .strokeBorder(
                target.isTargeted ? Palette.chromeText : Palette.chromeSecondaryText.opacity(0.7),
                style: StrokeStyle(lineWidth: target.isTargeted ? 1.5 : 1.2, dash: [5, 3])
            )
    }
}
