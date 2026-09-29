import Foundation

/// Waits for macOS to publish a default-browser change.
///
/// The call that asks for the switch raises a system panel and comes back —
/// often reporting an error — before the person in front of it has answered,
/// so the answer has to be read back from Launch Services. Reading for the
/// length of a function call is what reported a switch the user *did* make as
/// a failure.
///
/// Pure, so the waiting rule is tested without Launch Services.
public enum DefaultBrowserSwitch {
    /// Long enough to read the system panel and answer it. Shorter windows
    /// close while the panel is still on screen and call the switch a failure.
    public static let interval = Duration.milliseconds(150)
    public static let attempts = 80
    /// Reads granted after the panel closes: Launch Services publishes the
    /// change a moment behind the click that made it. Roughly two seconds.
    public static let graceAttempts = 14

    /// The whole window a read-back is given: `attempts` × `interval`.
    public static var window: Duration { interval * attempts }

    /// What a read-back asks the system. Injected so the rule is tested
    /// without Launch Services and without a panel on screen.
    public struct Probes {
        /// Reads Launch Services.
        public var isDefault: () async -> Bool
        /// Whether the system's confirmation is still on screen.
        public var isPanelUp: () async -> Bool
        /// Pauses between reads.
        public var wait: () async -> Void

        public init(
            isDefault: @escaping () async -> Bool,
            isPanelUp: @escaping () async -> Bool,
            wait: @escaping () async -> Void
        ) {
            self.isDefault = isDefault
            self.isPanelUp = isPanelUp
            self.wait = wait
        }
    }

    /// Asks for the switch, then reads the answer back.
    ///
    /// A thrown request is not an answer: macOS reports an error the moment it
    /// raises its panel, before anyone has touched it. Taking that for a
    /// decline reports a switch the user goes on to make as one that failed.
    public static func apply(
        attempts: Int = DefaultBrowserSwitch.attempts,
        request: () async throws -> Void,
        probes: Probes
    ) async -> Bool {
        try? await request()
        return await confirm(attempts: attempts, probes: probes)
    }

    /// Reads until the system says yes, until the answered panel has had its
    /// grace, or until the window closes.
    ///
    /// A panel that closes with the old handler still in place is a decline,
    /// and waiting out the rest of the window only makes the person who
    /// declined watch a spinner for it.
    public static func confirm(
        attempts: Int = DefaultBrowserSwitch.attempts,
        probes: Probes
    ) async -> Bool {
        var sawPanel = false
        var readsSincePanel = 0
        for attempt in 0..<max(attempts, 1) {
            if await probes.isDefault() { return true }
            if await probes.isPanelUp() {
                sawPanel = true
                readsSincePanel = 0
            } else if sawPanel {
                readsSincePanel += 1
                if readsSincePanel >= graceAttempts { return false }
            }
            if attempt < attempts - 1 { await probes.wait() }
        }
        return false
    }
}
