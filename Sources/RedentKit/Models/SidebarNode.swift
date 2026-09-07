import Foundation

/// One row in the sidebar outline: a lone tab or a related/manual cluster.
public enum SidebarNode: Equatable, Sendable, Identifiable {
    public struct Cluster: Equatable, Sendable, Identifiable {
        public let id: UUID
        public let name: String
        public let headerTabID: UUID?
        public let memberIDs: [UUID]
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
        case .cluster(let cluster):
            if let header = cluster.headerTabID { return [header] + cluster.memberIDs }
            return cluster.memberIDs
        }
    }
}
