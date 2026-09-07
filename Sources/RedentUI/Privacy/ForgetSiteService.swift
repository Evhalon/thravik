import Foundation
import RedentKit

/// Removes everything Redent holds about one site, and reports exactly what it
/// managed to remove — never a blanket claim of erasure.
///
/// Order matters: live views stop first, so a page cannot write storage back
/// while the deletion is in flight.
@MainActor
public struct ForgetSiteService {
    private let siteData: any SiteDataManaging
    private let history: any HistoryStoring
    private let tabs: any BrowserControlling

    public init(siteData: any SiteDataManaging, history: any HistoryStoring, tabs: any BrowserControlling) {
        self.siteData = siteData
        self.history = history
        self.tabs = tabs
    }

    public func forget(_ origin: Origin) async -> ForgetSiteReport {
        let domain = origin.registrableDomain
        var report = ForgetSiteReport(domain: domain)

        for tab in tabs.tabs where tab.origin?.registrableDomain == domain {
            tab.hibernate()
        }
        // The per-tab path holds the same URLs, so forgetting has to reach it
        // too or the timeline would hand back what was just erased.
        for tab in tabs.tabs { tab.forgetTimeline(domain: domain) }

        for context in siteData.loadedContexts {
            let removed = await siteData.removeRecords(matching: domain, in: context)
            guard !removed.isEmpty else { continue }
            report.removedRecords.append(contentsOf: removed)
            report.clearedContainers += 1
        }

        await history.clear(domain: domain, containerID: nil)
        report.clearedHistory = true
        report.discardedClosedTabs = tabs.forgetClosedTabs(matching: domain)
        return report
    }
}
