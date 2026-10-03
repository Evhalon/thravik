import Foundation

private enum TabSnapshotCodingKey: String, CodingKey {
    case id, url, title, faviconData, isPinned, pinnedURL, customTitle, customEmoji, lastActiveAt
    case spaceID, containerID, groupID, parentTabID, expiresAt, lifespan, timeline, zoom
    case standsApartFromSite
}

/// Decoding is explicit so a field added later never drops a saved session.
extension TabSnapshot {
    public init(from decoder: Decoder) throws {
        let values = try decoder.container(keyedBy: TabSnapshotCodingKey.self)
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
        self.zoom = PageZoom.clamped(try values.decodeIfPresent(Double.self, forKey: .zoom) ?? PageZoom.identity)
        self.parentTabID = try values.decodeIfPresent(UUID.self, forKey: .parentTabID)
        self.pinnedURL = try values.decodeIfPresent(URL.self, forKey: .pinnedURL)
        self.customTitle = try values.decodeIfPresent(String.self, forKey: .customTitle)
        self.customEmoji = TabCustomEmoji.validated(
            try values.decodeIfPresent(String.self, forKey: .customEmoji)
        )
        self.standsApartFromSite = try values.decodeIfPresent(Bool.self, forKey: .standsApartFromSite) ?? false
    }

    public func encode(to encoder: Encoder) throws {
        var values = encoder.container(keyedBy: TabSnapshotCodingKey.self)
        try values.encode(id, forKey: .id)
        try values.encodeIfPresent(url, forKey: .url)
        try values.encode(title, forKey: .title)
        try values.encodeIfPresent(faviconData, forKey: .faviconData)
        try values.encode(isPinned, forKey: .isPinned)
        try values.encodeIfPresent(pinnedURL, forKey: .pinnedURL)
        try values.encodeIfPresent(customTitle, forKey: .customTitle)
        try values.encodeIfPresent(customEmoji, forKey: .customEmoji)
        try values.encode(lastActiveAt, forKey: .lastActiveAt)
        try values.encodeIfPresent(spaceID, forKey: .spaceID)
        try values.encodeIfPresent(containerID, forKey: .containerID)
        try values.encodeIfPresent(groupID, forKey: .groupID)
        try values.encodeIfPresent(parentTabID, forKey: .parentTabID)
        try values.encodeIfPresent(expiresAt, forKey: .expiresAt)
        try values.encode(lifespan, forKey: .lifespan)
        try values.encode(timeline.persistable(), forKey: .timeline)
        try values.encode(zoom, forKey: .zoom)
        try values.encode(standsApartFromSite, forKey: .standsApartFromSite)
    }
}
