import Foundation

/// The part of a tab that survives hibernation and app restarts.
///
/// Deliberately free of any WebKit type: the engine restores a live view from
/// this, and the UI can render a hibernated tab without one existing.
public struct TabSnapshot: Identifiable, Hashable, Sendable, Codable {
    public let id: UUID
    public var url: URL?
    public var title: String
    public var faviconData: Data?
    public var isPinned: Bool
    public var lastActiveAt: Date
    public var spaceID: UUID?
    public var containerID: UUID?
    public var groupID: UUID?
    /// Opener tab. Child popups nest under this in the sidebar.
    public var parentTabID: UUID?
    public var lifespan: TabLifespan
    /// The tab's own path. Excluded from persistence for temporary tabs, which
    /// never reach a saved snapshot at all.
    public var timeline = TabTimeline()

    private enum CodingKeys: String, CodingKey {
        case id, url, title, faviconData, isPinned, lastActiveAt
        case spaceID, containerID, groupID, parentTabID, expiresAt, lifespan, timeline
    }

    public init(
        id: UUID = UUID(),
        url: URL? = nil,
        title: String = "",
        faviconData: Data? = nil,
        isPinned: Bool = false,
        lastActiveAt: Date = .now,
        spaceID: UUID? = nil,
        containerID: UUID? = nil,
        groupID: UUID? = nil,
        expiresAt: Date? = nil
    ) {
        self.id = id
        self.url = url
        self.title = title
        self.faviconData = faviconData
        self.isPinned = isPinned
        self.lastActiveAt = lastActiveAt
        self.spaceID = spaceID
        self.containerID = containerID
        self.groupID = groupID
        self.parentTabID = nil
        self.lifespan = expiresAt.map { .temporary(sessionID: UUID(), expiresAt: $0, cleanupOnClose: true) } ?? .normal
    }

    /// What the tab strip shows: page title, else host, else a placeholder.
    public var displayTitle: String {
        if !title.isEmpty { return title }
        if let host = url.flatMap(Origin.init(url:))?.displayHost { return host }
        return "New Tab"
    }

    public var origin: Origin? { url.flatMap(Origin.init(url:)) }

    /// A temporary tab that cleans up after itself owns an ephemeral store;
    /// every other tab browses in its Container, defaulting to Default.
    public var browsingContext: BrowsingContext {
        if case let .temporary(sessionID, _, cleanupOnClose) = lifespan, cleanupOnClose {
            return .ephemeral(sessionID)
        }
        return .container(containerID ?? BrowserContainer.defaultID)
    }

    public init(from decoder: Decoder) throws {
        let values = try decoder.container(keyedBy: CodingKeys.self)
        let expiry = try values.decodeIfPresent(Date.self, forKey: .expiresAt)
        self.init(
            id: try values.decodeIfPresent(UUID.self, forKey: .id) ?? UUID(),
            url: try values.decodeIfPresent(URL.self, forKey: .url),
            title: try values.decodeIfPresent(String.self, forKey: .title) ?? "",
            faviconData: try values.decodeIfPresent(Data.self, forKey: .faviconData),
            isPinned: try values.decodeIfPresent(Bool.self, forKey: .isPinned) ?? false,
            lastActiveAt: try values.decodeIfPresent(Date.self, forKey: .lastActiveAt) ?? .now,
            spaceID: try values.decodeIfPresent(UUID.self, forKey: .spaceID),
            containerID: try values.decodeIfPresent(UUID.self, forKey: .containerID),
            groupID: try values.decodeIfPresent(UUID.self, forKey: .groupID),
            expiresAt: expiry
        )
        if let lifespan = try values.decodeIfPresent(TabLifespan.self, forKey: .lifespan) {
            self.lifespan = lifespan
        }
        self.timeline = try values.decodeIfPresent(TabTimeline.self, forKey: .timeline) ?? TabTimeline()
        self.parentTabID = try values.decodeIfPresent(UUID.self, forKey: .parentTabID)
    }

    public func encode(to encoder: Encoder) throws {
        var values = encoder.container(keyedBy: CodingKeys.self)
        try values.encode(id, forKey: .id)
        try values.encodeIfPresent(url, forKey: .url)
        try values.encode(title, forKey: .title)
        try values.encodeIfPresent(faviconData, forKey: .faviconData)
        try values.encode(isPinned, forKey: .isPinned)
        try values.encode(lastActiveAt, forKey: .lastActiveAt)
        try values.encodeIfPresent(spaceID, forKey: .spaceID)
        try values.encodeIfPresent(containerID, forKey: .containerID)
        try values.encodeIfPresent(groupID, forKey: .groupID)
        try values.encodeIfPresent(parentTabID, forKey: .parentTabID)
        try values.encodeIfPresent(expiresAt, forKey: .expiresAt)
        try values.encode(lifespan, forKey: .lifespan)
        try values.encode(timeline.persistable(), forKey: .timeline)
    }

    public var expiresAt: Date? {
        get { lifespan.expiresAt }
        set {
            if let newValue {
                lifespan = .temporary(sessionID: UUID(), expiresAt: newValue, cleanupOnClose: true)
            } else {
                lifespan = .normal
            }
        }
    }

    public var isTemporary: Bool { lifespan.isTemporary }
}
