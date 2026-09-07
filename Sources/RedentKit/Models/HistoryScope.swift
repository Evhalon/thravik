import Foundation

/// Optional dimensions applied to a history query or deletion.
public struct HistoryScope: Hashable, Sendable, Codable {
    public var spaceID: UUID?
    public var containerID: UUID?
    public var domain: String?

    public init(
        spaceID: UUID? = nil,
        containerID: UUID? = nil,
        domain: String? = nil
    ) {
        self.spaceID = spaceID
        self.containerID = containerID
        self.domain = domain
    }

    public static let all = HistoryScope()
}
