import Foundation

/// macOS MDM-managed browser policies. Every field optional — nil means not managed.
public struct ManagedPolicy: Sendable, Equatable {
    public var homepageURL: String?
    public var defaultSearchEngine: ManagedDefaultSearchEngine?
    public var disablePrivateWindows: Bool?
    public var disableExtensions: Bool?
    public var extensionAllowlist: [String]?
    public var disablePasswordSaving: Bool?
    public var forceTrackerBlocking: Bool?
    public var disableAccountSync: Bool?
    public var blockedURLPatterns: [String]?

    public init(
        homepageURL: String? = nil,
        defaultSearchEngine: ManagedDefaultSearchEngine? = nil,
        disablePrivateWindows: Bool? = nil,
        disableExtensions: Bool? = nil,
        extensionAllowlist: [String]? = nil,
        disablePasswordSaving: Bool? = nil,
        forceTrackerBlocking: Bool? = nil,
        disableAccountSync: Bool? = nil,
        blockedURLPatterns: [String]? = nil
    ) {
        self.homepageURL = homepageURL
        self.defaultSearchEngine = defaultSearchEngine
        self.disablePrivateWindows = disablePrivateWindows
        self.disableExtensions = disableExtensions
        self.extensionAllowlist = extensionAllowlist
        self.disablePasswordSaving = disablePasswordSaving
        self.forceTrackerBlocking = forceTrackerBlocking
        self.disableAccountSync = disableAccountSync
        self.blockedURLPatterns = blockedURLPatterns
    }

    public var isActive: Bool {
        homepageURL != nil
            || defaultSearchEngine != nil
            || disablePrivateWindows != nil
            || disableExtensions != nil
            || extensionAllowlist != nil
            || disablePasswordSaving != nil
            || forceTrackerBlocking != nil
            || disableAccountSync != nil
            || blockedURLPatterns != nil
    }
}
