import Foundation
import Testing
@testable import RedentKit

@Suite("Tab timeline")
struct TabTimelineTests {
    private func page(_ value: String) throws -> URL { try #require(URL(string: value)) }

    @Test("A→B→C is recorded in order")
    func recordsPath() throws {
        var timeline = TabTimeline()
        timeline.record(url: try page("https://a.example"), transition: .opened)
        timeline.record(url: try page("https://b.example"), transition: .link)
        timeline.record(url: try page("https://c.example"), transition: .link)

        #expect(timeline.entries.map(\.sequence) == [0, 1, 2])
        #expect(timeline.current?.url.host() == "c.example")
    }

    @Test("A reload is its own step, but a repeated link arrival is not")
    func reloadVersusDuplicate() throws {
        var timeline = TabTimeline()
        let url = try page("https://a.example")
        timeline.record(url: url, transition: .opened)
        timeline.record(url: url, transition: .link)
        #expect(timeline.entries.count == 1)

        timeline.record(url: url, transition: .reload)
        #expect(timeline.entries.count == 2)
        #expect(timeline.current?.transition == .reload)
    }

    @Test("Going back is recorded as traversal, not as a new visit")
    func traversal() throws {
        var timeline = TabTimeline()
        timeline.record(url: try page("https://a.example"), transition: .opened)
        timeline.record(url: try page("https://b.example"), transition: .link)
        timeline.record(url: try page("https://a.example"), transition: .traversal)
        #expect(timeline.entries.map(\.transition) == [.opened, .link, .traversal])
    }

    @Test("A title arriving after the load lands on the entry it belongs to")
    func titleUpdate() throws {
        var timeline = TabTimeline()
        let entry = try #require(timeline.record(url: try page("https://a.example"), transition: .opened))
        timeline.updateTitle("Arrived", for: entry.id)
        #expect(timeline.entries.first?.title == "Arrived")
        #expect(timeline.entries.first?.displayTitle == "Arrived")
    }

    @Test("Without a live view every entry offers a reload, not a restore")
    func liveStateIsHonest() throws {
        var timeline = TabTimeline()
        timeline.record(url: try page("https://a.example"), transition: .opened)
        #expect(timeline.current?.hasLiveState == true)
        #expect(timeline.current?.restoreLabel == "Go")

        timeline.dropLiveState()
        #expect(timeline.current?.hasLiveState == false)
        #expect(timeline.current?.restoreLabel == "Reload URL")
    }

    @Test("A persisted timeline is bounded and never claims live state")
    func persistableIsBounded() throws {
        var timeline = TabTimeline()
        for index in 0..<40 {
            timeline.record(url: try page("https://site\(index).example"), transition: .link)
        }
        let saved = timeline.persistable(limit: 25)
        #expect(saved.entries.count == 25)
        #expect(saved.entries.allSatisfy { !$0.hasLiveState })
        #expect(saved.entries.first?.url.host() == "site15.example")
    }

    @Test("The timeline is capped so a long-lived tab cannot grow without bound")
    func capped() throws {
        var timeline = TabTimeline()
        for index in 0..<(TabTimeline.limit + 20) {
            timeline.record(url: try page("https://site\(index).example"), transition: .link)
        }
        #expect(timeline.entries.count == TabTimeline.limit)
    }

    @Test("Forgetting a site removes its steps and leaves the rest of the path")
    func forgetCascades() throws {
        var timeline = TabTimeline()
        timeline.record(url: try page("https://keep.example/a"), transition: .opened)
        timeline.record(url: try page("https://drop.example/b"), transition: .link)
        timeline.record(url: try page("https://sub.drop.example/c"), transition: .link)
        timeline.record(url: try page("https://keep.example/d"), transition: .link)

        timeline.forget(domain: "drop.example")
        #expect(timeline.entries.map { $0.url.host() } == ["keep.example", "keep.example"])
    }
}
