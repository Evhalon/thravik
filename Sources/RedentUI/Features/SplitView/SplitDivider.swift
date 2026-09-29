import RedentDesign
import RedentKit
import SwiftUI

/// The seam between two panes. Follows the pointer directly — an animated
/// width lags behind the cursor mid-drag, which reads as a broken control.
struct SplitDivider: View {
    static let thickness = Metric.hairWidth + 3

    let orientation: SplitLayout.Orientation
    /// Total travel since the drag began, in points along the split.
    let onDrag: (CGFloat) -> Void
    let onEnd: () -> Void

    @State private var isHovering = false

    var body: some View {
        Rectangle()
            .fill(.white.opacity(isHovering ? 0.20 : 0.08))
            .frame(
                width: orientation == .horizontal ? Self.thickness : nil,
                height: orientation == .vertical ? Self.thickness : nil
            )
            .contentShape(.rect)
            .onHover { hovering in
                isHovering = hovering
                if hovering { cursor.push() } else { NSCursor.pop() }
            }
            .gesture(
                DragGesture(minimumDistance: 1, coordinateSpace: .global)
                    .onChanged { value in
                        onDrag(orientation == .horizontal ? value.translation.width : value.translation.height)
                    }
                    .onEnded { _ in onEnd() }
            )
    }

    private var cursor: NSCursor {
        orientation == .horizontal ? .resizeLeftRight : .resizeUpDown
    }
}
