import Foundation
import RedentKit

/// A tab the address bar may offer to switch to rather than reopen.
public struct OpenTabCandidate: Hashable, Sendable {
    public let id: UUID
    public let title: String
    public let url: URL
    public let faviconData: Data?

    public init(id: UUID, title: String, url: URL, faviconData: Data? = nil) {
        self.id = id
        self.title = title
        self.url = url
        self.faviconData = faviconData
    }
}

/// Everything about the window a query is ranked against.
public struct SuggestionContext: Sendable {
    public var searchEngine: SearchEngine
    public var spaceID: UUID?
    public var openTabs: [OpenTabCandidate]

    public init(searchEngine: SearchEngine, spaceID: UUID? = nil, openTabs: [OpenTabCandidate] = []) {
        self.searchEngine = searchEngine
        self.spaceID = spaceID
        self.openTabs = openTabs
    }
}

/// What the user typed, completed in place: `git` + `hub.com`.
public struct InlineCompletion: Equatable, Sendable {
    public let typed: String
    public let suffix: String
    /// Where return goes while the completion stands — kept apart from the
    /// text so an `http://` site is not re-resolved to `https://`.
    public let url: URL

    public var text: String { typed + suffix }
}

/// The dropdown for one query: its rows, and the completion the field shows.
/// Row 0 is always what return does with the text in the field.
public struct SuggestionResult: Sendable {
    public var rows: [AddressSuggestion]
    public var completion: InlineCompletion?

    static let empty = SuggestionResult(rows: [], completion: nil)
}
