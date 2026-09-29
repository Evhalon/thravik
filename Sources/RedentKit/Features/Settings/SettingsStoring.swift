import Foundation

public protocol SettingsStoring: Sendable {
    func load() -> BrowserSettings
    func save(_ settings: BrowserSettings)
}
