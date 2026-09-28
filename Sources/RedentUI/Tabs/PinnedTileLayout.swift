import RedentKit
import SwiftUI

/// Lays pinned tiles out by `PinnedTileGeometry`: wide launchers first, then
/// squares, then more rows of squares.
struct PinnedTileLayout: Layout {
    func sizeThatFits(proposal: ProposedViewSize, subviews: Subviews, cache: inout ()) -> CGSize {
        let width = proposal.width ?? 0
        let geometry = PinnedTileGeometry(count: subviews.count, width: width)
        return CGSize(width: width, height: geometry.height(for: subviews.count))
    }

    func placeSubviews(in bounds: CGRect, proposal: ProposedViewSize, subviews: Subviews, cache: inout ()) {
        let geometry = PinnedTileGeometry(count: subviews.count, width: bounds.width)
        for (index, subview) in subviews.enumerated() {
            let origin = geometry.origin(of: index)
            subview.place(
                at: CGPoint(x: bounds.minX + origin.x, y: bounds.minY + origin.y),
                anchor: .topLeading,
                proposal: ProposedViewSize(width: geometry.tileWidth, height: geometry.tileHeight)
            )
        }
    }
}
