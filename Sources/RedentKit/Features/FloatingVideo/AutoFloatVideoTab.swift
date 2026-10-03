import Foundation

/// Playback facts a tab-switch decision needs. No WebKit, no UI.
public struct AutoFloatVideoTab: Sendable, Equatable {
    public var id: UUID
    public var isHibernated: Bool
    /// Still shown after the switch, e.g. in another split pane.
    public var isOnScreen: Bool
    public var video: Video

    public init(id: UUID, isHibernated: Bool, isOnScreen: Bool = false, video: Video) {
        self.id = id
        self.isHibernated = isHibernated
        self.isOnScreen = isOnScreen
        self.video = video
    }
}

extension AutoFloatVideoTab {
    public struct Video: Sendable, Equatable {
        public var isPlaying: Bool
        public var canFloat: Bool
        /// Unmuted with some volume. Muted autoplay previews never float.
        public var isAudible: Bool
        public var isFloating: Bool
        public var floatedAutomatically: Bool

        public init(
            isPlaying: Bool,
            canFloat: Bool,
            isAudible: Bool = true,
            isFloating: Bool,
            floatedAutomatically: Bool
        ) {
            self.isPlaying = isPlaying
            self.canFloat = canFloat
            self.isAudible = isAudible
            self.isFloating = isFloating
            self.floatedAutomatically = floatedAutomatically
        }
    }
}
