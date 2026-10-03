import Foundation

extension ShortcutBindings {
    /// Mirrors the hard-coded menu shortcuts that shipped before this setting.
    public static let defaults: [ShortcutID: KeyChord] = windowDefaults
        .merging(tabDefaults) { _, new in new }
        .merging(pageDefaults) { _, new in new }
        .merging(viewDefaults) { _, new in new }
        .merging(libraryDefaults) { _, new in new }

    private static let windowDefaults: [ShortcutID: KeyChord] = [
        .settings: .command(","),
        .commandBar: .command("k"),
        .undoBrowserAction: KeyChord(key: "z", modifiers: [.command, .option]),
        .newWindow: .command("n"),
        .newPrivateWindow: KeyChord(key: "n", modifiers: [.command, .shift]),
        .newTab: .command("t"),
        .newPrivateTab: KeyChord(key: "n", modifiers: [.command, .control]),
        .closeTab: .command("w"),
        .reopenClosedTab: KeyChord(key: "t", modifiers: [.command, .shift])
    ]

    private static let tabDefaults: [ShortcutID: KeyChord] = [
        .nextTab: .command("j"),
        .previousTab: KeyChord(key: "tab", modifiers: [.control, .shift]),
        .lastActiveTab: KeyChord(key: "tab", modifiers: .control),
        .selectTabRight: KeyChord(key: "]", modifiers: [.command, .shift]),
        .selectTabLeft: KeyChord(key: "[", modifiers: [.command, .shift]),
        .pinTab: KeyChord(key: "p", modifiers: [.command, .shift]),
        .closeOtherTabs: KeyChord(key: "w", modifiers: [.command, .option]),
        .muteTab: KeyChord(key: "m", modifiers: .control)
    ]

    private static let pageDefaults: [ShortcutID: KeyChord] = [
        .reload: .command("r"),
        .findOnPage: .command("f"),
        .findNext: .command("g"),
        .findPrevious: KeyChord(key: "g", modifiers: [.command, .shift]),
        .closeFind: KeyChord(key: "escape", modifiers: []),
        .fillLogin: .command("\\"),
        .openLocation: .command("l"),
        .copyURL: KeyChord(key: "c", modifiers: [.command, .shift]),
        .pasteAndGo: KeyChord(key: "v", modifiers: [.command, .shift]),
        .print: .command("p"),
        .goBack: .command("["),
        .goForward: .command("]"),
        .hardReload: KeyChord(key: "r", modifiers: [.command, .shift]),
        .stopLoading: .command("."),
        .goHome: KeyChord(key: "h", modifiers: [.command, .shift])
    ]
}
