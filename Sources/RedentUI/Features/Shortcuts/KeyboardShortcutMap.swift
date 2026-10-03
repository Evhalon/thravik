import RedentKit
import SwiftUI

enum KeyboardShortcutMap {
    static func shortcut(for chord: KeyChord?) -> KeyboardShortcut? {
        guard let chord, let key = keyEquivalent(chord.key) else { return nil }
        return KeyboardShortcut(key, modifiers: eventModifiers(chord.modifiers))
    }

    static func keyEquivalent(_ name: String) -> KeyEquivalent? {
        switch name {
        case "tab":
            return KeyEquivalent.tab
        case "escape":
            return KeyEquivalent.escape
        case "space":
            return KeyEquivalent(" ")
        case "return":
            return KeyEquivalent.return
        case "delete":
            return KeyEquivalent.delete
        case "up": return .upArrow
        case "down": return .downArrow
        case "left": return .leftArrow
        case "right": return .rightArrow
        default:
            return functionKey(name) ?? name.first.map { KeyEquivalent($0) }
        }
    }

    /// `f1`…`f12` as AppKit's `NSF1FunctionKey`… characters.
    private static func functionKey(_ name: String) -> KeyEquivalent? {
        guard name.hasPrefix("f"), let number = Int(name.dropFirst()), (1...12).contains(number),
              let scalar = Unicode.Scalar(0xF704 + number - 1) else { return nil }
        return KeyEquivalent(Character(scalar))
    }

    static func eventModifiers(_ modifiers: KeyModifiers) -> EventModifiers {
        var result = EventModifiers()
        if modifiers.contains(.command) { result.insert(.command) }
        if modifiers.contains(.shift) { result.insert(.shift) }
        if modifiers.contains(.option) { result.insert(.option) }
        if modifiers.contains(.control) { result.insert(.control) }
        return result
    }
}
