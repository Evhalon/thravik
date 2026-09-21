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

    /// Once launched, links bypass SwiftUI, which answers every URL event that
    /// finds no window yet with a window of its own. The link that launches
    /// the app is left to SwiftUI — it builds the first window from it — and
    /// reaches a tab through that window's `onOpenURL`.
    @MainActor
    func applicationDidFinishLaunching(_ notification: Notification) {
        NSApp.setActivationPolicy(.regular)
        NSApp.activate()
        NSAppleEventManager.shared().setEventHandler(
            self,
            andSelector: #selector(handleGetURL(_:withReplyEvent:)),
            forEventClass: AEEventClass(kInternetEventClass),
            andEventID: AEEventID(kAEGetURL)
        )
    }

    func applicationShouldTerminateAfterLastWindowClosed(_ sender: NSApplication) -> Bool {
        true
    }

    @MainActor
    func applicationWillTerminate(_ notification: Notification) {
        container?.persist()
    }

    @MainActor @objc
    private func handleGetURL(_ event: NSAppleEventDescriptor, withReplyEvent reply: NSAppleEventDescriptor) {
        guard let text = event.paramDescriptor(forKeyword: keyDirectObject)?.stringValue,
              let url = URL(string: text)
        else { return }
        guard let container else {
            pendingLinks.append(url)
            return
        }
        container.openExternal([url])
        NSApp.activate()
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
