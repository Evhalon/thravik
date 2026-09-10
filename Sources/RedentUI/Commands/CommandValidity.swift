import RedentKit

/// Whether an action the Command Bar is holding still makes sense.
///
/// Rows are built from a snapshot of the window; by the time one is pressed the
/// tab or Space it names may be gone. Kept apart from the model so the rule can
/// be read — and tested — on its own.
enum CommandValidity {
    static func isValid(_ action: BrowserAction, in context: CommandBarContext) -> Bool {
        switch action {
        case .focusTab(let id), .closeTab(let id), .pinTab(let id, _):
            context.tabs.contains { $0.id == id }
        case .focusSpace(let id), .deleteSpace(let id):
            context.spaces.contains { $0.id == id }
        case .renameSpace(let id, let name):
            !name.isEmpty && context.spaces.contains { $0.id == id }
        case .moveTab(let tabID, let spaceID):
            context.tabs.contains { $0.id == tabID } && context.spaces.contains { $0.id == spaceID }
        case .createSpace(let name):
            !name.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty
        // The page commands act on whatever the window is showing when they
        // run, so there is nothing in a stale snapshot to invalidate them.
        case .newTab, .navigate, .reopenLastClosed, .goBack, .goForward, .toggleFocusMode,
             .toggleSidebar, .reloadPage, .bookmarkPage, .findOnPage, .printPage, .showScreen:
            true
        }
    }
}
