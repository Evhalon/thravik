import Foundation

/// Decides how a popup relates to the page that opened it.
public enum RelatedTabGrouping: Sendable {
    public enum Outcome: Equatable, Sendable {
        /// Parent already belongs to a group; the child copies that membership.
        case joinExisting
        /// First related child: name a group after the parent's site and put both in it.
        case create(name: String, tabIDs: [UUID])
        /// Temporary pages stay out of persisted groups.
        case skip
    }

    public static func outcome(parent: TabSnapshot, child: TabSnapshot) -> Outcome {
        if parent.isTemporary || child.isTemporary { return .skip }
        if parent.groupID != nil { return .joinExisting }
        let name = parent.origin?.displayHost ?? parent.displayTitle
        return .create(name: name, tabIDs: [parent.id, child.id])
    }
}
