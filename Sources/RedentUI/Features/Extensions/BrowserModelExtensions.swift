import Foundation
import RedentKit
import SwiftUI

extension BrowserModel {
    /// The store opens as an ordinary tab, leaving Settings for the page.
    func openExtensionStore() {
        guard let url = ExtensionsModel.storeURL else { return }
        closeSettings()
        tabs.newTab(url: url)
    }
}

extension EnvironmentValues {
    /// The extensions' toolbar buttons for this window, built by the
    /// composition root from the engine; nil in private windows and previews.
    @Entry public var extensionToolbar: AnyView?
}
