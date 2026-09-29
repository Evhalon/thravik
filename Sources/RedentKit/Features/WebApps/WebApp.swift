import Foundation

/// A site the user keeps as an app: it opens in a window of its own, in the
/// Space — and so the cookies and logins — it was saved from.
public struct WebApp: Identifiable, Codable, Sendable, Hashable {
    public let id: UUID
    public var name: String
    public var url: URL
    public var faviconData: Data?
    /// The Space the app browses in. Its Container is the app's session.
    public var spaceID: UUID?
    public var createdAt: Date

    public init(
        id: UUID = UUID(),
        name: String,
        url: URL,
        faviconData: Data? = nil,
        spaceID: UUID? = nil,
        createdAt: Date = Date()
    ) {
        self.id = id
        self.name = name
        self.url = url
        self.faviconData = faviconData
        self.spaceID = spaceID
        self.createdAt = createdAt
    }

    /// Builds an app from the page in front: the site's root, named after the
    /// brand the page title already carries when it has one.
    public init?(page url: URL, title: String, faviconData: Data?, spaceID: UUID?) {
        guard let origin = Origin(url: url),
              let root = URL(string: "\(origin.scheme)://\(origin.host)/") else { return nil }
        self.init(name: Self.name(fromTitle: title, origin: origin), url: root,
                  faviconData: faviconData, spaceID: spaceID)
    }

    /// Two apps for the same site would be one app listed twice.
    public func isSameSite(as other: URL) -> Bool {
        guard let mine = Origin(url: url), let theirs = Origin(url: other) else { return false }
        return mine.host == theirs.host
    }

    /// "Pull request #182 — OnePanel — GitHub" names itself: the title segment
    /// that spells the site is the brand. Otherwise the site's own label.
    static func name(fromTitle title: String, origin: Origin) -> String {
        let label = origin.registrableDomain.split(separator: ".").first.map(String.init) ?? origin.host
        let separators = CharacterSet(charactersIn: "—–-|·:")
        let segments = title.components(separatedBy: separators)
            .map { $0.trimmingCharacters(in: .whitespaces) }
            .filter { !$0.isEmpty }
        let brand = segments.last { segment in
            let letters = segment.lowercased().filter(\.isLetter)
            return !letters.isEmpty && (letters == label.lowercased() || origin.host.contains(letters))
        }
        return brand ?? label.prefix(1).uppercased() + label.dropFirst()
    }
}
