import AppKit
import Foundation
import RedentKit

/// Launch Services, behind the port.
///
/// Lives in the composition root because it is the only layer allowed to know
/// which concrete system service backs a port — and because handing web links
/// to an app is a decision macOS itself confirms with the user.
struct SystemDefaultBrowser: DefaultBrowserManaging {
    private static let probe = URL(string: "https://example.com")

    func isDefault() async -> Bool {
        guard let probe = Self.probe,
              let handler = NSWorkspace.shared.urlForApplication(toOpen: probe)
        else { return false }
        return handler.standardizedFileURL == Bundle.main.bundleURL.standardizedFileURL
    }

    /// macOS shows its own confirmation panel; a decline comes back as a
    /// thrown error, which is a "no", not a failure worth reporting.
    @discardableResult
    func makeDefault() async -> Bool {
        let bundle = Bundle.main.bundleURL
        for scheme in ["http", "https"] {
            do {
                try await NSWorkspace.shared.setDefaultApplication(
                    at: bundle, toOpenURLsWithScheme: scheme
                )
            } catch {
                return false
            }
        }
        return await isDefault()
    }
}
