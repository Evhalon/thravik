import Foundation

/// How pinned tabs tile the top of the sidebar.
///
/// Up to three share one row as wide launchers. Past that every pin still
/// shares the row, each narrower, until the row holds `maxColumns` or the
/// tiles reach a square; then they wrap onto further rows.
public struct PinnedTileGeometry: Sendable {
    public let columns: Int
    public let tileWidth: CGFloat
    public let tileHeight: CGFloat

    public static let spacing: CGFloat = 6
    public static let wideHeight: CGFloat = 44
    public static let smallestSide: CGFloat = 32
    public static let maxColumns = 4

    public init(count: Int, width: CGFloat) {
        let spacing = Self.spacing
        let fitting = Int((max(width, 0) + spacing) / (Self.smallestSide + spacing))
        let columns = max(1, min(count, fitting, Self.maxColumns))
        let tileWidth = max(0, (width - spacing * CGFloat(columns - 1)) / CGFloat(columns))
        self.columns = columns
        self.tileWidth = tileWidth
        self.tileHeight = min(Self.wideHeight, tileWidth)
    }

    public func rows(for count: Int) -> Int {
        count <= 0 ? 0 : (count + columns - 1) / columns
    }

    public func height(for count: Int) -> CGFloat {
        let rows = rows(for: count)
        guard rows > 0 else { return 0 }
        return CGFloat(rows) * tileHeight + CGFloat(rows - 1) * Self.spacing
    }

    /// The top-left corner of the tile at `index`, row by row.
    /// Plain offsets rather than a `CGPoint`: Swift 6.3's release build fails
    /// to read CoreGraphics types back out of this Foundation-only module.
    public func origin(of index: Int) -> (x: CGFloat, y: CGFloat) {
        let column = CGFloat(index % columns)
        let row = CGFloat(index / columns)
        return (column * (tileWidth + Self.spacing), row * (tileHeight + Self.spacing))
    }
}
