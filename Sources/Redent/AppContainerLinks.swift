import Foundation
import RedentUI

/// Links other apps hand over — Mail, Messages, anything — once Redent is the
/// system's default browser.
extension AppContainer {
    /// Opens each link in a tab of the window in front. A link that arrives
    /// before any window exists waits rather than being dropped — clicking a
    /// link in Mail is a common way to launch the browser in the first place.
    /// - Returns: whether a window was there to take them.
    @discardableResult
    func openExternal(_ urls: [URL]) -> Bool {
        guard let window = primaryWindow else {
            pendingLinks.append(contentsOf: urls)
            return false
        }
        for url in urls { window.model.open(url, inNewTab: true) }
        return true
    }

    /// Called by the first window to appear.
    func drainPendingLinks() {
        guard !pendingLinks.isEmpty else { return }
        let waiting = pendingLinks
        pendingLinks.removeAll()
        openExternal(waiting)
    }

    /// The offer to become the default browser, raised once per release and
    /// only over a window that is not already showing something modal.
    func offerDefaultBrowserIfNeeded(in window: WindowContainer) async {
        guard window.model.sheet == nil, await defaultBrowser.claimOffer() else { return }
        window.model.sheet = .defaultBrowser
    }
}
