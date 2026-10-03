import Foundation
import Testing
@testable import RedentKit

@Suite("Key chord")
struct KeyChordTests {
    @Test("Display uses macOS modifier order")
    func displayOrder() {
        let chord = KeyChord(key: "t", modifiers: [.command, .shift])
        #expect(chord.displayString == "⇧⌘T")
        #expect(KeyChord(key: "tab", modifiers: [.control, .shift]).displayString == "⌃⇧⇥")
        #expect(KeyChord(key: "escape", modifiers: []).displayString == "⎋")
        #expect(KeyChord.command("w").displayString == "⌘W")
        #expect(KeyChord(key: "up", modifiers: [.command, .option]).displayString == "⌥⌘↑")
        #expect(KeyChord(key: "f5", modifiers: []).displayString == "F5")
    }

    @Test("JSON round-trips key and modifiers")
    func coding() throws {
        let chord = KeyChord(key: "\\", modifiers: [.command, .option])
        let data = try JSONEncoder().encode(chord)
        let restored = try JSONDecoder().decode(KeyChord.self, from: data)
        #expect(restored == chord)
    }
}
