import Foundation

/// The website-data boundary a Space browses in.
///
/// A Container is an identity and nothing more: its name is its Space's name
/// and its lifetime is its Space's lifetime, so there is no separate record to
/// keep in step. `SpaceIdentity.containerID(for:)` is how one is addressed.
public enum BrowserContainer {
    /// The store that predates Space isolation. The Work Space derives onto it,
    /// which is what keeps existing cookies and logins where the user left them.
    public static let defaultID = UUID(uuid: (0x45, 0x44, 0x43, 0x01, 0x00, 0x00, 0x00, 0x00,
                                               0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x01))
}
