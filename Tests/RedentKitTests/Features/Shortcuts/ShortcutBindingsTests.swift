import Foundation
import Testing
@testable import RedentKit

@Suite("Shortcut bindings")
struct ShortcutBindingsTests {
    @Test("Defaults match the previous hard-coded menu shortcuts")
    func defaultsMatchMenus() {
        let bindings = ShortcutBindings()
        for (id, chord) in PreviousMenuShortcuts.all {
            #expect(bindings.chord(for: id) == chord, "\(id.rawValue)")
        }
        #expect(bindings.chord(for: .duplicateTab) == nil)
        #expect(Set(ShortcutBindings.defaults.keys) == Set(PreviousMenuShortcuts.all.keys))
    }

    @Test("Override, clear, and restore leave other chords alone")
    func overrideClearRestore() {
        var bindings = ShortcutBindings()
        #expect(bindings.setChord(.command("e"), for: .newTab) == .applied)
        #expect(bindings.chord(for: .newTab) == .command("e"))
        #expect(bindings.chord(for: .closeTab) == .command("w"))
        #expect(bindings.setChord(nil, for: .newTab) == .applied)
        #expect(bindings.chord(for: .newTab) == nil)
        bindings.restoreDefault(for: .newTab)
        #expect(bindings.chord(for: .newTab) == .command("t"))
        #expect(!bindings.isCustomized(.newTab))
    }

    @Test("Reserved system chords are rejected")
    func reserved() {
        var bindings = ShortcutBindings()
        #expect(bindings.setChord(.command("q"), for: .newTab) == .reserved)
        #expect(bindings.setChord(.command("h"), for: .newTab) == .reserved)
        #expect(bindings.setChord(.command("m"), for: .newTab) == .reserved)
        #expect(bindings.setChord(KeyChord(key: "tab", modifiers: .command), for: .newTab) == .reserved)
        #expect(bindings.setChord(KeyChord(key: "space", modifiers: .command), for: .newTab) == .reserved)
        #expect(bindings.setChord(.command("`"), for: .newTab) == .reserved)
        #expect(bindings.chord(for: .newTab) == .command("t"))
        #expect(bindings.setChord(.command("w"), for: .newTab) == .conflict([.closeTab]))
    }

    @Test("Edit-menu and fixed numbered chords are reserved; no default is")
    func reservedAppChords() {
        var bindings = ShortcutBindings()
        for key in ["c", "v", "x", "a", "z", "1", "9"] {
            #expect(bindings.setChord(.command(key), for: .newTab) == .reserved, "\(key)")
        }
        let space = KeyChord(key: "3", modifiers: [.control, .option])
        #expect(bindings.setChord(space, for: .newTab) == .reserved)
        #expect(bindings.setChord(KeyChord(key: "z", modifiers: [.command, .shift]), for: .newTab) == .reserved)
        #expect(ShortcutBindings.defaults.values.allSatisfy { !ReservedKeyChords.contains($0) })
    }

    @Test("Restoring a default another command took reports the conflict")
    func restoreConflict() {
        var bindings = ShortcutBindings()
        bindings.reassign(.command("w"), to: .newTab)
        #expect(bindings.restoreDefault(for: .closeTab) == .conflict([.newTab]))
        #expect(bindings.chord(for: .closeTab) == nil)
        bindings.reassign(.command("w"), to: .closeTab)
        #expect(bindings.chord(for: .closeTab) == .command("w"))
        #expect(!bindings.isCustomized(.closeTab))
        #expect(bindings.chord(for: .newTab) == nil)
    }

    @Test("The shipped ⌘\\ pair does not conflict while both keep it")
    func sharedDefault() {
        var bindings = ShortcutBindings()
        #expect(bindings.setChord(.command("\\"), for: .fillLogin) == .applied)
        #expect(bindings.restoreDefault(for: .toggleTabStrip) == .applied)
        #expect(bindings.setChord(.command("\\"), for: .newTab) == .conflict([.fillLogin, .toggleTabStrip]))
    }

    @Test("Reassign removes the chord from the other command")
    func reassign() {
        var bindings = ShortcutBindings()
        bindings.reassign(.command("w"), to: .newTab)
        #expect(bindings.chord(for: .newTab) == .command("w"))
        #expect(bindings.chord(for: .closeTab) == nil)
    }
}
