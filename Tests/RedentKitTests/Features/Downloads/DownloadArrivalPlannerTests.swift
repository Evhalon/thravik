import Foundation
import Testing
@testable import RedentKit

@Suite("Download arrival planner")
struct DownloadArrivalPlannerTests {
    private let session = Date(timeIntervalSince1970: 1_000)

    @Test("A download started before the session is restored, not flown")
    func restoredSkipsFlight() {
        var planner = DownloadArrivalPlanner(sessionStartedAt: session)
        let cues = planner.ingest([item("old.zip", start: -30)], at: session)
        #expect(cues.isEmpty)
        #expect(planner.nextDrainAt == nil)
    }

    @Test("A download started at or after the session flies once")
    func newItemFlies() {
        var planner = DownloadArrivalPlanner(sessionStartedAt: session)
        let file = item("report.pdf", start: 0)
        let cues = planner.ingest([file], at: session)
        #expect(cues.map(\.kind) == [.flight])
        #expect(cues.first?.filename == "report.pdf")
        #expect(cues.first?.count == 1)
        #expect(planner.ingest([file], at: session.addingTimeInterval(1)).isEmpty)
    }

    @Test("Five new files in one ingest become one flight with a count")
    func burstCoalescesIntoOneFlight() {
        var planner = DownloadArrivalPlanner(sessionStartedAt: session)
        let files = (0..<5).map { item("\($0).zip", start: 0) }
        let cues = planner.ingest(files, at: session)
        #expect(cues.count == 1)
        #expect(cues.first?.kind == .flight)
        #expect(cues.first?.count == 5)
        #expect(cues.first?.filename == "0.zip")
    }

    @Test("Arrivals within 0.3s share the next flight instead of stacking")
    func staggeredArrivalsCoalesce() {
        var planner = DownloadArrivalPlanner(sessionStartedAt: session)
        let a = item("a.zip", start: 0)
        let b = item("b.zip", start: 0.05)
        let first = planner.ingest([a], at: session)
        let held = planner.ingest([a, b], at: session.addingTimeInterval(0.05))
        let drained = planner.drain(at: session.addingTimeInterval(0.31))
        #expect(first.first?.count == 1)
        #expect(held.isEmpty)
        #expect(drained.first?.kind == .flight)
        #expect(drained.first?.count == 1)
        #expect(drained.first?.filename == "b.zip")
    }

    @Test("Finishing a running download pulses; restoring a finished one does not")
    func finishPulsesOnlyLiveItems() {
        var planner = DownloadArrivalPlanner(sessionStartedAt: session)
        var live = item("a.zip", start: 1)
        _ = planner.ingest([live], at: session.addingTimeInterval(1))
        live.state = .finished
        let liveCues = planner.ingest([live], at: session.addingTimeInterval(2))
        let restored = planner.ingest(
            [item("old.pdf", start: -10, state: .finished)],
            at: session.addingTimeInterval(2)
        )
        #expect(liveCues.map(\.kind) == [.pulse])
        #expect(restored.isEmpty)
    }

    @Test("A restored running download still pulses when it finishes")
    func restoredRunningThenFinishes() {
        var planner = DownloadArrivalPlanner(sessionStartedAt: session)
        var file = item("old.zip", start: -10)
        #expect(planner.ingest([file], at: session).isEmpty)
        file.state = .finished
        #expect(planner.ingest([file], at: session.addingTimeInterval(5)).map(\.kind) == [.pulse])
    }

    @Test("A clock set backwards releases a held burst instead of stalling it")
    func backwardsClockReleasesBurst() {
        var planner = DownloadArrivalPlanner(sessionStartedAt: session)
        _ = planner.ingest([item("a.zip", start: 0)], at: session)
        _ = planner.ingest([item("b.zip", start: 0.05)], at: session.addingTimeInterval(0.05))
        let drained = planner.drain(at: session.addingTimeInterval(-3_600))
        #expect(drained.first?.filename == "b.zip")
        #expect(planner.nextDrainAt == nil)
    }

    @Test("Drain is a no-op when nothing is waiting")
    func emptyDrain() {
        var planner = DownloadArrivalPlanner(sessionStartedAt: session)
        #expect(planner.drain(at: session).isEmpty)
    }

    private func item(
        _ name: String,
        start: TimeInterval,
        state: DownloadItem.State = .running
    ) -> DownloadItem {
        DownloadItem(filename: name, state: state, startedAt: session.addingTimeInterval(start))
    }
}
