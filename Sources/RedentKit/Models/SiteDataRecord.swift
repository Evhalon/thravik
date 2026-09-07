import Foundation

/// One website-data record exactly as the engine reports it.
///
/// `displayName` is the engine's own attribution — usually a registrable
/// domain, not an exact origin. Redent never substring-matches it: a record is
/// removed only when the engine itself hands it back for the domain being
/// cleared, so what the user is shown is the real deletion scope.
public struct SiteDataRecord: Sendable, Hashable, Identifiable {
    public let displayName: String
    public let dataTypes: Set<String>

    public var id: String { displayName }

    public init(displayName: String, dataTypes: Set<String>) {
        self.displayName = displayName
        self.dataTypes = dataTypes
    }
}

/// What a Forget Site pass actually did — a tally, never a promise.
public struct ForgetSiteReport: Sendable, Equatable {
    public var domain: String
    /// Engine record names actually removed, per Container.
    public var removedRecords: [String] = []
    public var clearedContainers: Int = 0
    public var clearedHistory = false
    public var discardedClosedTabs = 0
    /// Kept on purpose, and named so the user is not left guessing.
    public var retained: [String] = ["Bookmarks", "Saved passwords"]
    public var failures: [String] = []

    public init(domain: String) { self.domain = domain }

    public var removedNothing: Bool {
        removedRecords.isEmpty && !clearedHistory && discardedClosedTabs == 0
    }
}
