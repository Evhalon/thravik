import Foundation
@testable import Redent
import RedentKit
import Testing

@MainActor
struct WorkspaceBootstrapTests {
    @Test func readsOtherMacBeforePublishingFirstWorkspace() async {
        let remoteSpace = BrowserSpace(name: "Other Mac")
        let localSpace = BrowserSpace(name: "This Mac")
        let local = BrowserSession(spaces: [localSpace])
        let store = BootstrapWorkspaceStore(session: BrowserSession(spaces: [remoteSpace]))
        let sync = AppWorkspaceSync(makeStore: { _ in store })
        sync.accountChanged(session())
        sync.note(local)
        sync.apply = { snapshot in
            sync.note(WorkspaceSyncMerge.apply(local: local, snapshot: snapshot).session)
        }
        await sync.flush()
        #expect(store.events == ["pull", "publish", "pull"])
        #expect(store.published.first?.spaces.contains { $0.id == remoteSpace.id } == true)
        #expect(store.published.first?.spaces.contains { $0.id == localSpace.id } == true)
    }

    @Test func failedBootstrapKeepsPendingChangesForRetry() async {
        let local = BrowserSession(spaces: [BrowserSpace(name: "Offline changes")])
        let store = BootstrapWorkspaceStore(session: BrowserSession())
        store.failPull = true
        let sync = AppWorkspaceSync(makeStore: { _ in store })
        sync.accountChanged(session())
        sync.note(local)
        await sync.flush()
        #expect(store.published.isEmpty)
        #expect(sync.model.message != nil)
        store.failPull = false
        await sync.flush()
        #expect(store.published == [local])
        #expect(sync.model.message == nil)
    }

    @Test func waitsForAllBootstrapPagesBeforePublishing() async {
        let store = BootstrapWorkspaceStore(session: BrowserSession())
        store.hasMore = true
        let sync = AppWorkspaceSync(makeStore: { _ in store })
        sync.accountChanged(session())
        sync.note(BrowserSession())
        await sync.flush()
        #expect(store.events == ["pull"])
        store.hasMore = false
        await sync.flush()
        #expect(store.events == ["pull", "pull", "publish", "pull"])
    }

    @Test func accountSwitchDoesNotApplyOldResponse() async {
        let store = BootstrapWorkspaceStore(session: BrowserSession())
        let sync = AppWorkspaceSync(makeStore: { _ in store })
        var applications = 0
        sync.apply = { _ in applications += 1 }
        sync.accountChanged(session())
        store.onPull = { sync.accountChanged(session()) }
        await sync.flush()
        store.onPull = nil
        #expect(applications == 0)
        #expect(store.published.isEmpty)
    }

    @Test func managedPolicyStopsEveryPullAndPublish() async {
        let store = BootstrapWorkspaceStore(session: BrowserSession())
        let sync = AppWorkspaceSync(makeStore: { _ in store })
        sync.syncAllowed = false
        sync.accountChanged(session())
        sync.note(BrowserSession())
        await sync.flush()
        #expect(store.events.isEmpty)
    }

    private func session() -> AccountSession {
        AccountSession(accountID: UUID(), accessToken: "test", refreshToken: "test",
                       expiresAt: .distantFuture)
    }
}

@MainActor
private final class BootstrapWorkspaceStore: WorkspaceSyncing {
    var events: [String] = []
    var published: [BrowserSession] = []
    var failPull = false
    var hasMore = false
    var onPull: (@MainActor () -> Void)?
    private let snapshot: WorkspaceSyncSnapshot

    init(session: BrowserSession) {
        snapshot = WorkspaceSyncSnapshot(catalog: SyncSpaceCatalog(session: session),
                                         deviceTabs: [], localDeviceID: UUID())
    }

    func publish(_ session: BrowserSession) async throws {
        events.append("publish")
        published.append(session)
    }

    func synchronize() async throws -> (WorkspaceSyncSnapshot, Bool) {
        events.append("pull")
        if failPull { throw SyncError.unavailable }
        onPull?()
        return (snapshot, hasMore)
    }
}
