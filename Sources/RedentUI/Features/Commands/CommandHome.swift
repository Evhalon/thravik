import Foundation
import RedentKit

/// What the bar lists before anything is typed: the other tabs in this
/// Space, the saved apps, then every command that applies right now.
enum CommandHome {
    /// Enough to switch by arrow key; the rest are a keystroke away.
    private static let tabLimit = 8

    static func rows(context: CommandBarContext, descriptors: [CommandDescriptor]) -> [CommandBarResult] {
        let others = context.tabs.filter { tab in
            tab.id != context.selectedTabID
                && (context.selectedSpaceID == nil || tab.spaceID == context.selectedSpaceID)
        }
        let commands = descriptors.compactMap { $0.row(in: context, query: "") }
        return others.prefix(tabLimit).map(CommandEntityRows.tabRow)
            + context.webApps.map(CommandEntityRows.appRow)
            + commands
    }
}
