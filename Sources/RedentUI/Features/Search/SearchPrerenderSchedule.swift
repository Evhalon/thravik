import Foundation
import RedentKit

/// Waits for typing to pause before asking for the results page, so a search
/// is loaded once per pause rather than once per keystroke. The pause sits just
/// under the gap between keystrokes of steady typing, so the page usually has
/// a head start of several hundred milliseconds by the time return is pressed.
@MainActor
final class SearchPrerenderSchedule {
    static let pause = Duration.milliseconds(180)
    /// One letter is a keystroke, not a question worth sending anywhere.
    private static let minimumQueryLength = 2

    private var pending: Task<Void, Never>?

    /// - Parameter search: the results page return would open, or `nil` when
    ///   return would go somewhere else.
    func queryChanged(_ query: String, search: URL?, on browser: any BrowserControlling) {
        guard let search, query.count >= Self.minimumQueryLength else {
            pending?.cancel()
            pending = nil
            browser.prerender(nil)
            return
        }
        schedule(search, on: browser)
    }

    /// Loads a page return is about to open for a reason stronger than the
    /// letters alone: a site completed from history. A half-typed address is
    /// never one of these — `example.co` is somebody else's site.
    func schedule(_ url: URL, on browser: any BrowserControlling) {
        pending?.cancel()
        pending = Task { [weak browser] in
            try? await Task.sleep(for: Self.pause)
            guard !Task.isCancelled else { return }
            browser?.prerender(url)
        }
    }

    /// A row the user arrowed onto is the clearest signal of all: no pause.
    func prerenderNow(_ url: URL, on browser: any BrowserControlling) {
        pending?.cancel()
        pending = nil
        browser.prerender(url)
    }
}
