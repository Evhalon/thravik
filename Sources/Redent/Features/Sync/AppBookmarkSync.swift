import Foundation
import RedentKit
import RedentSync
import RedentUI
import RedentVault

@MainActor
final class AppBookmarkSync {
    let router: BookmarkStorageRouter
    let bookmarks: any BookmarkStoring
    private let local = JSONBookmarkStore()
    private var cloud: AppCloudPasswords?
    private var turnstile: SyncTurnstile?
    private var generation = UUID()
    private var accountID: UUID?
    private var store: BookmarkSyncStore?
    private var reset: Task<Void, Never>?
    private var task: Task<Void, Never>?
    private var observer: NSObjectProtocol?
    var note: ((String?) -> Void)?
    var syncAllowed = true

    init() {
        router = BookmarkStorageRouter(local: local)
        bookmarks = BroadcastingBookmarkStore(router)
        observer = NotificationCenter.default.addObserver(forName: .bookmarksDidChange, object: nil, queue: .main) {
            [weak self] notification in
            guard !(notification.object is AppBookmarkSync) else { return }
            Task { @MainActor in self?.schedule() }
        }
    }

    func attach(cloud: AppCloudPasswords, turnstile: SyncTurnstile) {
        self.cloud = cloud
        self.turnstile = turnstile
    }

    func accountChanged(_ session: AccountSession?) {
        task?.cancel()
        let generation = UUID()
        self.generation = generation
        accountID = session?.accountID
        store = nil
        let previous = reset
        reset = Task { [router] in
            await previous?.value
            await router.resetAccountSelection(generation: generation)
            NotificationCenter.default.post(name: .bookmarksDidChange, object: self)
        }
    }

    func prepare() async throws {
        await reset?.value
        guard let cloud, let accountID else { throw SyncError.unauthorized }
        let generation = generation
        if store == nil {
            let base = FileManager.default.urls(for: .applicationSupportDirectory, in: .userDomainMask).first
                ?? FileManager.default.temporaryDirectory
            let bundle = Bundle.main.bundleIdentifier ?? "app.redent.browser.debug"
            let file = base.appendingPathComponent(bundle).appendingPathComponent("bookmarks-\(accountID.uuidString).json")
            store = cloud.makeBookmarkStore(accountID: accountID, bookmarks: JSONBookmarkStore(fileURL: file))
        }
        guard let store else { throw SyncError.unauthorized }
        guard await router.selectAccountStore(store, generation: generation),
              self.generation == generation else { throw SyncError.accountMismatch }
        NotificationCenter.default.post(name: .bookmarksDidChange, object: self)
        schedule()
    }

    func copyLocalBookmarks() async throws {
        guard let store, let accountID else { throw SyncError.unauthorized }
        let pages = await local.all(in: nil)
        let folders = await local.folders(in: nil)
        guard self.accountID == accountID else { throw SyncError.accountMismatch }
        for folder in folders { await store.saveFolder(folder) }
        _ = await store.merge(pages)
        NotificationCenter.default.post(name: .bookmarksDidChange, object: self)
        schedule()
    }

    func schedule() {
        guard syncAllowed, store != nil else { return }
        task?.cancel()
        task = Task { [weak self] in
            do {
                try await Task.sleep(for: .seconds(1))
                guard let self else { return }
                try await self.turnstile?.run { await self.flush() }
            } catch is CancellationError { }
            catch { self?.note?("Bookmark sync is unavailable. Local bookmarks were kept.") }
        }
    }

    func flush() async {
        guard syncAllowed, let store else { return }
        guard await store.writeError == nil else {
            note?("Bookmark could not be saved. Retry the change.")
            return
        }
        let before = await store.all(in: nil)
        let folders = await store.folders(in: nil)
        do {
            let more = try await store.synchronize()
            guard self.store === store else { return }
            let after = await store.all(in: nil)
            let afterFolders = await store.folders(in: nil)
            let changed = after != before || afterFolders != folders
            if changed { NotificationCenter.default.post(name: .bookmarksDidChange, object: self) }
            note?(nil)
            if more { schedule() }
        } catch is CancellationError { }
        catch { note?("Bookmarks could not be synchronized. Local changes were kept.") }
    }
}
