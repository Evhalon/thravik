import Foundation
import Observation
import RedentKit

/// Drives the Updates pane: one check, one install, one restart.
///
/// It never installs on its own. A background check is cheap and quiet; a
/// background swap of the app under the user's hands is not.
@MainActor
@Observable
public final class UpdateModel {
    public enum Phase: Equatable {
        case idle
        case checking
        case upToDate
        case available(AppRelease)
        case installing
        /// Staged and armed. The swap happens as the app quits.
        case restarting
        case failed(String)
    }

    public private(set) var phase: Phase = .idle
    /// `nil` for a build with no `CFBundleShortVersionString`, which is every
    /// `swift run`. Such a build is never offered an update: there is nothing
    /// to compare against, and replacing a dev build would be wrong anyway.
    public let currentVersion: AppVersion?

    private let checker: any UpdateChecking
    private let installer: any UpdateInstalling
    private let quit: @MainActor () -> Void

    public init(
        currentVersion: AppVersion?,
        checker: any UpdateChecking,
        installer: any UpdateInstalling,
        quit: @escaping @MainActor () -> Void
    ) {
        self.currentVersion = currentVersion
        self.checker = checker
        self.installer = installer
        self.quit = quit
    }

    public var isBusy: Bool {
        phase == .checking || phase == .installing || phase == .restarting
    }

    public func check() async {
        guard !isBusy else { return }
        guard let currentVersion else {
            phase = .failed("This build has no version number, so it cannot be compared.")
            return
        }
        phase = .checking
        do {
            let release = try await checker.latestRelease()
            phase = release.version > currentVersion ? .available(release) : .upToDate
        } catch {
            phase = .failed(error.localizedDescription)
        }
    }

    /// Stages the release, then quits — the helper armed by `stage` reopens the
    /// app once this process is gone. A failure leaves the running app alone.
    public func installAndRestart(_ release: AppRelease) async {
        guard !isBusy else { return }
        phase = .installing
        do {
            try await installer.stage(release)
            phase = .restarting
            quit()
        } catch {
            phase = .failed(error.localizedDescription)
        }
    }
}
