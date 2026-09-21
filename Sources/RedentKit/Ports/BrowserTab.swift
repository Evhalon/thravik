import Foundation

@MainActor
public protocol BrowserTab: AnyObject {
    var id: UUID { get }
    var snapshot: TabSnapshot { get }
    var title: String { get }
    var url: URL? { get }
    var pageTrustIssue: PageTrustIssue? { get }
    var progress: Double { get }
    var isLoading: Bool { get }
    var canGoBack: Bool { get }
    var canGoForward: Bool { get }
    var isHibernated: Bool { get }
    var isPinned: Bool { get }
    var origin: Origin? { get }
    /// Page zoom, on `PageZoom`'s ladder.
    var zoom: Double { get }
    func setZoom(_ level: Double)
    func load(_ url: URL)
    /// Reloads after the user explicitly accepts an invalid TLS certificate.
    func proceedThroughInvalidCertificate()
    func goBack()
    func goForward()
    func reload()
    /// Reloads past the cache, the way ⇧⌘R does in every other browser.
    func reloadIgnoringCache()
    func stopLoading()
    /// Paints every match for `query` and steps the active one on.
    /// - Returns: how many matches the page holds, and which one is active.
    func findInPage(_ query: String, forward: Bool) async -> FindMatches
    /// Drops the highlights `findInPage` left behind.
    func clearFindHighlight()
    /// Puts the page on the system print panel.
    func printPage()
    func fillCredential(username: String, password: String) async
    func fillOTPCode(_ code: String) async
    func hibernate()
    /// Some frame in the page is playing sound, muted by Redent or not.
    var isPlayingAudio: Bool { get }
    var isMuted: Bool { get }
    func setMuted(_ muted: Bool)
    /// The tab's level, 0…1, scaling whatever the page itself plays at.
    var volume: Double { get }
    func setVolume(_ level: Double)
    /// The page's article is laid over it in Reader.
    var isReaderActive: Bool { get }
    /// Opens Reader, or closes it. A page with no article stays as it is.
    func toggleReader() async
    /// The tab's own navigation path, oldest first.
    var timeline: [NavigationEntry] { get }
    /// Returns to an earlier entry, live where possible and by URL otherwise.
    func travel(to entry: NavigationEntry)
    /// Drops timeline entries for a forgotten site.
    func forgetTimeline(domain: String)
}

/// Defaults for the capabilities a tab may simply not have — a stand-in in a
/// test, or a page the engine cannot search. Each is a no-op, never a crash.
public extension BrowserTab {
    var pageTrustIssue: PageTrustIssue? { nil }
    func proceedThroughInvalidCertificate() {}
    func reloadIgnoringCache() { reload() }
    func findInPage(_ query: String, forward: Bool) async -> FindMatches { .empty }
    func clearFindHighlight() {}
    func printPage() {}
    var isPlayingAudio: Bool { false }
    var isMuted: Bool { false }
    func setMuted(_ muted: Bool) {}
    var volume: Double { 1 }
    func setVolume(_ level: Double) {}
    var isReaderActive: Bool { false }
    func toggleReader() async {}
}
