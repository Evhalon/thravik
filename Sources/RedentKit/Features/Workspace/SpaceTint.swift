import Foundation

/// What a Space's color token means: a named swatch or any picked color, and
/// how vivid to render it.
///
/// It round-trips through the same `colorToken` string Spaces already store —
/// `rose`, `#3A7BFF`, `rose~80`, `rose~80/aurora+30` — so saved sessions need no migration and a
/// token from before this existed still reads as itself.
public struct SpaceTint: Hashable, Sendable {
    public enum Base: Hashable, Sendable {
        case named(String)
        case custom(SpaceRGB)
    }

    /// How the Space color pools across the top of the window.
    public enum Wash: String, CaseIterable, Sendable {
        case glow
        case aurora
        case none
    }

    public static let neutralVividness = 0.5
    private static let separator: Character = "~"
    private static let washSeparator: Character = "/"
    private static let grainSeparator: Character = "+"

    public var base: Base
    public var vividness: Double
    public var wash: Wash
    /// How much film grain rides on the color, 0 for perfectly smooth.
    public var grain: Double

    public init(base: Base, vividness: Double = SpaceTint.neutralVividness, wash: Wash = .glow, grain: Double = 0) {
        self.base = base
        self.vividness = vividness
        self.wash = wash
        self.grain = grain
    }

    public init(token full: String) {
        let grained = full.split(separator: Self.grainSeparator, maxSplits: 1, omittingEmptySubsequences: false)
        let token = grained.first.map(String.init) ?? full
        grain = grained.count == 2 ? Self.unit(percent: grained[1], fallback: 0) : 0
        let styled = token.split(separator: Self.washSeparator, maxSplits: 1, omittingEmptySubsequences: false)
        let color = styled.first.map(String.init) ?? token
        let parts = color.split(separator: Self.separator, maxSplits: 1, omittingEmptySubsequences: false)
        let head = parts.first.map(String.init) ?? color
        base = SpaceRGB(hex: head).map(Base.custom) ?? .named(head)
        vividness = parts.count == 2 ? Self.unit(percent: parts[1], fallback: Self.neutralVividness) : Self.neutralVividness
        wash = styled.count == 2 ? Wash(rawValue: String(styled[1])) ?? .glow : .glow
    }

    public var token: String {
        let head = switch base {
        case .named(let name): name
        case .custom(let rgb): rgb.hex
        }
        let percent = Self.percent(vividness)
        let color = percent == Self.percent(Self.neutralVividness) ? head : "\(head)\(Self.separator)\(percent)"
        let styled = wash == .glow ? color : "\(color)\(Self.washSeparator)\(wash.rawValue)"
        let grainPercent = Self.percent(grain)
        return grainPercent == 0 ? styled : "\(styled)\(Self.grainSeparator)\(grainPercent)"
    }

    private static func unit(percent: Substring, fallback: Double) -> Double {
        guard let value = Double(percent), value.isFinite else { return fallback }
        return min(max(value / 100, 0), 1)
    }

    private static func percent(_ unit: Double) -> Int {
        Int((min(max(unit, 0), 1) * 100).rounded())
    }
}
