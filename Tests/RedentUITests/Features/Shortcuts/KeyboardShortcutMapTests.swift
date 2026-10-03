import RedentKit
import SwiftUI
import Testing
@testable import RedentUI

@Suite("Keyboard shortcut map")
struct KeyboardShortcutMapTests {
    @Test("Default chords map to the same SwiftUI keys the menus used")
    func defaultChordsMap() {
        let tab = KeyboardShortcutMap.shortcut(for: .command("t"))
        #expect(tab?.key == KeyEquivalent("t"))
        #expect(tab?.modifiers == .command)

        let reopen = KeyboardShortcutMap.shortcut(
            for: KeyChord(key: "t", modifiers: [.command, .shift])
        )
        #expect(reopen?.key == KeyEquivalent("t"))
        #expect(reopen?.modifiers == [.command, .shift])

        let previous = KeyboardShortcutMap.shortcut(
            for: KeyChord(key: "tab", modifiers: [.control, .shift])
        )
        #expect(previous?.key == .tab)
        #expect(previous?.modifiers == [.control, .shift])

        let findClose = KeyboardShortcutMap.shortcut(
            for: KeyChord(key: "escape", modifiers: [])
        )
        #expect(findClose?.key == .escape)
        #expect(findClose?.modifiers.isEmpty == true)
        #expect(KeyboardShortcutMap.shortcut(for: nil) == nil)
    }

    @Test("Arrows and function keys map to AppKit's special characters")
    func specialKeys() {
        let up = KeyboardShortcutMap.shortcut(for: KeyChord(key: "up", modifiers: .command))
        #expect(up?.key == .upArrow)
        let f5 = KeyboardShortcutMap.shortcut(for: KeyChord(key: "f5", modifiers: []))
        #expect(f5?.key == KeyEquivalent(Character(UnicodeScalar(0xF708) ?? " ")))
        #expect(KeyboardShortcutMap.keyEquivalent("f") == KeyEquivalent("f"))
    }
}
