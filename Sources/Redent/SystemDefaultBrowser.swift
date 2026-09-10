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

    /// macOS puts up its own confirmation panel, and a decline comes back as a
    /// thrown error — a "no", not a failure worth reporting.
    ///
    /// One call carries the whole switch: the browser is a single setting, and
    /// a second call naming the other scheme is refused outright. Reporting
    /// that refusal is what made a switch that *had* happened look like one
    /// that had not, so the outcome is read back from Launch Services instead
    /// of taken from the call.
    @discardableResult
    func makeDefault() async -> Bool {
        try? await NSWorkspace.shared.setDefaultApplication(
            at: Bundle.main.bundleURL, toOpenURLsWithScheme: "http"
        )
        return await settled()
    }

    /// Launch Services publishes the change after the panel closes, not during
    /// it: asking straight away answers with the old handler and would report a
    /// switch that did work as a failure.
    private func settled() async -> Bool {
        for _ in 0..<20 {
            if await isDefault() { return true }
            try? await Task.sleep(for: .milliseconds(100))
        }
        return false
    }
}
