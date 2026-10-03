import RedentKit
import SwiftUI

/// The Browser menu's developer item: Chrome's DevTools under the page in
/// front of the user. Kept in an existing menu rather than a Develop menu of
/// its own, which a full menu bar hides behind the camera housing.
struct BrowserDevToolsItems: View {
    let model: BrowserModel?
    let bindings: ShortcutBindings

    var body: some View {
        Button((model?.isShowingDevTools ?? false) ? "Hide Developer Tools" : "Show Developer Tools") {
            model?.toggleDevTools()
        }
        .shortcut(.toggleDevTools, bindings: bindings)
        .disabled(!(model?.canToggleDevTools ?? false))
        Button("JavaScript Console") { model?.toggleConsole() }
            .shortcut(.toggleConsole, bindings: bindings)
            .disabled(!(model?.canToggleDevTools ?? false))
    }
}
