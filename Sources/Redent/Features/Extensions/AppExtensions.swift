import RedentEngine
import RedentUI
import RedentVault

/// The app's one extension host and the settings model that manages it.
/// One for the whole app: an extension's background page and storage are
/// shared by every window, as in Chrome.
@MainActor
struct AppExtensions {
    let host: ExtensionHost
    let model: ExtensionsModel

    init() {
        host = ExtensionHost(
            filesDirectory: JSONExtensionIndexStore.defaultFilesDirectory(),
            index: JSONExtensionIndexStore()
        )
        model = ExtensionsModel(host: host)
    }
}
