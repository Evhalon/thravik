import SwiftUI

private struct FocusedBrowserModelKey: FocusedValueKey {
    typealias Value = BrowserModel
}

public extension FocusedValues {
    /// The model of the window the user is working in.
    ///
    /// Menu commands read this rather than being handed one window's model when
    /// the app is built: with more than one window open, ⌘T has to open a tab in
    /// the window in front, not in whichever one happened to be created first.
    var browserModel: BrowserModel? {
        get { self[FocusedBrowserModelKey.self] }
        set { self[FocusedBrowserModelKey.self] = newValue }
    }
}
