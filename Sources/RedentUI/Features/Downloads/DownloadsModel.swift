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
    /// Bumped once per new download, so the chrome can animate the arrival.
    public private(set) var arrivals = 0
    /// Bumped once per download that finishes, for the completion flourish.
    public private(set) var completions = 0

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
        let previous = items.firstIndex { $0.id == item.id }
        let wasActive = previous.map { items[$0].isActive } ?? true
        if let previous {
            items[previous] = item
        } else {
            items.insert(item, at: 0)
            arrivals += 1
        }
        guard item.state == .finished, wasActive else { return }
        hasUnseenCompletion = true
        completions += 1
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

    public func openDownloadsFolder() {
        guard let folder = FileManager.default.urls(for: .downloadsDirectory, in: .userDomainMask).first
        else { return }
        NSWorkspace.shared.open(folder)
    }

    public func openFile(_ item: DownloadItem) {
        guard item.state == .finished, let destination = item.destination else { return }
        NSWorkspace.shared.open(destination)
    }
}
