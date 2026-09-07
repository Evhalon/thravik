import Foundation

/// Visual identity for a Space: an SF Symbol name and a color token.
///
/// Tokens are strings so RedentKit stays UI-free. `square`/`blue` is the
/// historical default written into early sessions; treat it as unset.
public enum SpaceIdentity: Sendable {
    public struct Look: Equatable, Sendable {
        public let icon: String
        public let colorToken: String
        public init(icon: String, colorToken: String) {
            self.icon = icon
            self.colorToken = colorToken
        }
    }

    public static let unsetIcon = "square"
    public static let unsetToken = "blue"

    public static let work = Look(icon: "briefcase.fill", colorToken: "amber")
    public static let personal = Look(icon: "heart.fill", colorToken: "rose")
    public static let research = Look(icon: "book.fill", colorToken: "indigo")
    public static let travel = Look(icon: "airplane", colorToken: "teal")

    public static let tokens = ["amber", "rose", "indigo", "teal", "violet", "lime", "coral", "sky"]
    public static let icons = [
        "square.stack.3d.up.fill", "sparkles", "leaf.fill", "moon.fill",
        "flame.fill", "drop.fill", "star.fill", "bolt.fill"
    ]

    public static func look(id: UUID, icon: String, colorToken: String) -> Look {
        if let preset = preset(for: id) { return preset }
        if icon == unsetIcon, colorToken == unsetToken { return derived(from: id) }
        return Look(icon: icon, colorToken: colorToken)
    }

    public static func preset(for id: UUID) -> Look? {
        switch id {
        case BrowserSpace.workID: work
        case BrowserSpace.personalID: personal
        case BrowserSpace.researchID: research
        case BrowserSpace.travelID: travel
        default: nil
        }
    }

    /// UUID bytes, not `Hasher` — Hasher is not stable across launches.
    public static func derived(from id: UUID) -> Look {
        let bytes = id.uuid
        return Look(
            icon: icons[Int(bytes.14) % icons.count],
            colorToken: tokens[Int(bytes.15) % tokens.count]
        )
    }
}
