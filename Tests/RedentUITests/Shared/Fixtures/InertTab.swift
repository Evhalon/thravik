import Foundation
import RedentKit

@MainActor
final class InertTab: BrowserTab {
    let id = UUID()
    var snapshot = TabSnapshot()
    var title = ""
    var url: URL?
    var progress: Double = 0
    var isLoading = false
    var canGoBack = false
    var canGoForward = false
    var isHibernated = true
    var isPinned = false
    var canFloatVideo = false
    var isVideoFloating = false
    var origin: Origin? { nil }
    var zoom: Double = PageZoom.identity
    var findResult: FindMatches = .empty
    var selectedText: String?
    var findHandler: (@MainActor (String, Bool) async -> FindMatches)?
    var selectionHandler: (@MainActor () async -> String?)?
    private(set) var findQueries: [String] = []
    private(set) var findDirections: [Bool] = []
    private(set) var findHighlightClears = 0
    private(set) var pageFocusRequests = 0

    func setZoom(_ level: Double) { zoom = PageZoom.clamped(level) }
    func load(_ url: URL) {}
    func goBack() {}
    func goForward() {}
    func reload() {}
    func stopLoading() {}

    func findInPage(_ query: String, forward: Bool) async -> FindMatches {
        findQueries.append(query)
        findDirections.append(forward)
        if let findHandler { return await findHandler(query, forward) }
        return findResult
    }

    func selectedPageText() async -> String? {
        if let selectionHandler { return await selectionHandler() }
        return selectedText
    }

    func focusPage() { pageFocusRequests += 1 }
    func clearFindHighlight() { findHighlightClears += 1 }
    func fillCredential(username: String, password: String) async {}
    func fillOTPCode(_ code: String) async {}
    func hibernate() {}
    var timeline: [NavigationEntry] { [] }
    func travel(to entry: NavigationEntry) {}
    func forgetTimeline(domain: String) {}
}
