import Foundation
import Testing
@testable import RedentKit
@testable import RedentUI

@MainActor
@Suite("Sensitive history window model")
struct SensitiveHistoryModelTests {
    private func page(_ raw: String) throws -> URL { try #require(URL(string: raw)) }

    @Test("Never Record History stores the registrable domain, not the host")
    func excludeSiteStoresRegistrableDomain() {
        let model = makeTestBrowserModel()
        model.excludeSiteFromHistory(Origin(scheme: "https", host: "secure.online.chase.com"))
        #expect(model.settings.sensitiveSiteHistoryDomains == ["chase.com"])
    }

    @Test("An edit in one window reaches the others")
    func editsPropagateAcrossWindows() {
        let editor = makeTestBrowserModel()
        let other = makeTestBrowserModel()
        editor.onSensitiveHistoryChanged = { other.adoptSensitiveHistory(from: $0) }
        editor.settings.excludeBankingAndHealthFromHistory = true
        editor.excludeSiteFromHistory(Origin(scheme: "https", host: "bank.example"))
        #expect(other.settings.sensitiveSiteHistoryDomains == ["bank.example"])
        #expect(other.settings.excludeBankingAndHealthFromHistory)
    }

    @Test("Form history skips sensitive and temporary pages")
    func formHistoryTraces() throws {
        let model = makeTestBrowserModel()
        model.settings.sensitiveSiteHistoryDomains = ["chase.com"]
        let tab = InertTab()
        tab.snapshot.url = try page("https://secure.chase.com/pay")
        #expect(!model.retainsBrowsingTraces(for: tab))
        tab.snapshot.url = try page("https://news.example/")
        #expect(model.retainsBrowsingTraces(for: tab))
        tab.snapshot.lifespan = .temporary(sessionID: UUID(), expiresAt: nil, cleanupOnClose: true)
        #expect(!model.retainsBrowsingTraces(for: tab))
    }

    @Test("Unrelated settings changes are not broadcast")
    func unrelatedChangesStayLocal() {
        let model = makeTestBrowserModel()
        var broadcasts = 0
        model.onSensitiveHistoryChanged = { _ in broadcasts += 1 }
        model.settings.blocksTrackers.toggle()
        #expect(broadcasts == 0)
    }
}
