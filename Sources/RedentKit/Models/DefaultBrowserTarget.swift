import Foundation

/// Identifies whether Launch Services routes web links to this exact app bundle.
public enum DefaultBrowserTarget {
    public static func matches(handlerURL: URL?, bundleURL: URL) -> Bool {
        guard let handlerURL else { return false }
        return handlerURL.standardizedFileURL == bundleURL.standardizedFileURL
    }
}
