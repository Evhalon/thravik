import AppKit
import RedentDesign
import SwiftUI

/// One site in the new-tab grid.
///
/// The tile takes its color from the site's own favicon, so the grid reads as a
/// set of places rather than a list of links — recognisable at a glance, before
/// any label is read.
struct NewTabTileView: View {
    let tile: NewTabTile
    let onOpen: (_ commandHeld: Bool) -> Void
    var onRemoveFavorite: (() -> Void)?

    @State private var isHovering = false
    @State private var fetchedIcon: Data?

    var body: some View {
        Button(action: { onOpen(NSEvent.modifierFlags.contains(.command)) }) {
            VStack(spacing: 9) {
                icon
                Text(tile.host)
                    .font(.system(size: 11, weight: .medium))
                    .foregroundStyle(Palette.chromeSecondaryText)
                    .lineLimit(1)
            }
            .frame(width: 96)
            .contentShape(.rect)
        }
        .buttonStyle(PressScaleStyle())
        .scaleEffect(isHovering ? 1.06 : 1)
        .animation(.spring(duration: 0.25), value: isHovering)
        .onHover { isHovering = $0 }
        .help(tile.title)
        .contextMenu { menu }
        .task(id: tile.host) { await loadIcon() }
    }

    @ViewBuilder
    private var menu: some View {
        if tile.isFavorite, let onRemoveFavorite {
            Button("Remove from Favorites", role: .destructive, action: onRemoveFavorite)
        }
    }

    private func loadIcon() async {
        if Self.canDraw(tile.faviconData) { return }
        fetchedIcon = await SiteIconLoader.shared.icon(for: tile.host)
    }

    private static func canDraw(_ data: Data?) -> Bool {
        guard let data, !data.isEmpty, let image = NSImage(data: data) else { return false }
        return image.isValid
    }

    private var iconData: Data? {
        if Self.canDraw(tile.faviconData) { return tile.faviconData }
        return fetchedIcon
    }

    private var icon: some View {
        let accent = DominantColor.extract(from: iconData) ?? Palette.defaultAmbient
        return ZStack {
            RoundedRectangle(cornerRadius: 17, style: .continuous)
                .fill(accent.opacity(isHovering ? 0.30 : 0.18))
            RoundedRectangle(cornerRadius: 17, style: .continuous)
                .strokeBorder(
                    LinearGradient(colors: [.white.opacity(0.28), .white.opacity(0.05)],
                                   startPoint: .top, endPoint: .bottom),
                    lineWidth: Metric.hairWidth
                )
            FaviconView(data: iconData, host: tile.host, size: 30)
        }
        .frame(width: 62, height: 62)
        .shadow(color: accent.opacity(isHovering ? 0.45 : 0.18), radius: isHovering ? 14 : 7, y: 4)
        .overlay(alignment: .topTrailing) {
            if tile.isFavorite {
                Image(systemName: "star.fill")
                    .font(.system(size: 8))
                    .foregroundStyle(.white.opacity(0.85))
                    .padding(4)
                    .background(Circle().fill(accent.opacity(0.9)))
                    .offset(x: 5, y: -5)
            }
        }
    }
}
