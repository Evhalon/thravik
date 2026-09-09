import Foundation

@MainActor
public protocol BrowserTab: AnyObject {
    var id: UUID { get }
    var snapshot: TabSnapshot { get }
    var title: String { get }
    var url: URL? { get }
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
    func goBack()
    func goForward()
    func reload()
    func stopLoading()
    func fillCredential(username: String, password: String) async
    func fillOTPCode(_ code: String) async
    func hibernate()
    /// The tab's own navigation path, oldest first.
    var timeline: [NavigationEntry] { get }
    /// Returns to an earlier entry, live where possible and by URL otherwise.
    func travel(to entry: NavigationEntry)
    /// Drops timeline entries for a forgotten site.
    func forgetTimeline(domain: String)
}
