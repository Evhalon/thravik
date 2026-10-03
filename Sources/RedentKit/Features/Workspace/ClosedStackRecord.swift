import Foundation

public struct ClosedStackRecord: Identifiable, Sendable, Hashable, Codable {
    public let id: UUID
    public let closedAt: Date
    public let insertIndex: Int
    public let payload: ClosedStackPayload

    public init(
        id: UUID = UUID(),
        closedAt: Date = .now,
        insertIndex: Int,
        payload: ClosedStackPayload
    ) {
        self.id = id
        self.closedAt = closedAt
        self.insertIndex = insertIndex
        self.payload = payload
    }

    public func listing() -> RecentlyClosedEntry {
        switch payload {
        case .tab(let snapshot):
            return RecentlyClosedEntry(
                id: id,
                title: snapshot.displayTitle,
                host: snapshot.origin?.displayHost,
                faviconData: snapshot.faviconData,
                closedAt: closedAt,
                kind: .tab
            )
        case .group(let group, let tabs):
            let icon = tabs.first?.faviconData
            return RecentlyClosedEntry(
                id: id,
                title: group.name,
                host: tabs.count == 1 ? tabs[0].origin?.displayHost : nil,
                faviconData: icon,
                closedAt: closedAt,
                kind: .group(tabCount: tabs.count)
            )
        }
    }
}
