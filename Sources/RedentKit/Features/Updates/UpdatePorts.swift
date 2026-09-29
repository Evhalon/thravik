import Foundation

/// Reads the newest published build from wherever releases live.
public protocol UpdateChecking: Sendable {
    func latestRelease() async throws -> AppRelease
}

/// Puts a release in place. Split from the check because installing an update
/// is never something the app should decide on its own.
public protocol UpdateInstalling: Sendable {
    /// Downloads `release`, verifies it, and arms a helper that swaps it in and
    /// reopens the app **once this process exits**. Nothing is replaced until
    /// the caller quits, so a failure here always leaves the running app intact.
    func stage(_ release: AppRelease) async throws
}
