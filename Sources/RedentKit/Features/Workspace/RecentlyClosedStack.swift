import Foundation

public struct RecentlyClosedStack: Sendable {
    public var records: [ClosedStackRecord] = []

    public init(records: [ClosedStackRecord] = []) {
        self.records = records
    }

    public mutating func pushTab(_ snapshot: TabSnapshot, insertIndex: Int, limit: Int) {
        push(
            ClosedStackRecord(insertIndex: insertIndex, payload: .tab(snapshot)),
            limit: limit
        )
    }

    public mutating func pushGroup(
        group: BrowserGroup,
        tabs: [TabSnapshot],
        insertIndex: Int,
        limit: Int
    ) {
        guard !tabs.isEmpty else { return }
        push(
            ClosedStackRecord(insertIndex: insertIndex, payload: .group(group: group, tabs: tabs)),
            limit: limit
        )
    }

    public mutating func push(_ record: ClosedStackRecord, limit: Int) {
        records.append(record)
        if records.count > limit {
            records.removeFirst(records.count - limit)
        }
    }

    /// Newest first. Records whose tabs are open again — an undo brought them
    /// back — are hidden, since reopening them would duplicate a live tab.
    public func listings(liveTabIDs: Set<UUID> = []) -> [RecentlyClosedEntry] {
        records.reversed()
            .filter { !Self.isStale($0, liveTabIDs: liveTabIDs) }
            .map { $0.listing() }
    }

    public mutating func remove(id: UUID, liveTabIDs: Set<UUID> = []) -> ClosedStackRecord? {
        guard let index = records.firstIndex(where: { $0.id == id }) else { return nil }
        let record = records.remove(at: index)
        return Self.isStale(record, liveTabIDs: liveTabIDs) ? nil : record
    }

    public mutating func popLast(liveTabIDs: Set<UUID>) -> ClosedStackRecord? {
        while let last = records.last {
            if Self.isStale(last, liveTabIDs: liveTabIDs) {
                records.removeLast()
            } else {
                return records.removeLast()
            }
        }
        return nil
    }

    @discardableResult
    public mutating func forget(domain: String) -> Int {
        let before = records.count
        records.removeAll { record in
            switch record.payload {
            case .tab(let tab):
                tab.origin?.registrableDomain == domain
            case .group(_, let tabs):
                tabs.contains { $0.origin?.registrableDomain == domain }
            }
        }
        return before - records.count
    }

    public static func isStale(_ record: ClosedStackRecord, liveTabIDs: Set<UUID>) -> Bool {
        switch record.payload {
        case .tab(let snapshot):
            liveTabIDs.contains(snapshot.id)
        case .group(_, let tabs):
            !tabs.isEmpty && tabs.allSatisfy { liveTabIDs.contains($0.id) }
        }
    }
}
