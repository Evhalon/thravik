import Foundation

public struct GroupingSuggestionService: Sendable {
    public init() {}

    public func suggestions(for tabs: [TabSnapshot], spaceID: UUID? = nil) -> [GroupingSuggestion] {
        var grouped: [Origin: [UUID]] = [:]
        for tab in tabs where isCandidate(tab, spaceID: spaceID) {
            guard let origin = tab.origin else { continue }
            grouped[origin, default: []].append(tab.id)
        }
        return grouped.filter { $0.value.count > 1 }
            .map { GroupingSuggestion(origin: $0.key, tabIDs: $0.value) }
            .sorted { $0.name.localizedStandardCompare($1.name) == .orderedAscending }
    }

    private func isCandidate(_ tab: TabSnapshot, spaceID: UUID?) -> Bool {
        guard !tab.isPinned, !tab.isTemporary else { return false }
        guard let spaceID else { return tab.groupID == nil }
        return tab.spaceID == spaceID && tab.groupID == nil
    }
}
