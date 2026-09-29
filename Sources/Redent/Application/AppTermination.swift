import AppKit

/// Quits the app on the updater's behalf.
///
/// `NSApplication.terminate` is silently swallowed while a sheet is attached to
/// a window, and "Update and restart" is a button inside the Settings sheet —
/// so the app stayed open, the armed helper never saw the process exit, and the
/// swap only happened once the user force-quit. Ending the AppKit sheet is not
/// the cure either: SwiftUI owns that presentation and re-presents it from its
/// binding as fast as the sheet is ended, which is the flicker the user saw.
/// The binding is cleared first; termination then waits for AppKit to detach.
enum AppTermination {
    private static let pollDelay = Duration.milliseconds(50)
    private static let maximumWaitAttempts = 40

    @MainActor
    static func quit(
        dismissing dismissPresentations: @MainActor () -> Void,
        terminate: @escaping @MainActor () -> Void = { NSApp.terminate(nil) }
    ) {
        dismissPresentations()
        Task { @MainActor in
            await waitForSheetsToDetach()
            // Not from inside this task: `terminate` spins a nested event loop
            // until the delegate answers, and the delegate answers from main-actor
            // tasks that cannot start while this one still holds the actor.
            RunLoop.main.perform { MainActor.assumeIsolated(terminate) }
        }
    }

    /// SwiftUI tears a sheet down over an animation, so the wait is real — but
    /// bounded: a sheet nobody claimed must not keep the app alive forever.
    @MainActor
    private static func waitForSheetsToDetach() async {
        for _ in 0..<maximumWaitAttempts {
            guard hasAttachedSheet else { return }
            try? await Task.sleep(for: pollDelay)
        }
        endAttachedSheets()
    }

    @MainActor
    private static var hasAttachedSheet: Bool {
        NSApp.windows.contains { !$0.sheets.isEmpty }
    }

    /// Last resort, and only once no binding is left to re-present them.
    @MainActor
    private static func endAttachedSheets() {
        for window in NSApp.windows {
            for sheet in window.sheets { window.endSheet(sheet) }
        }
    }
}
