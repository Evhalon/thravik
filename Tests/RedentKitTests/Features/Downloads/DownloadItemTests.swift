import Foundation
import Testing
@testable import RedentKit

@Suite("Download item")
struct DownloadItemTests {
    @Test("Progress is nil until the size is known")
    func fractionNeedsATotal() {
        var item = DownloadItem(filename: "report.pdf", bytesReceived: 500)
        #expect(item.fraction == nil)
        item.bytesExpected = 1000
        #expect(item.fraction == 0.5)
    }

    @Test("A server that overshoots its own length never reads past done")
    func fractionIsClamped() {
        let item = DownloadItem(filename: "a.bin", bytesReceived: 2000, bytesExpected: 1000)
        #expect(item.fraction == 1)
    }

    @Test("Only a running download is active")
    func activeStates() {
        #expect(DownloadItem(filename: "a", state: .running).isActive)
        #expect(!DownloadItem(filename: "a", state: .finished).isActive)
        #expect(!DownloadItem(filename: "a", state: .failed("no route")).isActive)
    }

    @Test("The caption names both sizes when both are known")
    func caption() {
        let item = DownloadItem(filename: "a", bytesReceived: 1_000, bytesExpected: 10_000)
        #expect(item.sizeCaption.contains("of"))
        #expect(!DownloadItem(filename: "a", bytesReceived: 1_000).sizeCaption.contains("of"))
    }

    @Test("Time left follows the average rate so far")
    func secondsRemaining() {
        let start = Date(timeIntervalSince1970: 0)
        let item = DownloadItem(
            filename: "a", bytesReceived: 1_000, bytesExpected: 4_000, startedAt: start
        )
        #expect(item.secondsRemaining(at: start.addingTimeInterval(10)) == 30)
    }

    @Test("No estimate without a size, a history, or a running fetch")
    func secondsRemainingNeedsData() {
        let start = Date(timeIntervalSince1970: 0)
        let later = start.addingTimeInterval(10)
        let unknownSize = DownloadItem(filename: "a", bytesReceived: 1_000, startedAt: start)
        let tooEarly = DownloadItem(filename: "a", bytesReceived: 1, bytesExpected: 9, startedAt: later)
        let finished = DownloadItem(
            filename: "a", bytesReceived: 1, bytesExpected: 9, state: .finished, startedAt: start
        )
        #expect(unknownSize.secondsRemaining(at: later) == nil)
        #expect(tooEarly.secondsRemaining(at: later) == nil)
        #expect(finished.secondsRemaining(at: later) == nil)
    }
}
