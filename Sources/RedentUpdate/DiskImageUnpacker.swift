import Foundation

/// Turns a downloaded disk image into a verified app on local disk.
///
/// Verification runs while the image is still mounted read-only, and the copy
/// is only made once it passes — so nothing that failed a check ever lands in
/// a directory the relaunch helper will read from.
enum DiskImageUnpacker {
    static func stageApp(from image: URL, into directory: URL, expecting identifier: String) async throws -> URL {
        let mount = directory.appendingPathComponent("mount", isDirectory: true)
        try FileManager.default.createDirectory(at: mount, withIntermediateDirectories: true)
        try await Shell.run("/usr/bin/hdiutil", [
            "attach", image.path, "-nobrowse", "-readonly", "-noverify", "-mountpoint", mount.path
        ])
        do {
            let staged = try await copyVerifiedApp(from: mount, into: directory, expecting: identifier)
            try await detach(mount)
            return staged
        } catch {
            // Unmount before the caller deletes the work directory the mount
            // point lives in, or the image stays attached for the session.
            try? await detach(mount)
            throw error
        }
    }

    private static func copyVerifiedApp(from mount: URL, into directory: URL, expecting identifier: String) async throws -> URL {
        let app = try locateApp(in: mount)
        try await verify(app, expecting: identifier)
        let staged = directory.appendingPathComponent(app.lastPathComponent, isDirectory: true)
        try? FileManager.default.removeItem(at: staged)
        try await Shell.run("/usr/bin/ditto", [app.path, staged.path])
        // A URLSession download carries no quarantine flag, so this is a
        // defensive no-op — but a quarantined bundle is refused at launch and
        // would leave the user with no browser at all.
        _ = await Shell.succeeds("/usr/bin/xattr", ["-dr", "com.apple.quarantine", staged.path])
        return staged
    }

    private static func detach(_ mount: URL) async throws {
        try await Shell.run("/usr/bin/hdiutil", ["detach", mount.path, "-force"])
    }

    private static func locateApp(in mount: URL) throws -> URL {
        let contents = try FileManager.default.contentsOfDirectory(
            at: mount, includingPropertiesForKeys: nil, options: [.skipsHiddenFiles]
        )
        guard let app = contents.first(where: { $0.pathExtension == "app" }) else {
            throw UpdateError.noAppInDiskImage
        }
        return app
    }

    /// The signature proves the bundle arrived intact; the identifier proves it
    /// is this app. Builds are ad-hoc signed, so neither proves who made it —
    /// that rests on the HTTPS link the release feed handed us.
    private static func verify(_ app: URL, expecting identifier: String) async throws {
        guard await Shell.succeeds("/usr/bin/codesign", ["--verify", "--deep", "--strict", app.path]) else {
            throw UpdateError.signatureRejected
        }
        guard let bundle = Bundle(url: app), bundle.bundleIdentifier == identifier else {
            throw UpdateError.identityMismatch
        }
    }
}
