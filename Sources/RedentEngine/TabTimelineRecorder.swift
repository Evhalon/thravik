import RedentKit
import WebKit

/// Turns what WebKit reports into the tab's own navigation path.
///
/// The transition comes from the navigation action WebKit was about to take,
/// captured before the load, so a reload or a back/forward traversal is
/// recorded as what it was rather than guessed at afterwards.
@MainActor
final class TabTimelineRecorder {
    private var pending: NavigationTransition?
    private var currentEntryID: UUID?

    func willNavigate(_ type: WKNavigationType) {
        pending = Self.transition(for: type)
    }

    func redirected() {
        pending = .redirect
    }

    func finished(_ tab: WebTab, webView: WKWebView) {
        guard let url = webView.url, Origin(url: url) != nil else { return }
        let transition = tab.snapshot.timeline.entries.isEmpty ? .opened : (pending ?? .link)
        pending = nil
        record(tab, url: url, title: webView.title ?? "", transition: transition, webView: webView)
    }

    /// A same-document move (a router change, an anchor) never fires a load, so
    /// it arrives through URL observation instead.
    func movedWithinDocument(_ tab: WebTab, webView: WKWebView) {
        guard let url = webView.url, Origin(url: url) != nil else { return }
        record(tab, url: url, title: webView.title ?? "", transition: .sameDocument, webView: webView)
    }

    func titleChanged(_ title: String, on tab: WebTab) {
        guard let id = currentEntryID else { return }
        tab.snapshot.timeline.updateTitle(title, for: id)
    }

    private func record(
        _ tab: WebTab, url: URL, title: String,
        transition: NavigationTransition, webView: WKWebView
    ) {
        guard let entry = tab.snapshot.timeline.record(url: url, title: title, transition: transition)
        else { return }
        currentEntryID = entry.id
        // The live item is what makes a real restore possible; without it the
        // entry can only be reloaded by URL, and it already says so.
        if let item = webView.backForwardList.currentItem {
            tab.liveItems[entry.id] = item
        }
    }

    private static func transition(for type: WKNavigationType) -> NavigationTransition {
        switch type {
        case .linkActivated: .link
        case .formSubmitted, .formResubmitted: .formSubmitted
        case .backForward: .traversal
        case .reload: .reload
        case .other: .link
        @unknown default: .link
        }
    }
}
