import Foundation

/// Visual identity for a Space: an SF Symbol name and a color token.
///
/// Tokens are strings so RedentKit stays UI-free. `square`/`blue` is the
/// historical default written into early sessions; treat it as unset.
public enum SpaceIdentity: Sendable {
    public struct Look: Hashable, Codable, Sendable {
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

    /// The swatches the Space composer offers. A superset of `tokens`, which
    /// stays fixed because derived looks index into it.
    public static let pickerTokens = tokens + [
        "blue", "red", "orange", "yellow", "green", "mint", "cyan",
        "purple", "pink", "magenta", "brown", "slate"
    ]
    public static let icons = [
        "square.stack.3d.up.fill", "sparkles", "leaf.fill", "moon.fill",
        "flame.fill", "drop.fill", "star.fill", "bolt.fill"
    ]

    /// The palette the Space composer offers. A superset of `icons`, which
    /// stays fixed because derived looks index into it.
    public static let pickerIcons = icons + [
        "briefcase.fill", "heart.fill", "book.fill", "airplane",
        "house.fill", "graduationcap.fill", "cart.fill", "gamecontroller.fill",
        "music.note", "paintbrush.fill", "hammer.fill", "chevron.left.forwardslash.chevron.right",
        "camera.fill", "globe", "dollarsign.circle.fill", "figure.run"
    ]

    /// A starter Space only wears its preset until the user picks a look.
    public static func look(id: UUID, icon: String, colorToken: String) -> Look {
        guard icon == unsetIcon, colorToken == unsetToken else {
            return Look(icon: icon, colorToken: colorToken)
        }
        return preset(for: id) ?? derived(from: id)
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
