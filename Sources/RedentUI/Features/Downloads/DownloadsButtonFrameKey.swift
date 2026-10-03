import SwiftUI

/// Frame of the downloads control, in the window overlay's space.
enum DownloadsButtonFrameKey: PreferenceKey {
    static let space = "downloadsButton"
    static var defaultValue: CGRect { .zero }

    static func reduce(value: inout CGRect, nextValue: () -> CGRect) {
        let next = nextValue()
        if next.width > 8, next.height > 8 { value = next }
    }
}
