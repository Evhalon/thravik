import Foundation
import RedentKit
import Testing
@testable import RedentUI

@Suite("Forget site")
@MainActor
struct ForgetSiteTests {
    @Test("Only the records the engine attributes to the domain are removed")
    func exactRecordScope() async {
        let data = FakeSiteData(records: [
            .init(displayName: "example.com", dataTypes: ["cookies"]),
            .init(displayName: "evil-example.com", dataTypes: ["cookies"]),
            .init(displayName: "other.com", dataTypes: ["cookies"])
        ])
        let report = await service(data: data).forget(Origin(scheme: "https", host: "www.example.com"))

        #expect(report.removedRecords == ["example.com"])
        #expect(data.remaining.map(\.displayName).sorted() == ["evil-example.com", "other.com"])
    }

    @Test("Every Container holding the site is cleared, and counted")
    func acrossContainers() async {
        let data = FakeSiteData(
            records: [.init(displayName: "example.com", dataTypes: ["cookies"])],
            contexts: [.container(UUID()), .container(UUID())]
        )
        let report = await service(data: data).forget(Origin(scheme: "https", host: "example.com"))
        #expect(report.clearedContainers == 2)
    }

    @Test("Reopen records for the site are discarded, and reported")
    func closedTabsDiscarded() async {
        let tabs = FakeBrowser(forgettable: 3)
        let report = await service(data: FakeSiteData(), tabs: tabs)
            .forget(Origin(scheme: "https", host: "example.com"))
        #expect(report.discardedClosedTabs == 3)
        #expect(tabs.forgottenDomains == ["example.com"])
    }

    @Test("Finding nothing is reported as nothing, not as a successful erasure")
    func nothingFound() async {
        let report = await service(data: FakeSiteData()).forget(Origin(scheme: "https", host: "quiet.com"))
        #expect(report.removedRecords.isEmpty)
        #expect(report.clearedContainers == 0)
        #expect(report.retained.contains("Saved passwords"))
    }

    private func service(data: FakeSiteData, tabs: FakeBrowser = FakeBrowser()) -> ForgetSiteService {
        ForgetSiteService(siteData: data, history: SilentHistory(), tabs: tabs)
    }
}
