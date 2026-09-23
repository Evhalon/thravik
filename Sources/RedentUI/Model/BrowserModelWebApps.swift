import Foundation
import RedentKit

/// Sites kept as apps. Each opens in a window of its own, browsing in the
/// Space it was saved from — so it keeps that Space's logins.
extension BrowserModel {
    func reloadWebApps() async {
        guard let webAppStore else { return }
        // A read that overtook a save would drop the app just saved.
        await webAppWrite?.value
        webApps = await webAppStore.all().sorted { $0.name.localizedCaseInsensitiveCompare($1.name) == .orderedAscending }
        refreshCommandContext()
    }

    /// Saves the site in front as an app and hands the page to the app's
    /// window, the way "Open as App" works elsewhere. A site already saved
    /// just opens.
    func saveCurrentSiteAsApp() throws {
        guard !isPrivate, let tab = selectedTab, let url = tab.url else { throw CommandActionError.unavailable }
        if let existing = webApps.first(where: { $0.isSameSite(as: url) }) { return try openWebApp(existing.id) }
        guard let app = WebApp(page: url, title: tab.title, faviconData: tab.snapshot.faviconData,
                               spaceID: currentSpaceID) else { throw CommandActionError.unavailable }
        webApps.append(app)
        write { await $0.save(app) }
        guard let windowDirectory else { return }
        windowDirectory.open(app, at: url, in: currentSpace)
        tabs.close(tab.id)
    }

    func openWebApp(_ id: UUID) throws {
        guard let app = webApps.first(where: { $0.id == id }) else { throw CommandActionError.unavailable }
        guard let windowDirectory else {
            tabs.newTab(url: app.url)
            return
        }
        let space = tabs.session.spaces.first { $0.id == app.spaceID }
        windowDirectory.open(app, at: nil, in: space)
    }

    func removeWebApp(_ id: UUID) {
        webApps.removeAll { $0.id == id }
        write { await $0.delete(id) }
    }

    /// Writes land in the order they were asked for.
    private func write(_ change: @escaping @Sendable (any WebAppStoring) async -> Void) {
        guard let webAppStore else { return }
        let previous = webAppWrite
        webAppWrite = Task {
            await previous?.value
            await change(webAppStore)
        }
    }
}
