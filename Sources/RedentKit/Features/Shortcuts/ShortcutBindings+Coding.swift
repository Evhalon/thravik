import Foundation

extension ShortcutBindings: Codable {
    public init(from decoder: Decoder) throws {
        let container = try decoder.singleValueContainer()
        let raw = try container.decode([String: KeyChord?].self)
        var mapped: [ShortcutID: KeyChord?] = [:]
        for (key, value) in raw {
            guard let id = ShortcutID(rawValue: key) else { continue }
            mapped[id] = value
        }
        overrides = mapped
    }

    public func encode(to encoder: Encoder) throws {
        var container = encoder.singleValueContainer()
        var raw: [String: KeyChord?] = [:]
        for (id, chord) in overrides {
            raw[id.rawValue] = chord
        }
        try container.encode(raw)
    }
}
