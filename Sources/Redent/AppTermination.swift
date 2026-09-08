import AppKit

/// Quits the app on the updater's behalf.
///
/// `NSApplication.terminate` is silently swallowed while a sheet is attached to
/// a window, and "Update and restart" is a button inside the Settings sheet —
/// so the app stayed open, the armed helper never saw the process exit, and the
/// swap only happened once the user force-quit. Ending the attached sheets in
/// the same turn puts AppKit back on its normal termination path.
enum AppTermination {
    @MainActor
    static func quit() {
        for window in NSApp.windows {
            for sheet in window.sheets { window.endSheet(sheet) }
        }
        NSApp.terminate(nil)
    }
}
