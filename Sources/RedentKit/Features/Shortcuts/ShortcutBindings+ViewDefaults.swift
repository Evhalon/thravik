import Foundation

extension ShortcutBindings {
    static let viewDefaults: [ShortcutID: KeyChord] = [
        .toggleTabLayout: .command("s"),
        .toggleSidebar: .command("b"),
        .toggleTabStrip: .command("\\"),
        .showBookmarksBar: KeyChord(key: "b", modifiers: [.command, .shift]),
        .focusMode: KeyChord(key: "f", modifiers: [.command, .shift]),
        .toggleReader: KeyChord(key: "r", modifiers: [.command, .control]),
        .floatVideo: KeyChord(key: "v", modifiers: [.command, .control]),
        .zoomIn: .command("+"),
        .zoomOut: .command("-"),
        .zoomReset: .command("0"),
        .splitView: KeyChord(key: "d", modifiers: [.command, .shift]),
        .addPane: KeyChord(key: "d", modifiers: [.command, .option]),
        .switchPane: KeyChord(key: "]", modifiers: [.command, .option])
    ]

    static let libraryDefaults: [ShortcutID: KeyChord] = [
        .showHistory: .command("y"),
        .bookmarkPage: .command("d"),
        .showBookmarks: KeyChord(key: "b", modifiers: [.command, .option]),
        .showDownloads: KeyChord(key: "j", modifiers: [.command, .shift]),
        .showTimeline: KeyChord(key: "y", modifiers: [.command, .shift]),
        .showSitePrivacy: KeyChord(key: "i", modifiers: [.command, .shift]),
        .toggleDevTools: KeyChord(key: "i", modifiers: [.command, .option]),
        .toggleConsole: KeyChord(key: "j", modifiers: [.command, .option]),
        .showTabGroups: KeyChord(key: "g", modifiers: [.control, .option])
    ]
}
