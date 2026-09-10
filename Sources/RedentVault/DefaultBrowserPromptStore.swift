import Foundation
import RedentKit

/// Remembers whether this release already offered to become the default
/// browser, and whether the user asked never to be offered again.
///
// @unchecked Sendable: UserDefaults is documented by Apple as thread-safe,
// but its Swift overlay doesn't declare Sendable conformance.
public struct DefaultBrowserPromptStore: DefaultBrowserPromptStoring, @unchecked Sendable {
    private enum Key {
        static let promptedVersion = "app.redent.browser.defaultBrowser.promptedVersion"
        static let silenced = "app.redent.browser.defaultBrowser.silenced"
        /// Stands in for a development build, which has no version string.
        static let unversioned = "unversioned"
    }

    private let defaults: UserDefaults

    public init(defaults: UserDefaults = .standard) {
        self.defaults = defaults
    }

    public var lastPromptedVersion: String? {
        defaults.string(forKey: Key.promptedVersion)
    }

    public var isSilenced: Bool {
        defaults.bool(forKey: Key.silenced)
    }

    public func recordPrompt(for version: String?) {
        defaults.set(version ?? Key.unversioned, forKey: Key.promptedVersion)
    }

    public func silence() {
        defaults.set(true, forKey: Key.silenced)
    }
}
