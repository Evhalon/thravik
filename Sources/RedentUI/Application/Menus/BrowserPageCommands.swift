import SwiftUI

/// The History menu: where the page has been, and how it is reloaded.
///
/// Named for what macOS browsers call it, so ⌘[ and ⌘R sit where a user's
/// hands already expect them.
struct BrowserPageCommands: Commands {
    let model: BrowserModel?

    var body: some Commands {
        CommandMenu("History") {
            Button("Back") { model?.goBack() }
                .keyboardShortcut("[", modifiers: .command)
                .disabled(!(model?.canGoBack ?? false))
            Button("Forward") { model?.goForward() }
                .keyboardShortcut("]", modifiers: .command)
                .disabled(!(model?.canGoForward ?? false))
            Divider()
            Button("Reload Page") { model?.reloadPage() }
                .keyboardShortcut("r")
                .disabled(!(model?.hasPage ?? false))
            Button("Reload Ignoring Cache") { model?.reloadIgnoringCache() }
                .keyboardShortcut("r", modifiers: [.command, .shift])
                .disabled(!(model?.hasPage ?? false))
            Button("Stop Loading") { model?.stopLoading() }
                .keyboardShortcut(".", modifiers: .command)
                .disabled(!(model?.isPageLoading ?? false))
            Divider()
            Button("Home") { model?.goHome() }
                .keyboardShortcut("h", modifiers: [.command, .shift])
                .disabled(model == nil)
            Button("Show All History…") { model?.sheet = .history }
                .keyboardShortcut("y")
                .disabled(model == nil)
        }
    }
}
