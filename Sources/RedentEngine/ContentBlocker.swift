import WebKit

/// Compiles the bundled ad/tracker list once and caches the result.
/// Compilation is async so tab creation never waits — live views pick the
/// list up when it lands, via `onCompiled`.
@MainActor
final class ContentBlocker {
    private static var hasScheduledRemoteUpdate = false
    private(set) var compiledLists = [WKContentRuleList]()
    private var hasStarted = false
    private let bundledIdentifier = "app.redent.browser.blocklist.v4"
    var onCompiled: (@MainActor () -> Void)?

    func startCompilingIfNeeded() {
        guard !hasStarted, let json = ContentBlockList.encodedJSON else { return }
        hasStarted = true
        compile(json, identifier: bundledIdentifier)
        restoreCachedLists()
        scheduleRemoteUpdate()
    }

    private func scheduleRemoteUpdate() {
        guard Bundle.main.bundleURL.pathExtension != "xctest",
              !Self.hasScheduledRemoteUpdate else { return }
        Self.hasScheduledRemoteUpdate = true
        Task { await updateBraveLists() }
    }

    private var remoteIdentifiers: [String] {
        AdblockFilterSource.braveDefaults.map { "app.redent.browser.brave.\($0.id).v1" }
    }

    private func restoreCachedLists() {
        for identifier in remoteIdentifiers {
            WKContentRuleListStore.default().lookUpContentRuleList(forIdentifier: identifier) { [weak self] list, _ in
                Task { @MainActor in
                    guard let self, let list,
                          !self.compiledLists.contains(where: { $0.identifier == identifier })
                    else { return }
                    self.compiledLists.append(list)
                    self.onCompiled?()
                }
            }
        }
    }

    private func compile(_ json: String, identifier: String) {
        WKContentRuleListStore.default().compileContentRuleList(
            forIdentifier: identifier,
            encodedContentRuleList: json
        ) { [weak self] list, _ in
            Task { @MainActor in
                guard let self, let list else { return }
                self.compiledLists.removeAll { $0.identifier == identifier }
                self.compiledLists.append(list)
                self.onCompiled?()
            }
        }
    }

    private func updateBraveLists() async {
        let downloader = AdblockListDownloader()
        let parser = AdblockFilterParser()
        await withTaskGroup(of: (String, String)?.self) { group in
            for source in AdblockFilterSource.braveDefaults {
                group.addTask {
                    guard let text = await downloader.fetch(source),
                          let json = parser.encodedRules(from: text) else { return nil }
                    return (source.id, json)
                }
            }
            for await result in group {
                guard let (id, json) = result else { continue }
                compile(json, identifier: "app.redent.browser.brave.\(id).v1")
            }
        }
    }

    static var ruleListJSON: String? { ContentBlockList.encodedJSON }
}
