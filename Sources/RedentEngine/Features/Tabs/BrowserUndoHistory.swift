import RedentKit
import Observation

@MainActor @Observable
final class BrowserUndoHistory {
    struct Record {
        let session: BrowserSession
        let scope: UndoScope
    }

    private var records: [Record] = []
    var canUndo: Bool { !records.isEmpty }
    var canUndoSpaces: Bool { records.contains { $0.scope == .spaces } }

    func record(_ session: BrowserSession, scope: UndoScope = .tabs) {
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
        records.append(Record(session: normal, scope: scope))
        if records.count > 25 { records.removeFirst() }
    }

    func pop() -> Record? { records.popLast() }

    /// The latest record of `scope`, skipping newer ones of the other scope:
    /// the Spaces panel's Undo must not rewind a tab closed after the edit.
    func pop(_ scope: UndoScope) -> Record? {
        guard let index = records.lastIndex(where: { $0.scope == scope }) else { return nil }
        return records.remove(at: index)
    }

    func clear() { records.removeAll() }
}
