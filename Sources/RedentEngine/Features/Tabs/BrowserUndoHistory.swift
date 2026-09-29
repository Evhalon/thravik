import RedentKit
import Observation

@MainActor @Observable
final class BrowserUndoHistory {
    private var records: [BrowserSession] = []
    var canUndo: Bool { !records.isEmpty }

    func record(_ session: BrowserSession) {
        var normal = session
        normal.tabs = normal.tabs.filter { !$0.isTemporary }.map {
            var snapshot = $0
            snapshot.faviconData = nil
            // Undo restores where a tab lives, not where it has been. Keeping a
            // copy of every timeline in twenty-five records pinned thousands of
            // navigation entries in memory for nothing.
            snapshot.timeline = TabTimeline()
            return snapshot
        }
        records.append(normal)
        if records.count > 25 { records.removeFirst() }
    }

    func pop() -> BrowserSession? { records.popLast() }
    func clear() { records.removeAll() }
}
