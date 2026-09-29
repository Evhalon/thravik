import Foundation

/// A Space owns its cookie jar, one to one.
///
/// The Container id is *derived* from the Space id rather than stored, so the
/// two can never drift apart, a crash before the first save cannot orphan a
/// profile on disk, and sessions written before Spaces were isolated need no
/// migration step: their Spaces simply resolve to their own Containers.
extension SpaceIdentity {
    public static func containerID(for spaceID: UUID) -> UUID {
        var bytes = spaceID.uuid
        // The same value in a different namespace: 'S'pace becomes 'C'ontainer.
        // By construction the starter Work Space lands on the Default Container,
        // which is what keeps existing cookies where the user left them.
        bytes.2 = 0x43
        return UUID(uuid: bytes)
    }
}
