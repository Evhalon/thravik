import AppKit
import CoreServices
import Foundation
import RedentKit
import RedentUpdate

enum WebAppInstallError: Error, Equatable {
    case launcherMissing
    case applicationsFolderUnavailable
    case iconUnavailable
}

/// Writes each web app as a real app in `~/Applications/<Browser> Apps`: the
/// launcher executable, an Info.plist of its own, and the site's icon. Finder,
/// Spotlight, Launchpad and the Dock then treat it like any other app.
struct WebAppBundleInstaller: WebAppInstalling {
    let host: WebAppHost
    let logger: any EventLogging

    func install(_ app: WebApp) async throws {
        guard let launcher = host.launcher else { throw WebAppInstallError.launcherMissing }
        let manifest = WebAppBundleManifest(app: app, host: host)
        let favicon = await WebAppIconSource.bestIcon(for: app)
        guard let icon = WebAppIconRenderer.icns(favicon: favicon, name: manifest.displayName) else {
            throw WebAppInstallError.iconUnavailable
        }
        let directory = try appsDirectory()
        let staging = FileManager.default.temporaryDirectory.appending(path: "\(UUID().uuidString).app")
        defer { try? FileManager.default.removeItem(at: staging) }
        try writeBundle(at: staging, manifest: manifest, launcher: launcher, icon: icon)
        // Ad hoc: the copied launcher's signature does not cover this bundle's
        // Info.plist, and Apple silicon will not run code whose seal is broken.
        try await Shell.run("/usr/bin/codesign", ["--force", "--sign", "-", staging.path])
        for stale in installedBundles(for: app.id) { try? FileManager.default.removeItem(at: stale) }
        let destination = directory.appending(path: manifest.bundleFileName)
        try? FileManager.default.removeItem(at: destination)
        try FileManager.default.moveItem(at: staging, to: destination)
        LSRegisterURL(destination as CFURL, true)
        logger.notice("webApp: installed")
    }

    func launch(_ app: WebApp) async {
        if installedBundles(for: app.id).isEmpty {
            do { try await install(app) } catch {
                logger.error("webApp: install failed — \(String(describing: error))")
                return
            }
        }
        let identifier = WebAppBundleManifest(app: app, host: host).bundleIdentifier
        // Opening a running app sends it a reopen, which it forwards straight
        // back here as a request for its window.
        guard NSRunningApplication.runningApplications(withBundleIdentifier: identifier).isEmpty,
              let bundle = installedBundles(for: app.id).first else { return }
        let configuration = NSWorkspace.OpenConfiguration()
        // The browser already shows the window; the app only takes its place
        // in the Dock, it does not take focus from it.
        configuration.activates = false
        _ = try? await NSWorkspace.shared.openApplication(at: bundle, configuration: configuration)
    }

    func uninstall(_ app: WebApp) async {
        for bundle in installedBundles(for: app.id) {
            try? FileManager.default.trashItem(at: bundle, resultingItemURL: nil)
        }
    }

    private func appsDirectory() throws -> URL {
        guard let applications = FileManager.default.urls(for: .applicationDirectory, in: .userDomainMask).first
        else { throw WebAppInstallError.applicationsFolderUnavailable }
        let directory = applications.appending(path: "\(host.name) Apps", directoryHint: .isDirectory)
        try FileManager.default.createDirectory(at: directory, withIntermediateDirectories: true)
        return directory
    }

    /// Found by the id in their Info.plist rather than by name, so a renamed
    /// app or one the user moved within the folder is still recognised.
    private func installedBundles(for id: UUID) -> [URL] {
        guard let directory = try? appsDirectory(),
              let contents = try? FileManager.default.contentsOfDirectory(at: directory, includingPropertiesForKeys: nil)
        else { return [] }
        return contents.filter { bundle in
            guard bundle.pathExtension == "app" else { return false }
            let info = NSDictionary(contentsOf: bundle.appending(path: "Contents/Info.plist"))
            return info?[WebAppLink.appIDKey] as? String == id.uuidString
        }
    }

    private func writeBundle(at bundle: URL, manifest: WebAppBundleManifest, launcher: URL, icon: Data) throws {
        let contents = bundle.appending(path: "Contents")
        let executables = contents.appending(path: "MacOS")
        let resources = contents.appending(path: "Resources")
        for folder in [executables, resources] {
            try FileManager.default.createDirectory(at: folder, withIntermediateDirectories: true)
        }
        try FileManager.default.copyItem(at: launcher, to: executables.appending(path: WebAppBundleManifest.executableName))
        try icon.write(to: resources.appending(path: "\(WebAppBundleManifest.iconName).icns"))
        let plist = try PropertyListSerialization.data(fromPropertyList: manifest.infoPlist, format: .xml, options: 0)
        try plist.write(to: contents.appending(path: "Info.plist"))
    }
}
