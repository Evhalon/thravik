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
    /// Where a pinned tab belongs: the page it showed when pinned. Browsing
    /// away keeps the pin; "Return to" comes back here.
    public var pinnedURL: URL?
    /// The user's own name for the tab, shown instead of the page title.
    public var customTitle: String?
    /// A user-chosen emoji drawn instead of the site favicon.
    public var customEmoji: String?
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
    /// Page zoom, kept per tab so it survives hibernation and restart.
    public var zoom: Double = PageZoom.identity
    /// Dragged out of its site's automatic cluster, so the sidebar leaves it
    /// on its own even while other tabs share its host.
    public var standsApartFromSite = false

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
        if let customTitle { return customTitle }
        if !title.isEmpty { return title }
        if let host = url.flatMap(Origin.init(url:))?.displayHost { return host }
        return "New Tab"
    }

    public var origin: Origin? { url.flatMap(Origin.init(url:)) }

    /// The pinned page, when the tab has browsed away from it.
    public var pinnedPageElsewhere: URL? {
        guard isPinned, let pinnedURL, url != pinnedURL else { return nil }
        return pinnedURL
    }

    /// A temporary tab that cleans up after itself owns an ephemeral store;
    /// every other tab browses in its Container, defaulting to Default.
    public var browsingContext: BrowsingContext {
        if case let .temporary(sessionID, _, cleanupOnClose) = lifespan, cleanupOnClose {
            return .ephemeral(sessionID)
        }
        return .container(containerID ?? BrowserContainer.defaultID)
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
