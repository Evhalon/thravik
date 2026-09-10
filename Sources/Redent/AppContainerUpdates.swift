import Foundation
import RedentKit
import RedentUI
import RedentUpdate

/// How the app updates itself, and what has to be cleared before it can.
extension AppContainer {
    /// Releases are published as signed disk images on GitHub; the installer
    /// swaps the running bundle and reopens it once this process exits.
    var updates: UpdateModel {
        if let updatesStorage { return updatesStorage }
        let created = UpdateModel(
            currentVersion: Self.installedVersion(),
            checker: GitHubReleaseFeed(repository: "Evhalon/thravik"),
            installer: DiskImageInstaller(),
            // The restart is asked for from inside a sheet a window presents, so
            // every window's binding has to be cleared before AppKit will
            // terminate — not just the one the button was pressed in.
            quit: { [weak self] in
                AppTermination.quit(dismissing: { self?.dismissAllPresentations() })
            }
        )
        updatesStorage = created
        return created
    }

    /// Every window's sheet binding, cleared at once — the precondition for
    /// AppKit letting the process go.
    func dismissAllPresentations() {
        for window in windows.values { window.model.dismissPresentations() }
    }

    /// `nil` under `swift run`, which has no Info.plist and so no version to
    /// compare — a dev build is never offered an update.
    static func installedVersion() -> AppVersion? {
        installedVersionString().flatMap(AppVersion.init)
    }

    /// The raw string, which the default-browser offer compares literally
    /// rather than as an ordered version.
    static func installedVersionString() -> String? {
        Bundle.main.infoDictionary?["CFBundleShortVersionString"] as? String
    }
}
