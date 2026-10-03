import RedentUI

extension AppPasswordStorage {
    func connect(_ workspace: AppWorkspaceSync, bookmarks: AppBookmarkSync) {
        guard let cloud else { return }
        workspace.attach(cloud: cloud, turnstile: turnstile)
        bookmarks.attach(cloud: cloud, turnstile: turnstile)
        bookmarks.note = { [weak workspace] in workspace?.model.note($0) }
        workspace.refreshSession = { [weak account] in await account?.refreshIfNeeded() }
        afterSync = { [weak workspace, weak bookmarks] in
            await workspace?.flush()
            await bookmarks?.flush()
        }
        onAccount = { [weak workspace, weak bookmarks] session in
            workspace?.accountChanged(session)
            bookmarks?.accountChanged(session)
        }
        prepareBookmarks = { [weak bookmarks] in try await bookmarks?.prepare() }
        model.copyLocalBookmarks = { [weak bookmarks] in try await bookmarks?.copyLocalBookmarks() }
        onVaultReady = { [weak workspace] in workspace?.schedule(forced: true) }
    }
}
