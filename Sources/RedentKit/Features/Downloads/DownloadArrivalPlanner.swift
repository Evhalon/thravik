import Foundation

/// New downloads fly; restored ones stay quiet. A burst becomes one flight.
public struct DownloadArrivalPlanner: Sendable {
    public static let coalesceInterval: TimeInterval = 0.3

    private let sessionStartedAt: Date
    private var seenIDs: Set<UUID> = []
    private var activeIDs: Set<UUID> = []
    private var pendingFlights: [DownloadItem] = []
    private var pendingPulses: [DownloadItem] = []
    private var lastFlightAt: Date?
    private var lastPulseAt: Date?

    public init(sessionStartedAt: Date = Date()) {
        self.sessionStartedAt = sessionStartedAt
    }

    public var nextDrainAt: Date? {
        let flight = drainDate(after: lastFlightAt, pending: !pendingFlights.isEmpty)
        let pulse = drainDate(after: lastPulseAt, pending: !pendingPulses.isEmpty)
        return [flight, pulse].compactMap { $0 }.min()
    }

    public mutating func ingest(_ items: [DownloadItem], at now: Date) -> [DownloadArrivalCue] {
        collect(items)
        return flushDue(at: now)
    }

    public mutating func drain(at now: Date) -> [DownloadArrivalCue] {
        flushDue(at: now)
    }

    private mutating func collect(_ items: [DownloadItem]) {
        for item in items {
            if seenIDs.contains(item.id) {
                noteExisting(item)
            } else {
                noteNew(item)
            }
            if item.isActive { activeIDs.insert(item.id) } else { activeIDs.remove(item.id) }
        }
    }

    private mutating func noteNew(_ item: DownloadItem) {
        seenIDs.insert(item.id)
        guard item.startedAt >= sessionStartedAt else { return }
        pendingFlights.append(item)
        if item.state == .finished { pendingPulses.append(item) }
    }

    private mutating func noteExisting(_ item: DownloadItem) {
        guard activeIDs.contains(item.id), item.state == .finished else { return }
        pendingPulses.append(item)
    }

    private mutating func flushDue(at now: Date) -> [DownloadArrivalCue] {
        var cues: [DownloadArrivalCue] = []
        if let flight = takeDue(from: &pendingFlights, lastAt: &lastFlightAt, now: now, kind: .flight) {
            cues.append(flight)
        }
        if let pulse = takeDue(from: &pendingPulses, lastAt: &lastPulseAt, now: now, kind: .pulse) {
            cues.append(pulse)
        }
        return cues
    }

    private func takeDue(
        from pending: inout [DownloadItem],
        lastAt: inout Date?,
        now: Date,
        kind: DownloadArrivalCue.Kind
    ) -> DownloadArrivalCue? {
        guard let lead = pending.first else { return nil }
        // A wall clock set backwards must release the burst, not hold it until it catches up.
        if let lastAt, now >= lastAt, now.timeIntervalSince(lastAt) + 0.001 < Self.coalesceInterval {
            return nil
        }
        let count = pending.count
        pending.removeAll()
        lastAt = now
        return DownloadArrivalCue(kind: kind, itemID: lead.id, filename: lead.filename, count: count)
    }

    private func drainDate(after last: Date?, pending: Bool) -> Date? {
        guard pending, let last else { return nil }
        return last.addingTimeInterval(Self.coalesceInterval)
    }
}
