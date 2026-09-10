import AppKit
import Foundation

/// Exists for the three things SwiftUI's `App` cannot express on macOS: making
/// a document-less browser behave like a normal app in the Dock, taking the
/// links other apps hand to the default browser, and flushing the session on
/// the way out.
final class AppDelegate: NSObject, NSApplicationDelegate {
    @MainActor var container: AppContainer? {
        didSet { flushPendingLinks() }
    }

    /// Links that arrived before the first window finished building — the
    /// common case when a click in Mail is what launched the app.
    @MainActor private var pendingLinks: [URL] = []

    func applicationDidFinishLaunching(_ notification: Notification) {
        NSApp.setActivationPolicy(.regular)
        NSApp.activate()
    }

    func applicationShouldTerminateAfterLastWindowClosed(_ sender: NSApplication) -> Bool {
        true
    }

    /// The container buffers for itself when it has no window yet, so this
    /// holds links only for the moment before the container exists at all.
    @MainActor
    func application(_ application: NSApplication, open urls: [URL]) {
        guard let container else {
            pendingLinks.append(contentsOf: urls)
            return
        }
        container.openExternal(urls)
        NSApp.activate()
    }

    @MainActor
    func applicationWillTerminate(_ notification: Notification) {
        container?.persist()
    }

    /// The container takes them from here: if it has no window yet either, it
    /// holds them itself until the first one appears.
    @MainActor
    private func flushPendingLinks() {
        guard !pendingLinks.isEmpty, let container else { return }
        let waiting = pendingLinks
        pendingLinks.removeAll()
        container.openExternal(waiting)
    }
}
