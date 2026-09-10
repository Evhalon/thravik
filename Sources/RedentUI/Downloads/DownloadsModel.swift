import AppKit
import Foundation
import Observation
import RedentKit

/// The window-independent list of files the browser has fetched.
///
/// One per app: a download started in one window belongs to all of them, and
/// survives the window that started it. The list is in memory for the life of
/// the process — the files themselves are the durable record, and a browsing
/// trail on disk is exactly what a private window must not leave behind.
@MainActor @Observable
public final class DownloadsModel: DownloadObserving {
    /// Newest first, which is the order the panel reads in.
    public private(set) var items: [DownloadItem] = []
    /// Set once a fetch finishes while the panel is closed, so the chrome can
    /// draw the badge that says something arrived.
    public private(set) var hasUnseenCompletion = false

    /// Weak: the engine coordinator and this list are both owned by the app.
    @ObservationIgnored public weak var commands: (any DownloadCommanding)?

    public init() {}

    public var activeItems: [DownloadItem] { items.filter(\.isActive) }
    public var isEmpty: Bool { items.isEmpty }

    /// What the chrome's ring draws: the mean of everything still running, or
    /// `nil` when nothing is.
    public var activeFraction: Double? {
        let running = activeItems
        guard !running.isEmpty else { return nil }
        let known = running.compactMap(\.fraction)
        guard !known.isEmpty else { return nil }
        return known.reduce(0, +) / Double(known.count)
    }

    public func downloadChanged(_ item: DownloadItem) {
        if let index = items.firstIndex(where: { $0.id == item.id }) {
            items[index] = item
        } else {
            items.insert(item, at: 0)
        }
        if item.state == .finished { hasUnseenCompletion = true }
    }

    public func markSeen() { hasUnseenCompletion = false }

    public func cancel(_ id: UUID) {
        commands?.cancelDownload(id)
    }

    /// Drops the row, and the fetch behind it if it is still running. The file
    /// already on disk is never touched.
    public func remove(_ id: UUID) {
        commands?.forgetDownload(id)
        items.removeAll { $0.id == id }
    }

    public func clearFinished() {
        for item in items where !item.isActive { commands?.forgetDownload(item.id) }
        items.removeAll { !$0.isActive }
    }

    /// Finder, not a web view: a downloaded file is the system's business.
    public func revealInFinder(_ item: DownloadItem) {
        guard let destination = item.destination else { return }
        NSWorkspace.shared.activateFileViewerSelecting([destination])
    }

    public func openFile(_ item: DownloadItem) {
        guard item.state == .finished, let destination = item.destination else { return }
        NSWorkspace.shared.open(destination)
    }
}
