import Foundation
import RedentKit

@MainActor
final class FindSession {
    struct Context: Equatable {
        let tabID: UUID?
        let url: URL?
        let isLoading: Bool

        @MainActor init(tab: (any BrowserTab)?) {
            tabID = tab?.id
            url = tab?.url
            isLoading = tab?.isLoading ?? false
        }
    }

    struct Request {
        var query: String
        var forward = true
        var delay: Duration?
        var seedsSelection = false
    }

    var context: Context?
    private(set) var task: Task<Void, Never>?
    private var generation: UInt = 0
    private var activeQuery: String?
    private var isDebouncing = false

    func invalidate() {
        generation &+= 1
        task?.cancel()
        isDebouncing = false
    }

    func search(_ request: Request, on tab: any BrowserTab, chrome: PageChromeModel,
                isCurrent: @escaping @MainActor () -> Bool) {
        let replacesQuery = activeQuery != request.query
        if replacesQuery || request.delay != nil || isDebouncing || request.seedsSelection {
            invalidate()
            chrome.findMatches = nil
        }
        activeQuery = request.query
        guard !request.query.isEmpty || request.seedsSelection else {
            tab.clearFindHighlight()
            return
        }
        let previous = task
        let version = generation
        isDebouncing = request.delay != nil
        task = Task { [weak self, weak chrome] in
            if let delay = request.delay { try? await Task.sleep(for: delay) }
            guard !Task.isCancelled else { return }
            // WebKit work already submitted cannot be cancelled; each explicit step must wait its turn.
            await previous?.value
            guard !Task.isCancelled, let self, let chrome,
                  self.generation == version, isCurrent() else { return }
            self.isDebouncing = false
            await self.perform(request, on: tab, chrome: chrome, version: version, isCurrent: isCurrent)
        }
    }

    private func perform(_ request: Request, on tab: any BrowserTab, chrome: PageChromeModel,
                         version: UInt, isCurrent: @MainActor () -> Bool) async {
        var query = request.query
        if request.seedsSelection {
            let selection = await tab.selectedPageText()
            guard !Task.isCancelled, generation == version,
                  chrome.findQuery == request.query, isCurrent() else { return }
            if let selection, !selection.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty {
                query = selection
                chrome.findQuery = query
                activeQuery = query
            }
            chrome.isCapturingFindSelection = false
            chrome.findFocusEpoch &+= 1
        }
        guard !query.isEmpty else { return }
        let matches = await tab.findInPage(query, forward: request.forward)
        guard !Task.isCancelled, generation == version, chrome.findQuery == query, isCurrent() else { return }
        chrome.findMatches = matches
    }
}
