import Foundation

/// One key plus modifiers. `key` is a letter, symbol, or a named special key
/// (`tab`, `escape`, `space`, `return`, `delete`, `up`/`down`/`left`/`right`,
/// `f1`…`f12`).
public struct KeyChord: Hashable, Codable, Sendable, Equatable {
    public var key: String
    public var modifiers: KeyModifiers

    public init(key: String, modifiers: KeyModifiers) {
        self.key = key
        self.modifiers = modifiers
    }

    public static func command(_ key: String) -> Self {
        Self(key: key, modifiers: .command)
    }

    public var displayString: String {
        KeyChordDisplay.string(for: self)
    }
}
