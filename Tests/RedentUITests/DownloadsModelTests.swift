import Foundation
import RedentKit
import Testing
@testable import RedentUI

@MainActor
final class RecordingDownloadCommands: DownloadCommanding {
    private(set) var cancelled: [UUID] = []
    private(set) var forgotten: [UUID] = []
    func cancelDownload(_ id: UUID) { cancelled.append(id) }
    func forgetDownload(_ id: UUID) { forgotten.append(id) }
}

@MainActor
@Suite("Downloads list")
struct DownloadsModelTests {
    private func model() -> (DownloadsModel, RecordingDownloadCommands) {
        let list = DownloadsModel()
        let commands = RecordingDownloadCommands()
        list.commands = commands
        return (list, commands)
    }

    @Test("Newest arrives on top, and progress updates the row in place")
    func upsertsInPlace() {
        let (list, _) = model()
        var first = DownloadItem(filename: "a.zip")
        list.downloadChanged(first)
        list.downloadChanged(DownloadItem(filename: "b.zip"))
        first.bytesReceived = 512
        list.downloadChanged(first)

        #expect(list.items.count == 2)
        #expect(list.items.first?.filename == "b.zip")
        #expect(list.items.last?.bytesReceived == 512)
    }

    @Test("A finished download is flagged until the panel is opened")
    func flagsCompletion() {
        let (list, _) = model()
        var item = DownloadItem(filename: "a.zip")
        list.downloadChanged(item)
        #expect(!list.hasUnseenCompletion)
        item.state = .finished
        list.downloadChanged(item)
        #expect(list.hasUnseenCompletion)
        list.markSeen()
        #expect(!list.hasUnseenCompletion)
    }

    @Test("Clearing keeps what is still running, and tells the engine to let go")
    func clearsOnlyFinished() {
        let (list, commands) = model()
        let running = DownloadItem(filename: "running.zip")
        let done = DownloadItem(filename: "done.zip", state: .finished)
        list.downloadChanged(running)
        list.downloadChanged(done)

        list.clearFinished()
        #expect(list.items.map(\.filename) == ["running.zip"])
        #expect(commands.forgotten == [done.id])
    }

    @Test("The chrome ring averages only what is still running")
    func averagesActiveProgress() {
        let (list, _) = model()
        list.downloadChanged(
            DownloadItem(filename: "a", bytesReceived: 50, bytesExpected: 100)
        )
        list.downloadChanged(
            DownloadItem(filename: "b", bytesReceived: 100, bytesExpected: 100, state: .finished)
        )
        #expect(list.activeFraction == 0.5)
    }

    @Test("Cancelling reaches the engine but leaves the row in the list")
    func cancelKeepsTheRow() {
        let (list, commands) = model()
        let item = DownloadItem(filename: "a.zip")
        list.downloadChanged(item)
        list.cancel(item.id)
        #expect(commands.cancelled == [item.id])
        #expect(list.items.count == 1)
    }
}
