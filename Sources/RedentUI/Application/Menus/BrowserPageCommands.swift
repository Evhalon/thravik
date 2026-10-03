import RedentKit
import SwiftUI

/// The History menu: where the page has been, and how it is reloaded.
///
/// Named for what macOS browsers call it, so ⌘[ and ⌘R sit where a user's
/// hands already expect them.
struct BrowserPageCommands: Commands {
    let model: BrowserModel?
    let bindings: ShortcutBindings

    var body: some Commands {
        CommandMenu("History") {
            Button("Back") { model?.goBack() }
                .shortcut(.goBack, bindings: bindings)
                .disabled(!(model?.canGoBack ?? false))
            Button("Forward") { model?.goForward() }
                .shortcut(.goForward, bindings: bindings)
                .disabled(!(model?.canGoForward ?? false))
            Divider()
            Button("Reload Page") { model?.reloadPage() }
                .shortcut(.reload, bindings: bindings)
                .disabled(!(model?.hasPage ?? false))
            Button("Reload Ignoring Cache") { model?.reloadIgnoringCache() }
                .shortcut(.hardReload, bindings: bindings)
                .disabled(!(model?.hasPage ?? false))
            Button("Stop Loading") { model?.stopLoading() }
                .shortcut(.stopLoading, bindings: bindings)
                .disabled(!(model?.isPageLoading ?? false))
            Divider()
            Button("Home") { model?.goHome() }
                .shortcut(.goHome, bindings: bindings)
                .disabled(model == nil)
            RecentlyClosedMenuItems(
                entries: model?.tabs.recentlyClosed ?? [],
                reopen: { model?.tabs.reopenClosed($0) }
            )
            .disabled(model == nil)
            Button("Show All History…") { model?.sheet = .history }
                .shortcut(.showHistory, bindings: bindings)
                .disabled(model == nil)
        }
    }
}
