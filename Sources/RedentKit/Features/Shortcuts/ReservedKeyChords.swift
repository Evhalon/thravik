import Foundation

/// Chords Redent must not steal: system keys, the standard Edit menu, and the
/// fixed ⌘1–9 tab and ⌃⌥1–9 Space keys. ⌘W is close-tab and is allowed.
public enum ReservedKeyChords {
    public static let all: Set<KeyChord> = system.union(editing).union(numbered)

    private static let system: Set<KeyChord> = [
        .command("q"),
        .command("h"),
        KeyChord(key: "h", modifiers: [.command, .option]),
        .command("m"),
        KeyChord(key: "f", modifiers: [.command, .control]),
        KeyChord(key: "tab", modifiers: .command),
        KeyChord(key: "space", modifiers: .command),
        .command("`")
    ]

    private static let editing: Set<KeyChord> = [
        .command("x"),
        .command("c"),
        .command("v"),
        .command("a"),
        .command("z"),
        KeyChord(key: "z", modifiers: [.command, .shift])
    ]

    private static let numbered: Set<KeyChord> = Set((1...9).flatMap { number in
        [
            KeyChord.command(String(number)),
            KeyChord(key: String(number), modifiers: [.control, .option])
        ]
    })

    public static func contains(_ chord: KeyChord) -> Bool {
        all.contains(chord)
    }
}
