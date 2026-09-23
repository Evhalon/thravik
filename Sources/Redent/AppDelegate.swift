import AppKit
import Foundation

/// Exists for the three things SwiftUI's `App` cannot express on macOS: making
/// a document-less browser behave like a normal app in the Dock, taking the
/// links other apps hand to the default browser, and flushing the session on
/// the way out.
final class AppDelegate: NSObject, NSApplicationDelegate {
    @MainActor var presentApplication: () -> Void = {
        NSApp.unhide(nil)
        let window = NSApp.keyWindow ?? NSApp.mainWindow ?? NSApp.windows.first(where: \.canBecomeKey)
        window?.deminiaturize(nil)
        window?.makeKeyAndOrderFront(nil)
        NSApp.activate()
    }

    @MainActor var container: AppContainer? {
        didSet { flushPendingLinks() }
    }

    /// Links that arrived before the first window finished building — the
    /// common case when a click in Mail is what launched the app.
    @MainActor private var pendingLinks: [URL] = []

    /// Register before launch completes so the URL that starts Redent is not
    /// consumed by SwiftUI as a request for an empty window.
    @MainActor
    func applicationWillFinishLaunching(_ notification: Notification) {
        NSAppleEventManager.shared().setEventHandler(
            self,
            andSelector: #selector(handleGetURL(_:withReplyEvent:)),
            forEventClass: AEEventClass(kInternetEventClass),
            andEventID: AEEventID(kAEGetURL)
        )
    }

    @MainActor
    func applicationDidFinishLaunching(_ notification: Notification) {
        NSApp.setActivationPolicy(.regular)
        NSApp.activate()
    }

    @MainActor
    func application(_ application: NSApplication, open urls: [URL]) {
        receive(urls)
    }

    /// Cold-launch URL events arrive before SwiftUI has registered an
    /// `NSWindow`. Present again once that window exists.
    @MainActor
    func windowBecameReady(openedExternalLinks: Bool) async {
        guard openedExternalLinks else { return }
        await Task.yield()
        presentApplication()
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
        receive([url])
    }

    @MainActor
    private func receive(_ urls: [URL]) {
        guard let container else {
            pendingLinks.append(contentsOf: urls)
            presentApplication()
            return
        }
        container.openExternal(urls)
        // Teams can use either URL delivery path. Presentation belongs here or
        // its new tab can stay hidden behind the source app.
        presentApplication()
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
