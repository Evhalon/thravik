import Foundation

public struct WorkspaceSyncApplication: Sendable, Equatable {
    public var session: BrowserSession
    public var remoteTabs: [RemoteSyncedTab]

    public init(session: BrowserSession, remoteTabs: [RemoteSyncedTab]) {
        self.session = session
        self.remoteTabs = remoteTabs
    }
}
