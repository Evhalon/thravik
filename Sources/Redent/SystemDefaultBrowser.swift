import AppKit
import Foundation
import RedentKit

/// Launch Services, behind the port.
///
/// Lives in the composition root because it is the only layer allowed to know
/// which concrete system service backs a port — and because handing web links
/// to an app is a decision macOS itself confirms with the user.
struct SystemDefaultBrowser: DefaultBrowserManaging {
    /// An https address, so the check answers the question that matters: not
    /// "did the call succeed" but "does a web link arrive here".
    private static let probe = URL(string: "https://example.com")

    /// Compared by bundle identifier rather than by path, because that is what
    /// Launch Services itself keys on: with a copy installed in Applications
    /// and another running from a build directory, macOS hands links to the
    /// one it prefers, and a path comparison then reports a switch that did
    /// work as one that did not. An update swaps the bundle in place for the
    /// same reason — the identifier is the stable half.
    func isDefault() async -> Bool {
        guard let probe = Self.probe,
              let handler = NSWorkspace.shared.urlForApplication(toOpen: probe),
              let handlerID = Bundle(url: handler)?.bundleIdentifier
        else { return false }
        return handlerID == Bundle.main.bundleIdentifier
    }

    /// One call carries the whole switch: the browser is a single setting, and
    /// a second call naming the other scheme is refused outright.
    ///
    /// The call comes back as soon as macOS has *raised* its confirmation
    /// panel — often reporting an error — not once the panel has been
    /// answered. So neither its return nor its error decides anything: the
    /// outcome is read back from Launch Services for as long as answering a
    /// panel takes.
    @discardableResult
    func makeDefault() async -> Bool {
        await DefaultBrowserSwitch.apply(
            request: {
                try await NSWorkspace.shared.setDefaultApplication(
                    at: Bundle.main.bundleURL, toOpenURLsWithScheme: "http"
                )
            },
            probes: .init(isDefault: isDefault, isPanelUp: Self.isPanelUp, wait: Self.pause)
        )
    }

    /// The confirmation belongs to another process, so raising it takes key
    /// away from this app and answering it hands key back. That hand-back is
    /// the earliest honest sign that a decline was a decline — without it, a
    /// no costs the person who said it the whole read-back window.
    private static func isPanelUp() async -> Bool {
        await MainActor.run { !NSApplication.shared.isActive }
    }

    private static func pause() async {
        try? await Task.sleep(for: DefaultBrowserSwitch.interval)
    }
}
