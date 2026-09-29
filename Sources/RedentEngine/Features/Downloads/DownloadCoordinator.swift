import Foundation
import RedentKit
import WebKit

/// Every download the app has going, across all windows.
///
/// One per process: a download outlives the tab that started it, and a file
/// fetched from a private window must not disappear from the list because that
/// window closed. The list itself lives in the UI; this side only owns the
/// live WebKit fetches.
@MainActor
public final class DownloadCoordinator: DownloadCommanding {
    /// Weak: the download list belongs to the app, which owns this too.
    public weak var observer: (any DownloadObserving)?

    private var sessions: [UUID: DownloadSession] = [:]
    private let logger: any EventLogging

    public init(logger: any EventLogging) {
        self.logger = logger
    }

    /// Adopts a `WKDownload` WebKit has just handed over. Only the host is
    /// kept from the URL — a query string never reaches the list or the log.
    func adopt(_ download: WKDownload, from url: URL?) {
        let session = DownloadSession(download: download, host: url?.host(), coordinator: self)
        sessions[session.id] = session
        download.delegate = session
        observer?.downloadChanged(session.item)
        logger.notice("downloadStarted")
    }

    public func cancelDownload(_ id: UUID) {
        sessions[id]?.cancel()
    }

    /// The list dropped a finished row. A still-running fetch is cancelled
    /// first, so nothing keeps writing to a file nobody is watching.
    public func forgetDownload(_ id: UUID) {
        guard let session = sessions[id] else { return }
        if session.item.isActive { session.cancel() }
        sessions[id] = nil
    }

    func sessionEnded(_ id: UUID) {
        sessions[id] = nil
    }

    /// Whether anything is still fetching — the quit path asks before letting
    /// the app go.
    public var hasActiveDownloads: Bool {
        sessions.values.contains { $0.item.isActive }
    }
}
