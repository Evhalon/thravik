import Foundation

/// Default chords plus optional user overrides. A `nil` override removes the key.
public struct ShortcutBindings: Hashable, Sendable, Equatable {
    public var overrides: [ShortcutID: KeyChord?]

    public init(overrides: [ShortcutID: KeyChord?] = [:]) {
        self.overrides = overrides
    }

    public func chord(for id: ShortcutID) -> KeyChord? {
        if let override = overrides[id] { return override }
        return Self.defaults[id]
    }

    public func isCustomized(_ id: ShortcutID) -> Bool {
        overrides.keys.contains(id)
    }

    /// Refuses to silently double-bind a chord another command took meanwhile.
    @discardableResult
    public mutating func restoreDefault(for id: ShortcutID) -> ShortcutChange {
        if let chord = Self.defaults[id] {
            let others = conflicts(with: chord, excluding: id)
            if !others.isEmpty { return .conflict(others) }
        }
        overrides.removeValue(forKey: id)
        return .applied
    }

    public mutating func restoreAllDefaults() {
        overrides.removeAll()
    }

    /// Commands that shipped sharing a default (Fill Login and Show Tabs on ⌘\,
    /// told apart by menu enablement) don't conflict while both keep it.
    public func conflicts(with chord: KeyChord, excluding id: ShortcutID) -> [ShortcutID] {
        ShortcutID.allCases.filter { other in
            guard other != id, self.chord(for: other) == chord else { return false }
            return !(Self.defaults[id] == chord && Self.defaults[other] == chord)
        }
    }

    public mutating func setChord(_ chord: KeyChord?, for id: ShortcutID) -> ShortcutChange {
        if let chord, ReservedKeyChords.contains(chord) { return .reserved }
        if let chord {
            let others = conflicts(with: chord, excluding: id)
            if !others.isEmpty { return .conflict(others) }
        }
        apply(chord, to: id)
        return .applied
    }

    public mutating func reassign(_ chord: KeyChord, to id: ShortcutID) {
        for other in conflicts(with: chord, excluding: id) {
            apply(nil, to: other)
        }
        apply(chord, to: id)
    }

    private mutating func apply(_ chord: KeyChord?, to id: ShortcutID) {
        if chord == Self.defaults[id] {
            overrides.removeValue(forKey: id)
            return
        }
        overrides[id] = chord
    }
}
