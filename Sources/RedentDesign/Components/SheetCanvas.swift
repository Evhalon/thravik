import SwiftUI

/// macOS 26 sheets grow a titlebar that steals height from a fixed frame,
/// clipping the footer. Form sizing plus a flexible ideal height keeps
/// Cancel/Import/Done on screen; the body scrolls if it still runs long.
public extension View {
    func sheetCanvas(width: CGFloat, height: CGFloat) -> some View {
        frame(
            minWidth: width,
            idealWidth: width,
            minHeight: min(height, 380),
            idealHeight: height
        )
        .presentationSizing(.form)
    }
}
