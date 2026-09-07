import RedentDesign
import RedentKit
import SwiftUI

/// The draggable seam between the tab rail and the page.
///
/// Uses `@GestureState` rather than `@State` for the drag origin: `@State`
/// survives across gestures and is reset when the view's identity changes, so a
/// re-layout mid-drag makes the translation accumulate from a stale origin and
/// the sidebar walks itself to the minimum width. `@GestureState` is torn down
/// with the gesture, which makes that class of drift impossible.
struct SidebarResizeHandle: View {
    @Binding var width: Double

    @GestureState private var dragOrigin: Double?
    @State private var isHovering = false

    var body: some View {
        Rectangle()
            .fill(isHovering ? Palette.accent.opacity(0.55) : Color.white.opacity(0.06))
            .frame(width: 1)
            // A 1pt line is impossible to grab; the hit area is widened well
            // past what is drawn.
            .contentShape(.rect.inset(by: -5))
            .onHover { hovering in
                withAnimation(.easeOut(duration: 0.12)) { isHovering = hovering }
                // `set()` rather than `push()`/`pop()`: SwiftUI does not
                // guarantee a matching exit for every enter, and an unbalanced
                // cursor stack leaves the whole app stuck on a resize cursor.
                (hovering ? NSCursor.resizeLeftRight : NSCursor.arrow).set()
            }
            .gesture(resize)
    }

    private var resize: some Gesture {
        // Global coordinates, never the handle's own: the handle slides with the
        // width it is setting, so a local translation is measured against an
        // origin that the drag itself keeps moving. That feedback loop is what
        // makes the seam — and the page next to it — judder under the pointer.
        DragGesture(minimumDistance: 4, coordinateSpace: .global)
            .updating($dragOrigin) { _, origin, _ in
                if origin == nil { origin = width }
            }
            .onChanged { value in
                guard let dragOrigin else { return }
                width = (dragOrigin + value.translation.width)
                    .clamped(to: BrowserSettings.sidebarWidthRange)
            }
    }
}

private extension Double {
    func clamped(to range: ClosedRange<Double>) -> Double {
        min(max(self, range.lowerBound), range.upperBound)
    }
}
