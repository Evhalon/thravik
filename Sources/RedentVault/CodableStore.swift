import Foundation
import RedentKit

private enum DefaultsKey {
    static let settings = "app.redent.browser.settings"
    static let session = "app.redent.browser.session"
}

// @unchecked Sendable: UserDefaults is documented by Apple as thread-safe,
// but its Swift overlay doesn't declare Sendable conformance.
public struct UserDefaultsSettingsStore: SettingsStoring, @unchecked Sendable {
    private let defaults: UserDefaults

    public init(defaults: UserDefaults = .standard) {
        self.defaults = defaults
    }

    public func load() -> BrowserSettings {
        guard let data = defaults.data(forKey: DefaultsKey.settings),
              let settings = try? JSONDecoder().decode(BrowserSettings.self, from: data)
        else { return BrowserSettings() }
        return settings
    }

    public func save(_ settings: BrowserSettings) {
        guard let data = try? JSONEncoder().encode(settings) else { return }
        defaults.set(data, forKey: DefaultsKey.settings)
    }
}

// @unchecked Sendable: UserDefaults is documented by Apple as thread-safe,
// but its Swift overlay doesn't declare Sendable conformance.
public struct UserDefaultsSessionStore: SessionStoring, @unchecked Sendable {
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
        guard let data = defaults.data(forKey: DefaultsKey.session),
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
