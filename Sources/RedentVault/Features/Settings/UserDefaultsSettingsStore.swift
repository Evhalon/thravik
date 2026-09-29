import Foundation
import RedentKit

// @unchecked Sendable: UserDefaults is documented by Apple as thread-safe,
// but its Swift overlay doesn't declare Sendable conformance.
public struct UserDefaultsSettingsStore: SettingsStoring, @unchecked Sendable {
    private static let key = "app.redent.browser.settings"
    private let defaults: UserDefaults

    public init(defaults: UserDefaults = .standard) {
        self.defaults = defaults
    }

    public func load() -> BrowserSettings {
        guard let data = defaults.data(forKey: Self.key),
              let settings = try? JSONDecoder().decode(BrowserSettings.self, from: data)
        else { return BrowserSettings() }
        return settings
    }

    public func save(_ settings: BrowserSettings) {
        guard let data = try? JSONEncoder().encode(settings) else { return }
        defaults.set(data, forKey: Self.key)
    }
}
