import SwiftUI

public struct SettingsServices: Sendable {
    let updates: UpdateModel
    let defaultBrowser: DefaultBrowserModel
    let passkeys: PasskeyAccessModel?

    public init(updates: UpdateModel, defaultBrowser: DefaultBrowserModel, passkeys: PasskeyAccessModel? = nil) {
        self.updates = updates
        self.defaultBrowser = defaultBrowser
        self.passkeys = passkeys
    }
}

extension EnvironmentValues {
    /// Set once per window by the composition root; nil in previews, where the
    /// Settings page has nothing to show.
    @Entry var settingsServices: SettingsServices?
}
