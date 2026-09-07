import SwiftUI

public extension View {
    /// A capsule that floats above the page — the shape the one-time-code
    /// button and other transient affordances use.
    func glassCapsuleSurface(tint: Color? = nil) -> some View {
        floatingGlass(in: Capsule(style: .continuous), ambient: 0.5)
            .environment(\.ambientTint, tint)
    }
}
