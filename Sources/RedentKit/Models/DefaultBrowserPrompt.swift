import Foundation

/// Decides whether this launch should offer to make Redent the default browser.
///
/// Pure, so the rule can be tested without Launch Services: the offer belongs
/// to the *first launch of a release*, never to every launch, and never once
/// the user has said no.
public enum DefaultBrowserPrompt {
    public struct Input: Sendable, Equatable {
        /// The running build, or `nil` for a development build with no
        /// version to remember.
        public var installedVersion: String?
        public var lastPromptedVersion: String?
        public var isSilenced: Bool
        public var isAlreadyDefault: Bool

        public init(
            installedVersion: String?,
            lastPromptedVersion: String?,
            isSilenced: Bool,
            isAlreadyDefault: Bool
        ) {
            self.installedVersion = installedVersion
            self.lastPromptedVersion = lastPromptedVersion
            self.isSilenced = isSilenced
            self.isAlreadyDefault = isAlreadyDefault
        }
    }

    /// A build with no version can only ever ask once: with nothing to compare,
    /// "the release changed" is a question it cannot answer.
    public static func shouldOffer(_ input: Input) -> Bool {
        guard !input.isSilenced, !input.isAlreadyDefault else { return false }
        guard let installed = input.installedVersion else {
            return input.lastPromptedVersion == nil
        }
        return input.lastPromptedVersion != installed
    }
}
