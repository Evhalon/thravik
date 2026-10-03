import Foundation

enum KeyChordDisplay {
    static func string(for chord: KeyChord) -> String {
        modifierPrefix(chord.modifiers) + glyph(for: chord.key)
    }

    private static func modifierPrefix(_ modifiers: KeyModifiers) -> String {
        var prefix = ""
        if modifiers.contains(.control) { prefix += "⌃" }
        if modifiers.contains(.option) { prefix += "⌥" }
        if modifiers.contains(.shift) { prefix += "⇧" }
        if modifiers.contains(.command) { prefix += "⌘" }
        return prefix
    }

    private static func glyph(for key: String) -> String {
        switch key {
        case "tab": "⇥"
        case "escape": "⎋"
        case "space": "Space"
        case "return": "↩"
        case "delete": "⌫"
        case "up": "↑"
        case "down": "↓"
        case "left": "←"
        case "right": "→"
        default: key.count == 1 ? key.uppercased() : key.capitalized
        }
    }
}
