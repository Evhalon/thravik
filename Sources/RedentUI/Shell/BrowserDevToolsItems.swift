import SwiftUI

/// The Browser menu's developer item: Chrome's DevTools under the page in
/// front of the user. Kept in an existing menu rather than a Develop menu of
/// its own, which a full menu bar hides behind the camera housing.
struct BrowserDevToolsItems: View {
    let model: BrowserModel?

    var body: some View {
        Button((model?.isShowingDevTools ?? false) ? "Hide Developer Tools" : "Show Developer Tools") {
            model?.toggleDevTools()
        }
        .keyboardShortcut("i", modifiers: [.command, .option])
        .disabled(!(model?.canToggleDevTools ?? false))
        Button("JavaScript Console") { model?.toggleConsole() }
            .keyboardShortcut("j", modifiers: [.command, .option])
            .disabled(!(model?.canToggleDevTools ?? false))
    }
}
