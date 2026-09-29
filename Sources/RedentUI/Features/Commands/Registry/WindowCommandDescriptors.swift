import Foundation
import RedentKit

enum WindowCommandDescriptors {
    static let all: [CommandDescriptor] = [
        CommandDescriptor(id: "new-window", title: "New Window", keywords: ["create", "open"], symbol: "macwindow.badge.plus") { _, _ in
            .newWindow
        },
        CommandDescriptor(id: "new-private-window", title: "New Private Window", keywords: ["incognito", "secret"], symbol: "eyeglasses") { _, _ in
            .newPrivateWindow
        },
        CommandDescriptor(id: "switch-window", title: "Switch Window…", keywords: ["windows", "focus"], symbol: "macwindow.on.rectangle",
                          completion: "window "),
        CommandDescriptor(id: "move-tab-new-window", title: "Move Tab to New Window", keywords: ["detach", "split off"], symbol: "rectangle.portrait.and.arrow.right") { context, _ in
            guard let tab = context.selectedTab, tab.url != nil else { return nil }
            return .moveTabToWindow(tabID: tab.id, windowID: nil)
        },
        CommandDescriptor(id: "close-window", title: "Close Window", keywords: ["quit"], symbol: "xmark.rectangle") { _, _ in
            .closeWindow
        },
        CommandDescriptor(id: "full-screen", title: "Toggle Full Screen", keywords: ["fullscreen", "enter", "exit"], symbol: "arrow.up.left.and.arrow.down.right") { _, _ in
            .toggleFullScreen
        },
        CommandDescriptor(id: "focus-mode", title: "Toggle Focus Mode", keywords: ["distraction", "chrome"], symbol: "rectangle.inset.filled") { _, _ in
            .toggleFocusMode
        },
        CommandDescriptor(id: "sidebar", title: "Toggle Sidebar", keywords: ["rail", "tabs", "layout"], symbol: "sidebar.left") { _, _ in
            .toggleSidebar
        }
    ]
}
