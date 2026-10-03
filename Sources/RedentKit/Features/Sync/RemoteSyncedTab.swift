import Foundation

public struct RemoteSyncedTab: Identifiable, Sendable, Equatable, Hashable {
    public let id: UUID
    public let deviceID: UUID
    public let title: String
    public let url: URL?

    public init(id: UUID, deviceID: UUID, title: String, url: URL?) {
        self.id = id
        self.deviceID = deviceID
        self.title = title
        self.url = url
    }
}
