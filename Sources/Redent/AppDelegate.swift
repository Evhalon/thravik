import AppKit

/// Exists for the two things SwiftUI's `App` cannot express on macOS: making a
/// document-less browser behave like a normal app in the Dock, and flushing the
/// session on the way out.
final class AppDelegate: NSObject, NSApplicationDelegate {
    @MainActor var container: AppContainer?

    func applicationDidFinishLaunching(_ notification: Notification) {
        NSApp.setActivationPolicy(.regular)
        NSApp.activate()
    }

    func applicationShouldTerminateAfterLastWindowClosed(_ sender: NSApplication) -> Bool {
        true
    }

    @MainActor
    func applicationWillTerminate(_ notification: Notification) {
        container?.persist()
    }
}
