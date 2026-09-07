import Foundation
import RedentKit

/// A command definition. The action builder keeps contextual IDs out of the
/// registry and lets the composition root inject additional commands.
public struct CommandDescriptor: Identifiable, Sendable {
    public let id: String
    public let title: String
    public let keywords: [String]
    public let symbol: String
    private let buildAction: @Sendable (CommandBarContext, String) -> BrowserAction?

    public init(
        id: String,
        title: String,
        keywords: [String] = [],
        symbol: String = "command",
        action: @escaping @Sendable (CommandBarContext, String) -> BrowserAction?
    ) {
        self.id = id
        self.title = title
        self.keywords = keywords
        self.symbol = symbol
        self.buildAction = action
    }

    public func action(in context: CommandBarContext, query: String = "") -> BrowserAction? {
        buildAction(context, query)
    }

    func matches(_ query: String) -> Bool {
        let text = query.trimmingCharacters(in: .whitespacesAndNewlines).lowercased()
        guard !text.isEmpty else { return true }
        let haystack = ([title] + keywords).joined(separator: " ").lowercased()
        let terms = text.split(separator: " ")
        let titleTerms = title.lowercased().split(separator: " ")
        let startsWithTitle = terms.count >= titleTerms.count
            && zip(terms, titleTerms).allSatisfy { $0 == $1 }
        return startsWithTitle || terms.allSatisfy { haystack.contains($0) }
    }
}

public enum DefaultCommandDescriptors {
    public static let all: [CommandDescriptor] = [
        CommandDescriptor(id: "new-tab", title: "New Tab", keywords: ["open", "create"], symbol: "plus") { _, _ in .newTab(nil) },
        CommandDescriptor(id: "close-tab", title: "Close Tab", keywords: ["remove"], symbol: "xmark") { context, _ in
            context.selectedTabID.map(BrowserAction.closeTab)
        },
        CommandDescriptor(id: "reopen-tab", title: "Reopen Closed Tab", keywords: ["restore", "undo"], symbol: "arrow.uturn.backward") { context, _ in
            context.canReopenLastClosed ? .reopenLastClosed : nil
        },
        CommandDescriptor(id: "pin-tab", title: "Pin Current Tab", keywords: ["unpin", "favorite"], symbol: "pin") { context, _ in
            guard let id = context.selectedTabID,
                  let tab = context.tabs.first(where: { $0.id == id }) else { return nil }
            return .pinTab(id, isPinned: !tab.isPinned)
        },
        CommandDescriptor(id: "focus-mode", title: "Toggle Focus Mode", keywords: ["distraction", "chrome"], symbol: "rectangle.inset.filled") { _, _ in
            .toggleFocusMode
        },
        CommandDescriptor(id: "sidebar", title: "Toggle Sidebar", keywords: ["rail", "tabs", "layout"], symbol: "sidebar.left") { _, _ in
            .toggleSidebar
        },
        CommandDescriptor(id: "create-space", title: "Create Space", keywords: ["new"], symbol: "plus.square") { _, query in
            CommandArguments.after("create space", in: query).map(BrowserAction.createSpace)
        },
        CommandDescriptor(id: "rename-space", title: "Rename Space", keywords: ["edit"], symbol: "pencil") { context, query in
            guard let id = context.selectedSpaceID,
                  let name = CommandArguments.after("rename space", in: query) else { return nil }
            return .renameSpace(id: id, name: name)
        },
        CommandDescriptor(id: "delete-space", title: "Delete Space", keywords: ["remove"], symbol: "trash") { context, _ in
            guard context.spaces.count > 1, let id = context.selectedSpaceID else { return nil }
            return .deleteSpace(id)
        },
        CommandDescriptor(id: "move-tab", title: "Move Tab", keywords: ["space", "to"], symbol: "arrow.right") { context, query in
            guard let tabID = context.selectedTabID,
                  let name = CommandArguments.after("move tab to", in: query),
                  let spaceID = context.spaces.first(where: { $0.name.caseInsensitiveCompare(name) == .orderedSame })?.id
            else { return nil }
            return .moveTab(tabID: tabID, spaceID: spaceID)
        }
    ]
}

private enum CommandArguments {
    static func after(_ prefix: String, in query: String) -> String? {
        guard query.lowercased().hasPrefix(prefix) else { return nil }
        let value = String(query.dropFirst(prefix.count)).trimmingCharacters(in: .whitespacesAndNewlines)
        return value.isEmpty ? nil : value
    }
}
