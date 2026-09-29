import Testing
@testable import RedentUI

@MainActor
@Suite("Titlebar double-click")
struct TitlebarDoubleClickTests {
    @Test("System preference maps to the matching window action")
    func mapping() {
        #expect(TitlebarDragRegion.action(for: "None") == .none)
        #expect(TitlebarDragRegion.action(for: "Minimize") == .minimize)
        #expect(TitlebarDragRegion.action(for: "Maximize") == .zoom)
        #expect(TitlebarDragRegion.action(for: "Fill") == .zoom)
        #expect(TitlebarDragRegion.action(for: nil) == .zoom)
    }
}
