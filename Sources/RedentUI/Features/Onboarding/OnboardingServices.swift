import Foundation

@MainActor
public struct OnboardingServices {
    public let account: AccountModel
    public let passwords: PasswordStorageModel
    public let workspace: WorkspaceSyncModel
    public let defaultBrowser: DefaultBrowserModel

    public init(account: AccountModel, passwords: PasswordStorageModel,
                workspace: WorkspaceSyncModel, defaultBrowser: DefaultBrowserModel) {
        self.account = account
        self.passwords = passwords
        self.workspace = workspace
        self.defaultBrowser = defaultBrowser
    }
}
