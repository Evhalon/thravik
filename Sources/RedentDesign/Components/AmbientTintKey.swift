import SwiftUI

private struct AmbientTintKey: EnvironmentKey {
    static let defaultValue: Color? = nil
}

public extension EnvironmentValues {
    /// The color the chrome should take on, normally the active page's
    /// `theme-color`. Set once at the window root; every glass surface reads it.
    var ambientTint: Color? {
        get { self[AmbientTintKey.self] }
        set { self[AmbientTintKey.self] = newValue }
    }
}
