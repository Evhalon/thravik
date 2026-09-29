import AppKit
import Foundation

/// Makes SwiftUI build its default window when AppKit never asked for one.
///
/// A launch caused by a link delivers `kAEGetURL` instead of the usual
/// open-application event, and SwiftUI only creates a `WindowGroup`'s first
/// window in response to the latter. The process then runs with a menu bar and
/// no window at all. SwiftUI has no API to open a window from outside a view,
/// but it answers a reopen event — the Dock-click path — exactly as needed:
/// a new window when none is visible, nothing otherwise.
enum SceneReopener {
    @MainActor
    static func requestWindow() {
        let reopen = NSAppleEventDescriptor(
            eventClass: AEEventClass(kCoreEventClass),
            eventID: AEEventID(kAEReopenApplication),
            targetDescriptor: NSAppleEventDescriptor(processIdentifier: ProcessInfo.processInfo.processIdentifier),
            returnID: AEReturnID(kAutoGenerateReturnID),
            transactionID: AETransactionID(kAnyTransactionID)
        )
        // Delivered through the event queue, so it lands after launch finishes
        // even when the link arrived first.
        _ = try? reopen.sendEvent(options: [.noReply], timeout: TimeInterval(kAEDefaultTimeout))
    }
}
