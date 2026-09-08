import Foundation
import RedentKit

/// Installs a release shipped as a `.dmg`, the way Thravik publishes them.
///
/// Nothing touches the installed app while this runs: the new bundle is
/// downloaded, verified and parked in a temporary directory, and only a helper
/// armed at the very end does the swap — after the caller quits.
public struct DiskImageInstaller: UpdateInstalling {
    private let target: URL
    private let identifier: String
    private let session: URLSession

    /// Defaults describe the running app; the parameters exist so tests and the
    /// composition root can point somewhere else.
    public init(target: URL = Bundle.main.bundleURL,
                identifier: String = Bundle.main.bundleIdentifier ?? "",
                session: URLSession = .shared) {
        self.target = target
        self.identifier = identifier
        self.session = session
    }

    public func stage(_ release: AppRelease) async throws {
        try ensureReplaceable()
        let work = try makeWorkDirectory()
        do {
            let image = try await download(release.downloadURL, into: work)
            let staged = try await DiskImageUnpacker.stageApp(
                from: image, into: work, expecting: identifier
            )
            try armRelaunch(stagedApp: staged, in: work)
        } catch {
            try? FileManager.default.removeItem(at: work)
            throw error
        }
    }

    /// Fails early rather than after a download: an app inside a read-only
    /// mount or a locked-down /Applications can never replace itself.
    private func ensureReplaceable() throws {
        let parent = target.deletingLastPathComponent()
        guard FileManager.default.isWritableFile(atPath: parent.path) else {
            throw UpdateError.destinationNotWritable(parent.path)
        }
    }

    private func makeWorkDirectory() throws -> URL {
        let work = URL(fileURLWithPath: NSTemporaryDirectory(), isDirectory: true)
            .appendingPathComponent("thravik-update-\(UUID().uuidString)", isDirectory: true)
        try FileManager.default.createDirectory(at: work, withIntermediateDirectories: true)
        return work
    }

    private func download(_ url: URL, into directory: URL) async throws -> URL {
        let (temporary, response) = try await downloaded(url)
        if let http = response as? HTTPURLResponse, http.statusCode != 200 {
            throw UpdateError.downloadStatus(http.statusCode)
        }
        let image = directory.appendingPathComponent("update.dmg")
        try FileManager.default.moveItem(at: temporary, to: image)
        return image
    }

    private func downloaded(_ url: URL) async throws -> (URL, URLResponse) {
        do {
            return try await session.download(from: url)
        } catch {
            throw UpdateError.feedUnreachable
        }
    }

    /// Writes the helper and starts it detached. It blocks on our PID, so
    /// nothing is replaced until the app actually quits.
    private func armRelaunch(stagedApp: URL, in work: URL) throws {
        let script = work.appendingPathComponent("relaunch.sh")
        let source = RelaunchScript.source(
            stagedApp: stagedApp, target: target, pid: ProcessInfo.processInfo.processIdentifier
        )
        try source.write(to: script, atomically: true, encoding: .utf8)
        try Shell.spawn("/bin/sh", [script.path])
    }
}
