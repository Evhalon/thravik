import Foundation
import RedentKit

/// Screens and Spaces: the places the browser keeps things.
enum LibraryCommandDescriptors {
    static let all: [CommandDescriptor] = screens + spaces

    private static let screens: [CommandDescriptor] = [
        CommandDescriptor(id: "downloads", title: "Downloads", keywords: ["files", "saved"], symbol: "arrow.down.circle") { _, _ in .showScreen(.downloads) },
        CommandDescriptor(id: "bookmarks", title: "Bookmarks", keywords: ["saved", "library"], symbol: "book") { _, _ in .showScreen(.bookmarks) },
        CommandDescriptor(id: "history", title: "History", keywords: ["visited", "recent"], symbol: "clock.arrow.circlepath") { _, _ in .showScreen(.history) },
        CommandDescriptor(id: "passwords", title: "Passwords", keywords: ["logins", "vault"], symbol: "key") { _, _ in .showScreen(.passwords) },
        CommandDescriptor(id: "settings", title: "Settings", keywords: ["preferences", "options"], symbol: "gearshape") { _, _ in .showScreen(.settings) }
    ]

    private static let spaces: [CommandDescriptor] = [
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
        }
    ]
}
