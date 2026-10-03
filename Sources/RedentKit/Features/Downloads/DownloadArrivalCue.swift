import Foundation

/// One chrome flourish for a download that just started or just finished.
public struct DownloadArrivalCue: Equatable, Sendable, Identifiable {
    public enum Kind: Equatable, Sendable {
        case flight
        case pulse
    }

    public let id: UUID
    public let kind: Kind
    public let itemID: UUID
    public let filename: String
    public let count: Int

    public init(
        id: UUID = UUID(),
        kind: Kind,
        itemID: UUID,
        filename: String,
        count: Int
    ) {
        self.id = id
        self.kind = kind
        self.itemID = itemID
        self.filename = filename
        self.count = count
    }
}
