import Foundation
import RedentKit
import Testing
@testable import Redent

@Suite("Primary window workspace")
struct PrimaryWorkspaceTests {
    private struct UnreadableWorkspace: Error {}

    // Regression: rebuilding the primary window reused the launch snapshot, so
    // tabs closed since launch came back and were saved again.
    @Test("A rebuilt primary window starts from the session it was released with")
    func rebuildKeepsClosedTabsClosed() {
        let kept = TabSnapshot(url: URL(string: "https://kept.example"))
        let closed = TabSnapshot(url: URL(string: "https://closed.example"))
        var workspace = PrimaryWorkspace(restored: .success(BrowserSession(tabs: [kept, closed])))

        workspace.windowReleased(with: BrowserSession(tabs: [kept], selectedTabID: kept.id))

        #expect(workspace.session.tabs.map(\.id) == [kept.id])
    }

    @Test("A failed restore is reported until the window has a session of its own")
    func failureClearsAfterRelease() {
        var workspace = PrimaryWorkspace(restored: .failure(UnreadableWorkspace()))
        #expect(workspace.restoreFailed)
        #expect(workspace.session.tabs.isEmpty)

        workspace.windowReleased(with: BrowserSession())

        #expect(!workspace.restoreFailed)
    }
}
