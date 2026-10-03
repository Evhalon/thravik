import AppKit
import RedentKit

enum KeyChordFromEvent {
    static func make(from event: NSEvent) -> KeyChord? {
        guard let key = keyName(event) else { return nil }
        let modifiers = modifiers(event.modifierFlags)
        if !isFunctionKey(key) && !hasCommandOrControl(modifiers) { return nil }
        return KeyChord(key: key, modifiers: modifiers)
    }

    static func isEscape(_ event: NSEvent) -> Bool {
        event.keyCode == 53
    }

    static func isClear(_ event: NSEvent) -> Bool {
        event.keyCode == 51 || event.keyCode == 117
    }

    /// Unshifted characters, so ⇧⌘] records as `]` + shift like the defaults,
    /// not as `}`.
    private static func keyName(_ event: NSEvent) -> String? {
        if let named = namedKeys[event.keyCode] { return named }
        if [51, 53, 117].contains(event.keyCode) { return nil }
        let raw = event.characters(byApplyingModifiers: []) ?? event.charactersIgnoringModifiers
        guard let character = raw?.first, !character.isUnprintable else { return nil }
        return String(character).lowercased()
    }

    private static let namedKeys: [UInt16: String] = [
        48: "tab", 49: "space", 36: "return", 76: "return",
        123: "left", 124: "right", 125: "down", 126: "up",
        122: "f1", 120: "f2", 99: "f3", 118: "f4", 96: "f5", 97: "f6",
        98: "f7", 100: "f8", 101: "f9", 109: "f10", 103: "f11", 111: "f12"
    ]

    private static func modifiers(_ flags: NSEvent.ModifierFlags) -> KeyModifiers {
        var result = KeyModifiers()
        if flags.contains(.command) { result.insert(.command) }
        if flags.contains(.shift) { result.insert(.shift) }
        if flags.contains(.option) { result.insert(.option) }
        if flags.contains(.control) { result.insert(.control) }
        return result
    }

    /// Function keys never type text, so they may stand alone. Everything else
    /// needs ⌘ or ⌃: a bare or ⌥-only key would swallow typing in every field.
    private static func isFunctionKey(_ key: String) -> Bool {
        key.count > 1 && key.hasPrefix("f") && Int(key.dropFirst()) != nil
    }

    private static func hasCommandOrControl(_ modifiers: KeyModifiers) -> Bool {
        modifiers.contains(.command) || modifiers.contains(.control)
    }
}

private extension Character {
    /// Unnamed special keys (Home, Page Up…) arrive as control or private-use
    /// characters; they have no stable menu equivalent here.
    var isUnprintable: Bool {
        guard let category = unicodeScalars.first?.properties.generalCategory else { return true }
        return category == .control || category == .privateUse
    }
}
