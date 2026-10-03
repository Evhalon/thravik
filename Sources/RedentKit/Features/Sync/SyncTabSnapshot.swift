import Foundation

/// Portable navigation metadata; runtime state and temporary tabs never enter this DTO.
public struct SyncTabSnapshot: Codable, Sendable, Equatable {
    public let id: UUID
    public let url: URL?
    public let title: String
    public let isPinned: Bool
    public let pinnedURL: URL?
    public let customTitle: String?
    /// Optional so older peers keep decoding; unknown keys stay ignored.
    public let customEmoji: String?
    public let spaceID: UUID?
    public let groupID: UUID?
    public let parentTabID: UUID?
    public let zoom: Double

    public init?(tab: TabSnapshot) {
        guard !tab.isTemporary else { return nil }
        id = tab.id
        url = Self.portableURL(tab.url)
        title = tab.title
        isPinned = tab.isPinned
        pinnedURL = Self.portableURL(tab.pinnedURL)
        customTitle = tab.customTitle
        customEmoji = TabCustomEmoji.validated(tab.customEmoji)
        spaceID = tab.spaceID
        groupID = tab.groupID
        parentTabID = tab.parentTabID
        zoom = tab.zoom
    }

    private static func portableURL(_ url: URL?) -> URL? {
        guard let url, var components = URLComponents(url: url, resolvingAgainstBaseURL: false),
              components.scheme == "https" || components.scheme == "http", components.host != nil
        else { return nil }
        components.user = nil
        components.password = nil
        components.query = nil
        components.fragment = nil
        return components.url
    }
}
