import Foundation
import RedentKit
import Testing
import WebKit
@testable import RedentEngine

@Suite("Browsing contexts")
@MainActor
struct BrowsingContextRegistryTests {
    @Test("One store serves every tab sharing a context")
    func storesAreShared() {
        let registry = BrowsingContextRegistry()
        let context = BrowsingContext.ephemeral(UUID())
        #expect(registry.store(for: context) === registry.store(for: context))
    }

    @Test("Separate contexts never share a store")
    func storesAreIsolated() {
        let registry = BrowsingContextRegistry()
        let first = registry.store(for: .ephemeral(UUID()))
        let second = registry.store(for: .ephemeral(UUID()))
        #expect(first !== second)
    }

    @Test("An ephemeral store is released once its last tab is gone")
    func ephemeralIsReleased() {
        let registry = BrowsingContextRegistry()
        let context = BrowsingContext.ephemeral(UUID())
        _ = registry.store(for: context)
        registry.sync([context, context])
        #expect(registry.tabCount(for: context) == 2)

        registry.sync([context])
        #expect(registry.isLoaded(context))

        registry.sync([])
        #expect(registry.tabCount(for: context) == 0)
        #expect(!registry.isLoaded(context))
    }

    @Test("A Container store in use cannot be retired out from under its tabs")
    func removalRequiresNoTabs() async {
        let registry = BrowsingContextRegistry()
        let context = BrowsingContext.container(UUID())
        registry.sync([context])
        await #expect(throws: BrowsingContextError.inUse) {
            try await registry.removeStore(for: context)
        }
    }

    @Test("Default's store is never retired")
    func defaultIsPermanent() async {
        let registry = BrowsingContextRegistry()
        await #expect(throws: BrowsingContextError.notRemovable) {
            try await registry.removeStore(for: .container(BrowserContainer.defaultID))
        }
    }

    @Test("Default Container keeps a stable WebKit profile across launches")
    func defaultStoreUsesPersistentIdentifier() {
        let registry = BrowsingContextRegistry()
        let store = registry.store(for: .container(BrowserContainer.defaultID))
        #expect(store.identifier == BrowserContainer.defaultID)
        #expect(store !== WKWebsiteDataStore.default())
    }
}
