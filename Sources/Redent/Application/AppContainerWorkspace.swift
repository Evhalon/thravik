import Foundation
import RedentKit

extension AppContainer {
    /// The window a link from another app lands in: the primary one, or
    /// whichever is open if that one is not.
    var primaryWindow: WindowContainer? {
        windows[.primary] ?? windows.values.first
    }

    func persist() {
        windows[.primary]?.model.persistSession()
    }

    func applyWorkspace(_ snapshot: WorkspaceSyncSnapshot) {
        let local = windows[.primary]?.model.durableSession() ?? startingSession(for: .primary)
        let application = WorkspaceSyncMerge.apply(local: local, snapshot: snapshot)
        if let model = windows[.primary]?.model {
            model.applySyncedWorkspace(application.session, remote: application.remoteTabs)
        } else if application.session != local {
            try? sessionStore.saveRecoverable(application.session)
        }
        workspace.model.replace(application.remoteTabs)
        if let catalog = snapshot.catalog { workspace.model.recordSyncedProfile(catalog.profile) }
    }
}
