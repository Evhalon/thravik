import Foundation
import WebKit

/// Compiles the bundled ad/tracker list once and caches the result.
/// Compilation is async so tab creation never waits — live views pick the
/// list up when it lands, via `onCompiled`.
@MainActor
final class ContentBlocker {
    private static var hasScheduledRemoteUpdate = false
    /// Lists compiled by the old converter, which turned modifiers it did not
    /// understand into plain blocks. Left on disk they would come back.
    private static let retiredIdentifiers = ["app.redent.browser.blocklist.v4"]
        + AdblockFilterSource.braveDefaults.map { "app.redent.browser.brave.\($0.id).v1" }
    /// Filter lists move daily at most. Fetching and recompiling five of them
    /// on every launch cost seconds of CPU right when the first pages load.
    private static let remoteRefreshInterval: TimeInterval = 24 * 60 * 60
    private static let lastRefreshKey = "app.redent.adblock.v2.refreshedAt"

    private(set) var compiledLists = [WKContentRuleList]()
    private var hasStarted = false
    private var isNotifying = false
    private let bundledIdentifier = "app.redent.browser.blocklist.v5"
    var onCompiled: (@MainActor () -> Void)?

    func startCompilingIfNeeded() {
        guard !hasStarted, let json = ContentBlockList.encodedJSON else { return }
        hasStarted = true
        compile(json, identifier: bundledIdentifier)
        if let quiet = QuietRuleList.encodedJSON { compile(quiet, identifier: QuietRuleList.identifier) }
        restoreCachedLists()
        retireOldLists()
        if Self.isRemoteRefreshDue { scheduleRemoteUpdate() }
    }

    /// The compiled lists a view built with `options` carries.
    func lists(for options: PageContentOptions) -> [WKContentRuleList] {
        compiledLists.filter { list in
            list.identifier == QuietRuleList.identifier ? options.quietsPages : options.blocksTrackers
        }
    }

    private static var isRemoteRefreshDue: Bool {
        let last = UserDefaults.standard.double(forKey: lastRefreshKey)
        return Date().timeIntervalSince1970 - last > remoteRefreshInterval
    }

    private func scheduleRemoteUpdate() {
        guard Bundle.main.bundleURL.pathExtension != "xctest",
              !Self.hasScheduledRemoteUpdate else { return }
        Self.hasScheduledRemoteUpdate = true
        Task(priority: .utility) { await updateBraveLists() }
    }

    private var remoteIdentifiers: [String] {
        AdblockFilterSource.braveDefaults.map(Self.remoteIdentifier)
    }

    private static func remoteIdentifier(_ source: AdblockFilterSource) -> String {
        "app.redent.browser.brave.\(source.id).v2"
    }

    private func restoreCachedLists() {
        for identifier in remoteIdentifiers {
            WKContentRuleListStore.default().lookUpContentRuleList(forIdentifier: identifier) { [weak self] list, _ in
                Task { @MainActor in
                    guard let self else { return }
                    // A list missing from the store cannot wait a day for the refresh.
                    guard let list else { return self.scheduleRemoteUpdate() }
                    self.adopt(list)
                }
            }
        }
    }

    private func retireOldLists() {
        for identifier in Self.retiredIdentifiers {
            WKContentRuleListStore.default().removeContentRuleList(forIdentifier: identifier) { _ in }
        }
    }

    private func compile(_ json: String, identifier: String) {
        WKContentRuleListStore.default().compileContentRuleList(
            forIdentifier: identifier,
            encodedContentRuleList: json
        ) { [weak self] list, _ in
            Task { @MainActor in
                guard let self, let list else { return }
                self.adopt(list)
            }
        }
    }

    private func adopt(_ list: WKContentRuleList) {
        compiledLists.removeAll { $0.identifier == list.identifier }
        compiledLists.append(list)
        notifyCompiled()
    }

    /// Lists land one by one at launch. Swapping them into every live view
    /// makes each page re-evaluate, so arrivals close together share one swap.
    private func notifyCompiled() {
        guard !isNotifying else { return }
        isNotifying = true
        Task { @MainActor [weak self] in
            try? await Task.sleep(for: .milliseconds(150))
            guard let self else { return }
            self.isNotifying = false
            self.onCompiled?()
        }
    }

    private func updateBraveLists() async {
        let downloader = AdblockListDownloader()
        let parser = AdblockFilterParser()
        var refreshed = true
        await withTaskGroup(of: (AdblockFilterSource, String)?.self) { group in
            for source in AdblockFilterSource.braveDefaults {
                group.addTask {
                    guard let text = await downloader.fetch(source),
                          let json = parser.encodedRules(from: text) else { return nil }
                    return (source, json)
                }
            }
            var converted = 0
            for await result in group {
                guard let (source, json) = result else { continue }
                converted += 1
                compile(json, identifier: Self.remoteIdentifier(source))
            }
            refreshed = converted == AdblockFilterSource.braveDefaults.count
        }
        guard refreshed else { return }
        UserDefaults.standard.set(Date().timeIntervalSince1970, forKey: Self.lastRefreshKey)
    }

    static var ruleListJSON: String? { ContentBlockList.encodedJSON }
}
