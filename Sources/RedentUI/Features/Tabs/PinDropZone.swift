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
                target.track(owner, frame: $0)
            }
            .onDisappear { target.forget(owner) }
            .help("Drag a tab here to pin it")
            .accessibilityLabel("Pinned tabs. Drag a tab here to pin it.")
    }

    private var glyph: some View {
        Image(systemName: "pin")
            .font(.system(size: 14, weight: .regular))
            .overlay(alignment: .topTrailing) {
                Image(systemName: "plus")
                    .font(.system(size: 7, weight: .bold))
                    .offset(x: 6, y: -3)
            }
            .foregroundStyle(target.isTargeted ? Palette.chromeText : Palette.chromeSecondaryText)
    }

    @ViewBuilder
    private var fill: some View {
        if target.isTargeted {
            RoundedRectangle(cornerRadius: Self.corner, style: .continuous)
                .fill(Palette.liftedChrome)
        }
    }

    private var outline: some View {
        RoundedRectangle(cornerRadius: Self.corner, style: .continuous)
            .strokeBorder(
                target.isTargeted ? Palette.chromeSecondaryText : Palette.hairline,
                style: StrokeStyle(lineWidth: 1, dash: [4, 3])
            )
    }
}
