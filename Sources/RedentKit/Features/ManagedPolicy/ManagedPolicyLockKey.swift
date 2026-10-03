import Foundation

/// User-facing settings fields an MDM policy overrides.
public enum ManagedPolicyLockKey: String, Sendable, Hashable, CaseIterable {
    case homepage
    case searchEngine
    case blocksTrackers
    case offersPasswordSave
}
