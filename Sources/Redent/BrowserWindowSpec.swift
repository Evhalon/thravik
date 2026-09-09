import Foundation

/// Which window a scene is showing.
///
/// Lives in the app target because a window is a composition concern: `RedentUI`
/// asks for "another window, private or not" through a closure and never learns
/// what one is.
struct BrowserWindowSpec: Hashable, Codable, Identifiable {
    let id: UUID
    let isPrivate: Bool
    /// What the window's first tab opens. Nil for a blank new-tab page.
    let startURL: URL?

    init(id: UUID = UUID(), isPrivate: Bool = false, startURL: URL? = nil) {
        self.id = id
        self.isPrivate = isPrivate
        self.startURL = startURL
    }

    /// The window that owns the saved workspace. Its identity is fixed so the
    /// restored session always lands in it and never in a window the user
    /// happened to open second.
    static let primary = BrowserWindowSpec(
        id: UUID(uuid: (0x52, 0x44, 0x4E, 0x54, 0x00, 0x00, 0x00, 0x00,
                        0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x01)),
        isPrivate: false
    )

    var isPrimary: Bool { id == Self.primary.id }
}
