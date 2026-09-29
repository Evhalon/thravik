import Foundation
import RedentKit
import WebKit

/// Mirrors one Container's session cookies into durable storage, and puts them
/// back into its store at launch before any page asks for them.
///
/// WebKit reports only the first cookie change after an observer registers,
/// so its notice alone saved one change per launch and lost every later
/// sign-in. Page loads and the app's way out trigger saves as well.
@MainActor
final class SessionCookieKeeper: NSObject, WKHTTPCookieStoreObserver {
    private static let saveDelay = Duration.seconds(1)

    private let cookieStore: WKHTTPCookieStore
    private let storage: any SessionCookieStoring
    private let container: UUID
    private var pendingSave: Task<Void, Never>?
    /// What the Keychain already holds. A search page rewrites dozens of
    /// persistent cookies per load; none of that is worth a Keychain write.
    private var lastSaved: Set<StoredCookie> = []
    /// Finishes once the saved cookies are back in the store; a first load
    /// waits on it so the page sees the user as still signed in.
    private(set) var restoration: Task<Void, Never>?

    init(cookieStore: WKHTTPCookieStore, storage: any SessionCookieStoring, container: UUID) {
        self.cookieStore = cookieStore
        self.storage = storage
        self.container = container
        super.init()
        restoration = Task { [weak self] in await self?.restore() }
    }

    nonisolated func cookiesDidChange(in cookieStore: WKHTTPCookieStore) {
        MainActor.assumeIsolated { scheduleSave() }
    }

    /// A page finished loading: the moment a sign-in's cookies have settled.
    func pageDidLoad() {
        guard restoration == nil else { return }
        scheduleSave()
    }

    /// Writes now. Skipped until the restore is done, since saving the store
    /// before its saved cookies are back would erase them.
    func flush() async {
        guard restoration == nil else { return }
        pendingSave?.cancel()
        pendingSave = nil
        await save()
    }

    func forget() async {
        pendingSave?.cancel()
        cookieStore.remove(self)
        await storage.remove(container: container)
    }

    private func restore() async {
        let saved = await storage.load(container: container)
        lastSaved = Set(saved)
        // Each set is a round trip to the network process, and the first page
        // load waits on all of them: overlap them rather than queue them.
        let store = cookieStore
        let pending = saved.compactMap(\.httpCookie).map { cookie in
            Task { await store.setCookie(cookie) }
        }
        for task in pending { await task.value }
        // Observing only now keeps the restore itself from triggering a save.
        cookieStore.add(self)
        restoration = nil
        // A page may have signed in while the restore was still running.
        scheduleSave()
    }

    private func scheduleSave() {
        pendingSave?.cancel()
        pendingSave = Task { [weak self] in
            try? await Task.sleep(for: Self.saveDelay)
            guard !Task.isCancelled else { return }
            await self?.save()
        }
    }

    private func save() async {
        let cookies = await cookieStore.allCookies().compactMap { StoredCookie($0) }
        let current = Set(cookies)
        guard current != lastSaved else { return }
        lastSaved = current
        await storage.save(cookies, container: container)
    }
}
