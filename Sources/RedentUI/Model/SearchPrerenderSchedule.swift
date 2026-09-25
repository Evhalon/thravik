import Foundation
import RedentKit

/// Waits for typing to pause before asking for the results page, so a search
/// is loaded once per pause rather than once per keystroke.
@MainActor
final class SearchPrerenderSchedule {
    static let pause = Duration.milliseconds(300)
    /// One letter is a keystroke, not a question worth sending anywhere.
    private static let minimumQueryLength = 2

    private var pending: Task<Void, Never>?

    /// - Parameter search: the results page return would open, or `nil` when
    ///   return would go somewhere else.
    func queryChanged(_ query: String, search: URL?, on browser: any BrowserControlling) {
        pending?.cancel()
        guard let search, query.count >= Self.minimumQueryLength else {
            pending = nil
            browser.prerender(nil)
            return
        }
        pending = Task { [weak browser] in
            try? await Task.sleep(for: Self.pause)
            guard !Task.isCancelled else { return }
            browser?.prerender(search)
        }
    }
}
