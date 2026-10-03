import RedentKit
import SwiftUI

struct BoundShortcut: ViewModifier {
    let id: ShortcutID
    let bindings: ShortcutBindings

    func body(content: Content) -> some View {
        if let shortcut = KeyboardShortcutMap.shortcut(for: bindings.chord(for: id)) {
            content.keyboardShortcut(shortcut)
        } else {
            content
        }
    }
}

extension View {
    func shortcut(_ id: ShortcutID, bindings: ShortcutBindings) -> some View {
        modifier(BoundShortcut(id: id, bindings: bindings))
    }
}
