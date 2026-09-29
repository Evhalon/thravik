import AppKit
import RedentDesign
import SwiftUI

/// A tile's drawable favicon and the accent sampled from it.
struct TileArtwork: Equatable {
    let iconData: Data?
    let accent: Color

    static func resolve(for tile: NewTabTile) async -> TileArtwork {
        let data = canDraw(tile.faviconData)
            ? tile.faviconData
            : await SiteIconLoader.shared.icon(for: tile.host)
        let accent = DominantColor.extract(from: data) ?? fallbackAccent(for: tile.host)
        return TileArtwork(iconData: data, accent: accent)
    }

    static func fallbackAccent(for host: String) -> Color {
        var hash: UInt64 = 5381
        for byte in host.utf8 { hash = (hash &* 33) &+ UInt64(byte) }
        return Color(hue: Double(hash % 360) / 360, saturation: 0.55, brightness: 0.78)
    }

    private static func canDraw(_ data: Data?) -> Bool {
        guard let data, !data.isEmpty, let image = NSImage(data: data) else { return false }
        return image.isValid
    }
}
