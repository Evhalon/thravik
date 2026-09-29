import AppKit
import SwiftUI

/// Quit, routed through the app's own termination path.
///
/// The standard item calls `NSApplication.terminate`, which AppKit swallows
/// while a sheet is attached — so ⌘Q did nothing at all with Settings, or the
/// first-launch default-browser offer, on screen. This one clears the
/// presentations first, and asks before abandoning a download in flight.
struct QuitCommand: Commands {
    let container: AppContainer?

    var body: some Commands {
        CommandGroup(replacing: .appTermination) {
            Button("Quit Thravik", action: quit)
                .keyboardShortcut("q")
        }
    }

    private func quit() {
        guard let container else { return NSApp.terminate(nil) }
        let active = container.downloads.activeItems.count
        guard active == 0 || confirmAbandoning(active) else { return }
        AppTermination.quit(dismissing: container.dismissAllPresentations)
    }

    /// A download the user is waiting on is worth one question. Anything else
    /// about quitting stays silent.
    private func confirmAbandoning(_ count: Int) -> Bool {
        let alert = NSAlert()
        alert.messageText = count == 1
            ? "A download is still in progress."
            : "\(count) downloads are still in progress."
        alert.informativeText = "Quitting now cancels it and leaves the file incomplete."
        alert.addButton(withTitle: "Cancel")
        alert.addButton(withTitle: count == 1 ? "Quit and Stop Download" : "Quit and Stop Downloads")
        return alert.runModal() == .alertSecondButtonReturn
    }
}
