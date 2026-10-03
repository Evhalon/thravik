import Foundation
import RedentKit
import Testing
@testable import RedentEngine

@MainActor
@Suite("Tab timeline recorder")
struct TabTimelineRecorderTests {
    private func page(_ raw: String) throws -> URL { try #require(URL(string: raw)) }

    @Test("Sensitive pages leave no timeline entry")
    func skipsSensitivePage() throws {
        let tab = WebTab(snapshot: TabSnapshot(), controller: nil)
        let recorder = TabTimelineRecorder()
        recorder.apply(policy: SensitiveSitePolicy(customDomains: ["chase.com"]))
        recorder.record(tab, url: try page("https://news.example/a"), title: "News", transition: .opened, item: nil)
        recorder.record(tab, url: try page("https://secure.chase.com/"), title: "", transition: .link, item: nil)
        #expect(tab.snapshot.timeline.entries.map(\.url.host) == ["news.example"])
    }

    @Test("A sensitive page's title never lands on the previous entry")
    func sensitiveTitleDoesNotLeak() throws {
        let tab = WebTab(snapshot: TabSnapshot(), controller: nil)
        let recorder = TabTimelineRecorder()
        recorder.apply(policy: SensitiveSitePolicy(customDomains: ["chase.com"]))
        recorder.record(tab, url: try page("https://news.example/a"), title: "News", transition: .opened, item: nil)
        recorder.record(tab, url: try page("https://secure.chase.com/"), title: "", transition: .link, item: nil)
        recorder.titleChanged("Chase account 1234", on: tab)
        #expect(tab.snapshot.timeline.entries.map(\.title) == ["News"])
    }
}
