import Foundation

/// Remembers which stale tabs the user dismissed or already archived, so the
/// banner stays hidden until a tab it has not offered before goes stale.
public struct TidyTabsDismissal: Sendable, Equatable {
    public private(set) var suppressedCandidateIDs: Set<UUID> = []

    public init() {}

    public mutating func dismiss(candidates: Set<UUID>) {
        suppressedCandidateIDs.formUnion(candidates)
    }

    public func shouldShowSuggestion(for candidates: Set<UUID>) -> Bool {
        !candidates.subtracting(suppressedCandidateIDs).isEmpty
    }
}
