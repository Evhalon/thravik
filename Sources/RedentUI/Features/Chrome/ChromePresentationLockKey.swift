import SwiftUI

/// Raised by a view inside revealed chrome while it presents its own sheet or
/// dialog, so the panel hosting that presentation is not dismissed under it.
enum ChromePresentationLockKey: PreferenceKey {
    static let defaultValue = false

    static func reduce(value: inout Bool, nextValue: () -> Bool) {
        value = value || nextValue()
    }
}
