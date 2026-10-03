import Foundation

public struct TidyTabsPolicy: Sendable {
    public static let minimumSuggestionCount = 5

    public struct Request: Sendable {
        public var tabs: [TabSnapshot]
        public var selectedTabID: UUID?
        public var splitTabIDs: Set<UUID>
        public var playingAudioTabIDs: Set<UUID>
        public var inactivityThreshold: TimeInterval
        public var now: Date
        public var requiresMinimumCount: Bool

        public init(
            tabs: [TabSnapshot],
            selectedTabID: UUID?,
            splitTabIDs: Set<UUID>,
            playingAudioTabIDs: Set<UUID>,
            inactivityThreshold: TimeInterval,
            now: Date,
            requiresMinimumCount: Bool
        ) {
            self.tabs = tabs
            self.selectedTabID = selectedTabID
            self.splitTabIDs = splitTabIDs
            self.playingAudioTabIDs = playingAudioTabIDs
            self.inactivityThreshold = inactivityThreshold
            self.now = now
            self.requiresMinimumCount = requiresMinimumCount
        }
    }

    public init() {}

    public func candidateIDs(for request: Request) -> [UUID] {
        let staleBefore = request.now.addingTimeInterval(-request.inactivityThreshold)
        let ids = request.tabs.compactMap { tab -> UUID? in
            guard isEligible(tab, request: request, staleBefore: staleBefore) else { return nil }
            return tab.id
        }
        guard !request.requiresMinimumCount || ids.count >= Self.minimumSuggestionCount else { return [] }
        return ids
    }

    private func isEligible(_ tab: TabSnapshot, request: Request, staleBefore: Date) -> Bool {
        guard !tab.isPinned, !tab.isTemporary, tab.groupID == nil else { return false }
        guard tab.id != request.selectedTabID else { return false }
        guard !request.splitTabIDs.contains(tab.id) else { return false }
        guard !request.playingAudioTabIDs.contains(tab.id) else { return false }
        return tab.lastActiveAt <= staleBefore
    }
}
