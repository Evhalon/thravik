import Foundation
import RedentKit

// @unchecked Sendable: UserDefaults is documented by Apple as thread-safe,
// but its Swift overlay doesn't declare Sendable conformance.
public struct UserDefaultsSessionStore: SessionStoring, @unchecked Sendable {
    private static let legacyKey = "app.redent.browser.session"
    private let defaults: UserDefaults
    /// One workspace store for the life of the session store: it memoizes the
    /// blob it last wrote, and a fresh instance per save would throw that away.
    private let workspace: UserDefaultsWorkspaceStore

    public init(defaults: UserDefaults = .standard) {
        self.defaults = defaults
        self.workspace = UserDefaultsWorkspaceStore(defaults: defaults)
    }

    public func load() -> BrowserSession {
        if defaults.data(forKey: "app.redent.browser.workspace.v2") != nil {
            return (try? workspace.loadWorkspace().session) ?? BrowserSession()
        }
        guard let data = defaults.data(forKey: Self.legacyKey),
              let session = try? JSONDecoder().decode(BrowserSession.self, from: data)
        else { return BrowserSession() }
        return session
    }

    public func save(_ session: BrowserSession) {
        try? workspace.saveWorkspace(WorkspaceSnapshot(session: session))
    }

    public func loadRecoverable() throws -> BrowserSession {
        try workspace.loadWorkspace().session
    }

    public func saveRecoverable(_ session: BrowserSession) throws {
        try workspace.saveWorkspace(WorkspaceSnapshot(session: session))
    }
}
