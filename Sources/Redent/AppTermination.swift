import AppKit

/// Quits the app on the updater's behalf.
///
/// `NSApplication.terminate` is silently swallowed while a sheet is attached to
/// a window, and "Update and restart" is a button inside the Settings sheet —
/// so the app stayed open, the armed helper never saw the process exit, and the
/// swap only happened once the user force-quit. Termination must wait until
/// AppKit has completed detaching every sheet.
enum AppTermination {
    private static let retryDelay = Duration.milliseconds(100)
    private static let maximumDismissAttempts = 30

    @MainActor
    static func quit() {
        Task { @MainActor in
            await dismissSheets()
            NSApp.terminate(nil)
        }
    }

    @MainActor
    private static func dismissSheets() async {
        for _ in 0..<maximumDismissAttempts {
            guard endAttachedSheets() else { return }
            try? await Task.sleep(for: retryDelay)
        }
    }

    @MainActor
    private static func endAttachedSheets() -> Bool {
        let windowsWithSheets = NSApp.windows.filter { !$0.sheets.isEmpty }
        for window in windowsWithSheets {
            for sheet in window.sheets {
                sheet.orderOut(nil)
                window.endSheet(sheet)
            }
        }
        return !windowsWithSheets.isEmpty
    }
}
