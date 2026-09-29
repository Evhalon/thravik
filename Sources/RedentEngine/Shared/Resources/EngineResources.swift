import Foundation

/// Finds RedentEngine's SwiftPM resource bundle without trapping.
///
/// `Bundle.module` is a `fatalError` when the bundle is absent, and it fires
/// inside a `dispatch_once` on first touch. A shipped build died that way in
/// `AppContainer.init` on a Mac whose copy of the app had no
/// `Redent_RedentEngine.bundle` in `Contents/Resources`. Resources here are
/// optional by design — every caller already handles `nil` — so the lookup
/// must report absence, not abort the process.
enum EngineResources {
    /// `nil` when the app was assembled without its resource bundle.
    static let bundle: Bundle? = locate()

    static func url(forResource name: String, withExtension ext: String) -> URL? {
        bundle?.url(forResource: name, withExtension: ext)
    }

    /// SwiftPM's own search order for `Bundle.module`, minus the trap: the
    /// host app's `Contents/Resources`, then the loading binary's, then the
    /// directories those bundles sit in, which is where `swift test` and
    /// `swift run` leave it.
    private static func locate() -> Bundle? {
        let anchor = Bundle(for: BundleAnchor.self)
        let roots = [
            Bundle.main.resourceURL,
            anchor.resourceURL,
            Bundle.main.bundleURL,
            anchor.bundleURL.deletingLastPathComponent()
        ]
        for root in roots.compactMap({ $0 }) {
            let candidate = root.appendingPathComponent(bundleName)
            if let bundle = Bundle(url: candidate) { return bundle }
        }
        return nil
    }

    /// SwiftPM names resource bundles `<package>_<target>.bundle`.
    private static let bundleName = "Redent_RedentEngine.bundle"
}

/// A handle for `Bundle(for:)` — the class that locates the binary
/// RedentEngine was linked into. Never instantiated.
private final class BundleAnchor {}
