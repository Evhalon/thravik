import Foundation

/// One row in the sidebar outline: a lone tab or a related/manual cluster.
public enum SidebarNode: Equatable, Sendable, Identifiable {
    /// A cluster's header is only a label: every tab in it, the opener of a
    /// popup included, is a member row, so selecting the header never means
    /// selecting a page.
    public struct Cluster: Equatable, Sendable, Identifiable {
        public let id: UUID
        public let name: String
        public let memberIDs: [UUID]
        /// True when the browser chose `name` (a site), so a better label
        /// may replace it; a name the user typed is kept as is.
        public let isNameAutomatic: Bool

        public init(id: UUID, name: String, memberIDs: [UUID], isNameAutomatic: Bool) {
            self.id = id
            self.name = name
            self.memberIDs = memberIDs
            self.isNameAutomatic = isNameAutomatic
        }
    }

    case tab(UUID)
    case cluster(Cluster)

    public var id: UUID {
        switch self {
        case .tab(let id): return id
        case .cluster(let cluster): return cluster.id
        }
    }

    /// Top-to-bottom ids as the sidebar draws this node.
    public var tabIDs: [UUID] {
        switch self {
        case .tab(let id): return [id]
        case .cluster(let cluster): return cluster.memberIDs
        }
    }
}
