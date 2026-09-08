import Foundation

/// The isolation rule, in one place: a tab browses in its Space's Container
/// and nowhere else. Applied after every action, so moving a tab between
/// Spaces moves it between cookie jars and the engine rebuilds its view.
extension WorkspaceState {
    mutating func normalizeContainers() {
        for index in session.tabs.indices {
            guard let spaceID = session.tabs[index].spaceID else { continue }
            session.tabs[index].containerID = SpaceIdentity.containerID(for: spaceID)
        }
    }
}
