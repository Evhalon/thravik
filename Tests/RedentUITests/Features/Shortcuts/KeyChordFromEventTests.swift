import AppKit
import RedentKit
import Testing
@testable import RedentUI

@Suite("Shortcut recorder key parsing")
struct KeyChordFromEventTests {
    @Test("Keys that type text need ⌘ or ⌃")
    func typingKeysNeedModifier() {
        #expect(KeyChordFromEvent.make(from: key(17, "t", [])) == nil)
        #expect(KeyChordFromEvent.make(from: key(17, "T", .shift)) == nil)
        #expect(KeyChordFromEvent.make(from: key(14, "´", .option)) == nil)
        #expect(KeyChordFromEvent.make(from: key(36, "\r", [])) == nil)
        #expect(KeyChordFromEvent.make(from: key(49, " ", [])) == nil)
        #expect(KeyChordFromEvent.make(from: key(48, "\t", .shift)) == nil)
        #expect(KeyChordFromEvent.make(from: key(48, "\t", [.control, .shift])) == KeyChord(
            key: "tab", modifiers: [.control, .shift]
        ))
    }

    @Test("Arrows record by name; function keys may stand alone")
    func specialKeys() {
        #expect(KeyChordFromEvent.make(from: key(126, "\u{F700}", [.command, .option])) == KeyChord(
            key: "up", modifiers: [.command, .option]
        ))
        #expect(KeyChordFromEvent.make(from: key(126, "\u{F700}", [])) == nil)
        #expect(KeyChordFromEvent.make(from: key(96, "\u{F708}", [])) == KeyChord(key: "f5", modifiers: []))
        #expect(KeyChordFromEvent.make(from: key(115, "\u{F729}", .command)) == nil)
    }

    @Test("Escape cancels and Delete clears instead of recording")
    func controlKeys() {
        #expect(KeyChordFromEvent.make(from: key(53, "\u{1B}", .command)) == nil)
        #expect(KeyChordFromEvent.isEscape(key(53, "\u{1B}", [])))
        #expect(KeyChordFromEvent.isClear(key(51, "\u{7F}", [])))
    }

    private func key(_ code: UInt16, _ characters: String, _ flags: NSEvent.ModifierFlags) -> NSEvent {
        NSEvent.keyEvent(
            with: .keyDown, location: .zero, modifierFlags: flags, timestamp: 0,
            windowNumber: 0, context: nil, characters: characters,
            charactersIgnoringModifiers: characters, isARepeat: false, keyCode: code
        ) ?? NSEvent()
    }
}
