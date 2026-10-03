import Foundation
import Observation
import RedentKit

@MainActor @Observable
public final class WorkspaceSyncModel {
    public private(set) var remoteTabs: [RemoteSyncedTab] = []
    public private(set) var syncedProfile: BrowserProfile?
    public private(set) var message: String?

    @ObservationIgnored public var openTab: ((RemoteSyncedTab) -> Void)?

    public init() {}

    public func replace(_ tabs: [RemoteSyncedTab]) { remoteTabs = tabs }

    public func recordSyncedProfile(_ profile: BrowserProfile?) { syncedProfile = profile }

    public func open(_ tab: RemoteSyncedTab) { openTab?(tab) }

    public func note(_ message: String?) { self.message = message }
}
