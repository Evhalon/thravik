import Foundation
import RedentKit

enum PageCommandDescriptors {
    static let all: [CommandDescriptor] = navigation + zoom + page

    private static let navigation: [CommandDescriptor] = [
        CommandDescriptor(id: "back", title: "Go Back", keywords: ["previous", "history"], symbol: "chevron.backward") { context, _ in
            hasPage(context) ? .goBack : nil
        },
        CommandDescriptor(id: "forward", title: "Go Forward", keywords: ["next", "history"], symbol: "chevron.forward") { context, _ in
            hasPage(context) ? .goForward : nil
        },
        CommandDescriptor(id: "reload", title: "Reload Page", keywords: ["refresh"], symbol: "arrow.clockwise") { _, _ in .reloadPage },
        CommandDescriptor(id: "hard-reload", title: "Hard Reload", keywords: ["refresh", "cache", "force"], symbol: "arrow.clockwise.icloud") { context, _ in
            hasPage(context) ? .hardReload : nil
        }
    ]

    private static let zoom: [CommandDescriptor] = [
        CommandDescriptor(id: "zoom-in", title: "Zoom In", keywords: ["bigger", "larger", "magnify"], symbol: "plus.magnifyingglass") { context, _ in
            hasPage(context) ? .zoomIn : nil
        },
        CommandDescriptor(id: "zoom-out", title: "Zoom Out", keywords: ["smaller"], symbol: "minus.magnifyingglass") { context, _ in
            hasPage(context) ? .zoomOut : nil
        },
        CommandDescriptor(id: "zoom-reset", title: "Actual Size", keywords: ["zoom", "reset", "100%"], symbol: "1.magnifyingglass") { context, _ in
            hasPage(context) ? .resetZoom : nil
        }
    ]

    private static let page: [CommandDescriptor] = [
        CommandDescriptor(id: "bookmark", title: "Bookmark Page", keywords: ["save", "star", "favorite"], symbol: "star") { _, _ in .bookmarkPage },
        CommandDescriptor(id: "find", title: "Find on Page", keywords: ["search", "text"], symbol: "text.magnifyingglass") { _, _ in .findOnPage },
        CommandDescriptor(id: "reader", title: "Toggle Reader", keywords: ["read", "article", "clean"], symbol: "text.page") { _, _ in .toggleReader },
        CommandDescriptor(id: "mute", title: "Mute or Unmute Tab", keywords: ["sound", "audio", "silence"], symbol: "speaker.slash") { _, _ in .toggleMute },
        CommandDescriptor(id: "print", title: "Print Page", keywords: ["pdf", "paper"], symbol: "printer") { _, _ in .printPage },
        CommandDescriptor(id: "site-data", title: "Clear Current Site's Data…", keywords: ["cookies", "storage", "forget", "privacy"], symbol: "hand.raised") { context, _ in
            hasPage(context) ? .showScreen(.siteData) : nil
        },
        CommandDescriptor(id: "open-as-app", title: "Open Current Website as App", keywords: ["web app", "save", "install", "pwa"], symbol: "app.badge") { context, _ in
            guard hasPage(context), !context.isPrivate else { return nil }
            return existingApp(context).map { .openWebApp($0.id) } ?? .saveWebApp
        },
        CommandDescriptor(id: "remove-app", title: "Remove Current Website App", keywords: ["web app", "forget", "delete"], symbol: "app.dashed") { context, _ in
            existingApp(context).map { .removeWebApp($0.id) }
        }
    ]

    private static func hasPage(_ context: CommandBarContext) -> Bool {
        context.selectedTab?.url != nil
    }

    private static func existingApp(_ context: CommandBarContext) -> WebApp? {
        guard let url = context.selectedTab?.url else { return nil }
        return context.webApps.first { $0.isSameSite(as: url) }
    }
}
