import Foundation

/// What an undo record is allowed to rewind. Editing a Space and rearranging
/// tabs share one history, but undoing one must never rewind the other.
public enum UndoScope: Sendable, Hashable {
    case tabs
    case spaces
}

extension WorkspaceAction {
    public var undoScope: UndoScope {
        switch self {
        case .createSpace, .renameSpace, .setSpaceLook, .moveSpace, .deleteSpace: .spaces
        default: .tabs
        }
    }
}
