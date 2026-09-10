import SwiftUI

/// Frame of the address pill, in the page column's space.
///
/// The suggestion list has to be an overlay of the column — not of the field —
/// or the page card and its web view paint over it.
enum AddressFieldFrameKey: PreferenceKey {
    static let space = "pageColumn"
    static var defaultValue: CGRect { .zero }

    static func reduce(value: inout CGRect, nextValue: () -> CGRect) {
        let next = nextValue()
        if next != .zero { value = next }
    }
}
