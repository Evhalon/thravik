import Testing
@testable import RedentKit

@Suite("Shortcut command-bar ids")
struct ShortcutIDCommandBarTests {
    @Test("Known command descriptors map to a ShortcutID")
    func mapsKnownDescriptors() {
        #expect(ShortcutID(commandDescriptorID: "new-tab") == .newTab)
        #expect(ShortcutID(commandDescriptorID: "reload") == .reload)
        #expect(ShortcutID(commandDescriptorID: "paste-and-search") == nil)
        #expect(ShortcutID(commandDescriptorID: "paste-and-go") == nil)
        #expect(ShortcutID(commandDescriptorID: "sidebar") == .toggleSidebar)
        #expect(ShortcutID(commandDescriptorID: "tidy-tabs") == nil)
    }
}
