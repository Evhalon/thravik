import Foundation

/// Result of writing one binding. Conflicts list every other owner of that chord.
public enum ShortcutChange: Equatable, Sendable {
    case applied
    case reserved
    case conflict([ShortcutID])
}
