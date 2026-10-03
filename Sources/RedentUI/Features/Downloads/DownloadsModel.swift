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
    /// Bumped once per coalesced burst of new downloads.
    public private(set) var arrivals = 0
    /// Bumped once per coalesced burst of finished downloads.
    public private(set) var completions = 0
    /// The latest flight for the key window to play.
    public private(set) var arrivalCue: DownloadArrivalCue?
    public private(set) var landingPulses = 0

    /// Weak: the engine coordinator and this list are both owned by the app.
    @ObservationIgnored public weak var commands: (any DownloadCommanding)?
    @ObservationIgnored private var planner: DownloadArrivalPlanner
    /// Owned here, not by a window: a held burst must land even with no window open.
    @ObservationIgnored private(set) var drainTask: Task<Void, Never>?
    @ObservationIgnored private let now: @MainActor () -> Date
    @ObservationIgnored private let sleep: @Sendable (Duration) async -> Void

    public init(
        sessionStartedAt: Date = Date(),
        now: @escaping @MainActor () -> Date = { .now },
        sleep: @escaping @Sendable (Duration) async -> Void = { try? await Task.sleep(for: $0) }
    ) {
        planner = DownloadArrivalPlanner(sessionStartedAt: sessionStartedAt)
        self.now = now
        self.sleep = sleep
    }

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
        if let previous = items.firstIndex(where: { $0.id == item.id }) {
            items[previous] = item
        } else {
            items.insert(item, at: 0)
        }
        apply(planner.ingest([item], at: now()))
    }

    public func drainArrivals(at now: Date = .now) {
        apply(planner.drain(at: now))
    }

    public func noteArrivalLanded() { landingPulses += 1 }
    public func markSeen() { hasUnseenCompletion = false }
    public func cancel(_ id: UUID) { commands?.cancelDownload(id) }

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

    private func apply(_ cues: [DownloadArrivalCue]) {
        for cue in cues { accept(cue) }
        scheduleDrain()
    }

    private func accept(_ cue: DownloadArrivalCue) {
        switch cue.kind {
        case .flight:
            arrivals += 1
            arrivalCue = cue
        case .pulse:
            hasUnseenCompletion = true
            completions += 1
        }
    }

    /// One pending wake at most; progress ticks while a burst is held must not
    /// spawn a task each.
    private func scheduleDrain() {
        guard drainTask == nil, let when = planner.nextDrainAt else { return }
        let interval = DownloadArrivalPlanner.coalesceInterval
        let delay = min(max(when.timeIntervalSince(now()), 0), interval)
        let sleep = sleep
        drainTask = Task { [weak self] in
            await sleep(.seconds(delay))
            guard let self else { return }
            drainTask = nil
            drainArrivals(at: now())
        }
    }
}
