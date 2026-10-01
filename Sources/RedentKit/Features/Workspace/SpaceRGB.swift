import Foundation

/// A Space hue as plain sRGB components, so the domain can store and reshape
/// any color the user picks without knowing about a UI framework.
public struct SpaceRGB: Hashable, Sendable {
    public let red: Double
    public let green: Double
    public let blue: Double

    public init(red: Double, green: Double, blue: Double) {
        self.red = Self.unit(red)
        self.green = Self.unit(green)
        self.blue = Self.unit(blue)
    }

    public init?(hex: String) {
        guard hex.hasPrefix("#") else { return nil }
        let digits = hex.dropFirst()
        guard digits.count == 6, digits.allSatisfy(\.isHexDigit), let value = UInt32(digits, radix: 16) else {
            return nil
        }
        self.init(
            red: Double((value >> 16) & 0xFF) / 255,
            green: Double((value >> 8) & 0xFF) / 255,
            blue: Double(value & 0xFF) / 255
        )
    }

    public init(hue: Double, saturation: Double, brightness: Double) {
        let sextant = (hue - hue.rounded(.down)) * 6
        let fraction = sextant - sextant.rounded(.down)
        let value = Self.unit(brightness)
        let chroma = Self.unit(saturation)
        let low = value * (1 - chroma)
        let falling = value * (1 - chroma * fraction)
        let rising = value * (1 - chroma * (1 - fraction))
        switch Int(sextant) % 6 {
        case 0: self.init(red: value, green: rising, blue: low)
        case 1: self.init(red: falling, green: value, blue: low)
        case 2: self.init(red: low, green: value, blue: rising)
        case 3: self.init(red: low, green: falling, blue: value)
        case 4: self.init(red: rising, green: low, blue: value)
        default: self.init(red: value, green: low, blue: falling)
        }
    }

    public var hex: String {
        String(format: "#%02X%02X%02X", Self.byte(red), Self.byte(green), Self.byte(blue))
    }

    public var hue: Double {
        let delta = brightness - min(red, green, blue)
        guard delta > 0 else { return 0 }
        let sextant = switch brightness {
        case red: (green - blue) / delta
        case green: (blue - red) / delta + 2
        default: (red - green) / delta + 4
        }
        let turn = sextant / 6
        return turn < 0 ? turn + 1 : turn
    }

    public var saturation: Double {
        brightness > 0 ? (brightness - min(red, green, blue)) / brightness : 0
    }

    public var brightness: Double { max(red, green, blue) }

    /// Half leaves the hue as picked. Below dusts it toward a muted pastel;
    /// above pushes it toward neon. Greys stay grey: a hue they never had
    /// must not appear out of nowhere.
    public func vivified(_ vividness: Double) -> SpaceRGB {
        let amount = Self.unit(vividness)
        guard amount != SpaceTint.neutralVividness else { return self }
        if amount < SpaceTint.neutralVividness {
            let calm = amount / SpaceTint.neutralVividness
            return SpaceRGB(hue: hue, saturation: saturation * (0.15 + 0.85 * calm), brightness: brightness * (0.8 + 0.2 * calm))
        }
        let boost = (amount - SpaceTint.neutralVividness) / (1 - SpaceTint.neutralVividness)
        let saturationBoost = boost * min(1, saturation * 3)
        return SpaceRGB(
            hue: hue,
            saturation: saturation + (1 - saturation) * saturationBoost,
            brightness: brightness + (1 - brightness) * boost
        )
    }

    private static func unit(_ value: Double) -> Double {
        value.isFinite ? min(max(value, 0), 1) : 0
    }

    private static func byte(_ value: Double) -> Int {
        Int((value * 255).rounded())
    }
}
