import Foundation
import RedentKit

/// Stands in for the app's windows: records what the window model asked of
/// them, and accepts or refuses a tab as told.
@MainActor
final class RecordingWindowDirectory: BrowserWindowDirectory {
    var windows: [CommandWindowContext] = []
    var acceptsTabs = true
    private(set) var adopted: [(url: URL, window: UUID?)] = []
    private(set) var openedApps: [(app: WebApp, url: URL?)] = []
    private(set) var focused: [UUID] = []

    func focus(_ id: UUID) { focused.append(id) }
    func closeCurrent() {}
    func toggleFullScreen() {}

    func adopt(_ url: URL, into id: UUID?) -> Bool {
        guard acceptsTabs else { return false }
        adopted.append((url, id))
        return true
    }

    func open(_ app: WebApp, at url: URL?, in space: BrowserSpace?) {
        openedApps.append((app, url))
    }
}

actor MemoryWebAppStore: WebAppStoring {
    private(set) var apps: [WebApp]

    init(_ apps: [WebApp] = []) { self.apps = apps }

    func all() async -> [WebApp] { apps }
    func save(_ app: WebApp) async {
        apps.removeAll { $0.id == app.id }
        apps.append(app)
    }
    func delete(_ id: UUID) async { apps.removeAll { $0.id == id } }
}
