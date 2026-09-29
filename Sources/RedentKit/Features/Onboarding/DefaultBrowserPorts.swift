import Foundation

/// Reads and sets which app macOS opens web links with.
///
/// Implemented in the composition root, which is the only layer allowed to
/// know that Launch Services exists.
public protocol DefaultBrowserManaging: Sendable {
    func isDefault() async -> Bool
    /// Asks the system to hand `http` and `https` to this app.
    /// - Returns: whether the system agreed. The user can decline the prompt.
    @discardableResult
    func makeDefault() async -> Bool
}

/// Remembers which release already asked, so the offer arrives once per update
/// rather than on every launch.
public protocol DefaultBrowserPromptStoring: Sendable {
    var lastPromptedVersion: String? { get }
    func recordPrompt(for version: String?)
    /// The user said no and meant it. Nothing asks again.
    var isSilenced: Bool { get }
    func silence()
}
