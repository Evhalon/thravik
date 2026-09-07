import RedentDesign
import RedentKit
import SwiftUI

/// The seam between two panes. Follows the pointer directly — an animated
/// width lags behind the cursor mid-drag, which reads as a broken control.
struct SplitDivider: View {
    let orientation: SplitLayout.Orientation
    let onDrag: (CGFloat) -> Void

    @State private var isHovering = false

    var body: some View {
        Rectangle()
            .fill(.white.opacity(isHovering ? 0.20 : 0.08))
            .frame(
                width: orientation == .horizontal ? Metric.hairWidth + 3 : nil,
                height: orientation == .vertical ? Metric.hairWidth + 3 : nil
            )
            .contentShape(.rect)
            .onHover { hovering in
                isHovering = hovering
                if hovering { NSCursor.resizeLeftRight.push() } else { NSCursor.pop() }
            }
            .gesture(
                DragGesture(minimumDistance: 1)
                    .onChanged { value in
                        onDrag(orientation == .horizontal ? value.translation.width : value.translation.height)
                    }
            )
    }
}
