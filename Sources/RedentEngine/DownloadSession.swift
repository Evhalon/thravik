import Foundation
import RedentKit
import WebKit

/// One in-flight download: its WebKit delegate, its destination decision, and
/// the progress observation that feeds the download list.
///
/// Retained by `DownloadCoordinator` for exactly as long as the fetch lasts —
/// WebKit holds its delegate weakly, so nothing else would keep this alive.
@MainActor
final class DownloadSession: NSObject, WKDownloadDelegate {
    private(set) var item: DownloadItem
    private let download: WKDownload
    /// Weak both ways: the coordinator owns this session.
    private weak var coordinator: DownloadCoordinator?
    private var progressToken: NSKeyValueObservation?
    /// Bytes at the last report. WebKit updates progress far more often than a
    /// list can usefully redraw, so the observer is told in steps.
    private var reportedBytes: Int64 = 0
    /// Where WebKit is writing, until the finished file is moved across.
    private var stagedURL: URL?

    private static let reportStep: Int64 = 96 * 1024

    init(download: WKDownload, host: String?, coordinator: DownloadCoordinator) {
        self.download = download
        self.coordinator = coordinator
        self.item = DownloadItem(filename: "Download", host: host)
        super.init()
        observeProgress()
    }

    var id: UUID { item.id }

    func cancel() {
        progressToken = nil
        download.cancel { _ in }
        stagedURL.map(DownloadDestination.discardStaging)
        finish(with: .cancelled)
    }

    func download(
        _ download: WKDownload,
        decideDestinationUsing response: URLResponse,
        suggestedFilename: String
    ) async -> URL? {
        // Off the main actor: creating the folder is disk work, and this is
        // called on the way into a fetch the user is waiting on.
        let staged = await Task.detached {
            try? DownloadDestination.stagingURL(for: suggestedFilename)
        }.value
        guard let staged else {
            finish(with: .failed("Nowhere to save the file."))
            return nil
        }
        stagedURL = staged
        item.filename = staged.lastPathComponent
        if response.expectedContentLength > 0 { item.bytesExpected = response.expectedContentLength }
        publish()
        return staged
    }

    func downloadDidFinish(_ download: WKDownload) {
        progressToken = nil
        item.bytesReceived = item.bytesExpected ?? item.bytesReceived
        Task { await moveIntoDownloads() }
    }

    /// The last step of every download: WebKit's network process cannot write
    /// into Downloads, so the finished file is moved there by this app.
    private func moveIntoDownloads() async {
        guard let staged = stagedURL else { return finish(with: .finished) }
        let moved = await Task.detached { try? DownloadDestination.moveToDownloads(staged) }.value
        guard let moved else {
            DownloadDestination.discardStaging(staged)
            finish(with: .failed("The file could not be saved to Downloads."))
            return
        }
        item.destination = moved
        item.filename = moved.lastPathComponent
        finish(with: .finished)
    }

    func download(
        _ download: WKDownload, didFailWithError error: any Error, resumeData: Data?
    ) {
        progressToken = nil
        stagedURL.map(DownloadDestination.discardStaging)
        finish(with: .failed((error as NSError).localizedDescription))
    }

    /// WebKit publishes byte counts through `Progress`, so they are observed
    /// rather than polled (AGENTS.md §4).
    private func observeProgress() {
        progressToken = download.progress.observe(\.completedUnitCount) { [weak self] progress, _ in
            let received = progress.completedUnitCount
            let expected = progress.totalUnitCount
            Task { @MainActor in self?.advance(received: received, expected: expected) }
        }
    }

    private func advance(received: Int64, expected: Int64) {
        guard item.isActive else { return }
        item.bytesReceived = received
        if expected > 0 { item.bytesExpected = expected }
        guard received - reportedBytes >= Self.reportStep else { return }
        reportedBytes = received
        publish()
    }

    private func finish(with state: DownloadItem.State) {
        guard item.isActive else { return }
        item.state = state
        publish()
        coordinator?.sessionEnded(id)
    }

    private func publish() {
        coordinator?.observer?.downloadChanged(item)
    }
}
