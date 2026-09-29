import SwiftUI

/// Frame of either address pill, in the window's space.
///
/// The window draws suggestions above both the rail and the web content.
enum AddressFieldFrameKey: PreferenceKey {
    static let space = "browserAddress"
    static var defaultValue: CGRect { .zero }

    static func reduce(value: inout CGRect, nextValue: () -> CGRect) {
        let next = nextValue()
        if next != .zero { value = next }
    }
}
