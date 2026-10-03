import RedentKit
import RedentUI

extension AppContainer {
    func wireManagedPolicy() {
        managedPolicy.onChange = { [weak self] in self?.refreshManagedPolicyOnAllWindows() }
        workspace.syncAllowed = managedPolicy.accountSyncAllowed
        bookmarkSync.syncAllowed = managedPolicy.accountSyncAllowed
        extensions.model.allowsExtensionInstall = { [managedPolicy] id in
            ManagedExtensionInstallPolicy.allowsInstall(storeID: id, policy: managedPolicy.policy)
        }
        extensions.model.restrictsExtensionInstalls = { [managedPolicy] in
            ManagedExtensionInstallPolicy.restrictsInstalls(managedPolicy.policy)
        }
    }

    /// Rebuilt from the stored user settings, so a removed policy hands every
    /// field back to the user rather than leaving the managed value behind.
    func applyManagedPolicy(to window: WindowContainer) {
        let settings = settingsStore.load()
        window.model.managedPolicyLocks = managedPolicy.locked
        window.model.settings = settings
        window.tabs.apply(settings: settings)
        window.model.autofill.setEnabled(settings.offersPasswordSave)
        window.tabs.managedURLBlocker = { [weak self] url in
            self?.managedPolicy.urlIsBlocked(url) ?? false
        }
        wireManagedPolicyHooks(on: window.model)
    }

    func refreshManagedPolicyOnAllWindows() {
        workspace.syncAllowed = managedPolicy.accountSyncAllowed
        bookmarkSync.syncAllowed = managedPolicy.accountSyncAllowed
        for window in windows.values { applyManagedPolicy(to: window) }
    }

    private func wireManagedPolicyHooks(on model: BrowserModel) {
        model.privateWindowsAllowed = { [managedPolicy] in managedPolicy.privateWindowsAllowed }
        model.accountSyncAllowed = { [managedPolicy] in managedPolicy.accountSyncAllowed }
    }
}
