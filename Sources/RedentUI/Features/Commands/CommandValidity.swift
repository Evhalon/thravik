import Foundation
import RedentKit

/// Whether an action the Command Bar is holding still makes sense.
///
/// Rows are built from a snapshot of the window; by the time one is pressed the
/// tab or Space it names may be gone. Kept apart from the model so the rule can
/// be read — and tested — on its own.
enum CommandValidity {
    static func isValid(_ action: BrowserAction, in context: CommandBarContext) -> Bool {
        if let valid = targetsValid(action, in: context) { return valid }
        return true
    }

    /// Nil for an action that names nothing: the page and window commands act
    /// on whatever the window shows when they run, so a stale snapshot cannot
    /// invalidate them.
    private static func targetsValid(_ action: BrowserAction, in context: CommandBarContext) -> Bool? {
        switch action {
        case .focusTab(let id), .closeTab(let id), .pinTab(let id, _), .duplicateTab(let id):
            hasTab(id, context)
        case .closeTabs(let ids):
            !ids.isEmpty && ids.allSatisfy { hasTab($0, context) }
        case .focusSpace(let id), .deleteSpace(let id):
            hasSpace(id, context)
        case .renameSpace(let id, let name):
            !name.isEmpty && hasSpace(id, context)
        case .moveTab(let tabID, let spaceID):
            hasTab(tabID, context) && hasSpace(spaceID, context)
        case .moveTabToGroup(let tabID, let groupID):
            hasTab(tabID, context) && context.groups.contains { $0.id == groupID }
        case .createSpace(let name):
            !name.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty
        case .focusWindow(let id):
            context.windows.contains { $0.id == id && !$0.isCurrent }
        case .moveTabToWindow(let tabID, let windowID):
            hasTab(tabID, context) && (windowID.map { id in context.windows.contains { $0.id == id } } ?? true)
        case .openWebApp(let id), .removeWebApp(let id):
            context.webApps.contains { $0.id == id }
        default:
            nil
        }
    }

    private static func hasTab(_ id: UUID, _ context: CommandBarContext) -> Bool {
        context.tabs.contains { $0.id == id }
    }

    private static func hasSpace(_ id: UUID, _ context: CommandBarContext) -> Bool {
        context.spaces.contains { $0.id == id }
    }
}
