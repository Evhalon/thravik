import WebKit

/// Compiles the bundled ad/tracker list once and caches the result.
/// Compilation is async so tab creation never waits — live views pick the
/// list up when it lands, via `onCompiled`.
@MainActor
final class ContentBlocker {
    private(set) var compiledList: WKContentRuleList?
    private var hasStarted = false
    private let identifier = "app.redent.browser.blocklist.v3"
    var onCompiled: (@MainActor () -> Void)?

    func startCompilingIfNeeded() {
        guard !hasStarted, let json = ContentBlockList.encodedJSON else { return }
        hasStarted = true
        WKContentRuleListStore.default().compileContentRuleList(
            forIdentifier: identifier,
            encodedContentRuleList: json
        ) { [weak self] list, _ in
            Task { @MainActor in
                guard let self, let list else { return }
                self.compiledList = list
                self.onCompiled?()
            }
        }
    }

    static var ruleListJSON: String? { ContentBlockList.encodedJSON }
}
