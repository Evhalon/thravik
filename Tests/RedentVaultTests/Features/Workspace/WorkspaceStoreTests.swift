import Foundation
import Testing
@testable import RedentKit
@testable import RedentVault

@Suite("Workspace persistence")
struct WorkspaceStoreTests {
    @Test("Save keeps a recoverable backup and omits temporary tabs")
    func persistence() throws {
        let defaults = try #require(UserDefaults(suiteName: "workspace-store-\(UUID().uuidString)"))
        let store = UserDefaultsWorkspaceStore(defaults: defaults)
        let first = BrowserSession(tabs: [TabSnapshot(title: "First")])
        try store.saveWorkspace(WorkspaceSnapshot(session: first))
        var second = BrowserSession(tabs: [TabSnapshot(title: "Second")])
        var temporary = TabSnapshot(title: "Private")
        temporary.lifespan = .temporary(sessionID: UUID(), expiresAt: nil, cleanupOnClose: true)
        second.tabs.append(temporary)
        try store.saveWorkspace(WorkspaceSnapshot(session: second))
        #expect(try store.loadWorkspace().tabs.map(\.title) == ["Second"])
        #expect(try store.restoreBackup().tabs.map(\.title) == ["First"])
    }

    @Test("Corrupt and newer data are reported")
    func failureModes() throws {
        let defaults = try #require(UserDefaults(suiteName: "workspace-store-\(UUID().uuidString)"))
        let store = UserDefaultsWorkspaceStore(defaults: defaults)
        defaults.set(Data("bad".utf8), forKey: "app.redent.browser.workspace.v2")
        #expect(throws: WorkspaceStoreError.corruptData) { try store.loadWorkspace() }
        let newer = Data("{\"schemaVersion\":99}".utf8)
        defaults.set(newer, forKey: "app.redent.browser.workspace.v2")
        #expect(throws: WorkspaceStoreError.newerSchema(99)) { try store.loadWorkspace() }
    }

    @Test("A cancelled stale save cannot resurrect closed tabs")
    func cancelledSaveIsIgnored() async throws {
        let defaults = try #require(UserDefaults(suiteName: "workspace-store-\(UUID().uuidString)"))
        let store = UserDefaultsWorkspaceStore(defaults: defaults)
        let current = BrowserSession(tabs: [TabSnapshot(title: "Still open")])
        try store.saveWorkspace(WorkspaceSnapshot(session: current))

        let stale = Task {
            withUnsafeCurrentTask { $0?.cancel() }
            let session = BrowserSession(tabs: [TabSnapshot(title: "Already closed")])
            try store.saveWorkspace(WorkspaceSnapshot(session: session))
        }

        await #expect(throws: CancellationError.self) { try await stale.value }
        #expect(try store.loadWorkspace().tabs.map(\.title) == ["Still open"])
    }
}
