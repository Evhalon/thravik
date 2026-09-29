public struct SettingsServices {
    let updates: UpdateModel
    let defaultBrowser: DefaultBrowserModel
    let passkeys: PasskeyAccessModel?

    public init(updates: UpdateModel, defaultBrowser: DefaultBrowserModel, passkeys: PasskeyAccessModel? = nil) {
        self.updates = updates
        self.defaultBrowser = defaultBrowser
        self.passkeys = passkeys
    }
}
