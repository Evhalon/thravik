import Foundation

/// What the app is called on screen.
///
/// The codebase is named Redent and the app ships as Thravik, so the name in
/// user-facing copy is read from the bundle rather than written out — a
/// sentence that says "Redent" is showing the reader the wrong product.
enum AppIdentity {
    static let displayName: String = {
        let info = Bundle.main.infoDictionary
        let name = info?["CFBundleDisplayName"] as? String ?? info?["CFBundleName"] as? String
        // Absent under `swift run`, which has no Info.plist to read.
        guard let name, !name.isEmpty else { return fallback }
        return name
    }()

    private static let fallback = "Thravik"
}
