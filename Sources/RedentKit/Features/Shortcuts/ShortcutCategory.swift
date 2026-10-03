import Foundation

/// Settings grouping for the shortcut list.
public enum ShortcutCategory: String, CaseIterable, Sendable, Identifiable {
    case general = "GENERAL"
    case tabs = "TABS"
    case page = "PAGE"
    case find = "FIND"
    case view = "VIEW"
    case library = "LIBRARY"

    public var id: String { rawValue }
}
