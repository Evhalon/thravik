import Foundation
import Observation
import RedentKit

/// Topic names for automatic tab groups, generated on the device. A name is
/// asked for once per membership, so a title settling or a page reloading
/// never asks again; a tab joining or leaving does.
@MainActor @Observable
final class GroupNameModel {
    private struct Entry {
        let members: Set<UUID>
        let name: String?
    }

    @ObservationIgnored private let naming: (any TabGroupNaming)?
    /// Long enough for a tab that just joined to have a title worth reading.
    @ObservationIgnored private let settleDelay: Duration
    private var entries: [UUID: Entry] = [:]

    init(naming: (any TabGroupNaming)?, settleDelay: Duration = .milliseconds(700)) {
        self.naming = naming
        self.settleDelay = settleDelay
    }

    /// The generated topic when there is one; the site the browser named the
    /// group after otherwise, or whatever the user typed.
    func displayName(for cluster: SidebarNode.Cluster, isEnabled: Bool) -> String {
        guard isEnabled, cluster.isNameAutomatic, let name = entries[cluster.id]?.name else { return cluster.name }
        return name
    }

    /// `pages` is read after the settle delay, not before, so it sees titles
    /// that loaded meanwhile. Cancelling — the membership changed again —
    /// leaves the previous name in place.
    func resolve(
        _ cluster: SidebarNode.Cluster,
        isEnabled: Bool,
        pages: @MainActor () -> [TabGroupPage]
    ) async {
        guard isEnabled, cluster.isNameAutomatic, let naming else { return }
        let members = Set(cluster.memberIDs)
        guard entries[cluster.id]?.members != members else { return }
        do { try await Task.sleep(for: settleDelay) } catch { return }
        let name = await naming.name(for: pages())
        guard !Task.isCancelled else { return }
        entries[cluster.id] = Entry(members: members, name: name)
    }
}
