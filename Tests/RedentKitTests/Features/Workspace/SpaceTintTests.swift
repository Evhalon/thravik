import Foundation
import Testing
@testable import RedentKit

@Suite("Space tint")
struct SpaceTintTests {
    @Test("A token from before tints existed reads as a neutral named swatch")
    func legacyToken() {
        let tint = SpaceTint(token: "rose")
        #expect(tint.base == .named("rose"))
        #expect(tint.vividness == SpaceTint.neutralVividness)
        #expect(tint.token == "rose")
    }

    @Test("Custom color and vividness round-trip through the stored token")
    func roundTrip() {
        let tint = SpaceTint(base: .custom(SpaceRGB(red: 0.2, green: 0.4, blue: 1)), vividness: 0.8)
        #expect(tint.token == "#3366FF~80")
        #expect(SpaceTint(token: tint.token) == tint)
        #expect(SpaceTint(token: "amber~5") == SpaceTint(base: .named("amber"), vividness: 0.05))
    }

    @Test("Malformed vividness falls back to neutral and out-of-range clamps")
    func malformedVividness() {
        #expect(SpaceTint(token: "teal~loud").vividness == SpaceTint.neutralVividness)
        #expect(SpaceTint(token: "teal~250").vividness == 1)
        #expect(SpaceTint(token: "teal~-4").vividness == 0)
    }

    @Test("Only a strict #RRGGBB reads as a custom color")
    func hexParsing() {
        #expect(SpaceRGB(hex: "#FF8000") == SpaceRGB(red: 1, green: 128.0 / 255, blue: 0))
        #expect(SpaceRGB(hex: "FF8000") == nil)
        #expect(SpaceRGB(hex: "#+F8000") == nil)
        #expect(SpaceRGB(hex: "#FF80") == nil)
        #expect(SpaceTint(token: "#nothex").base == .named("#nothex"))
    }

    @Test("HSB survives a round trip through RGB")
    func hsbRoundTrip() {
        let original = SpaceRGB(red: 0.9, green: 0.3, blue: 0.55)
        let rebuilt = SpaceRGB(hue: original.hue, saturation: original.saturation, brightness: original.brightness)
        #expect(abs(rebuilt.red - original.red) < 1e-9)
        #expect(abs(rebuilt.green - original.green) < 1e-9)
        #expect(abs(rebuilt.blue - original.blue) < 1e-9)
    }

    @Test("Vividness mutes below half, intensifies above, keeps the hue")
    func vividness() {
        let rose = SpaceRGB(red: 0.8, green: 0.3, blue: 0.45)
        let muted = rose.vivified(0)
        let vivid = rose.vivified(1)
        #expect(rose.vivified(SpaceTint.neutralVividness) == rose)
        #expect(muted.saturation < rose.saturation)
        #expect(vivid.saturation > rose.saturation)
        #expect(vivid.brightness > rose.brightness)
        #expect(abs(muted.hue - rose.hue) < 1e-9)
        #expect(abs(vivid.hue - rose.hue) < 1e-9)
    }

    @Test("A grey never gains a hue when turned up")
    func greyStaysGrey() {
        let grey = SpaceRGB(red: 0.5, green: 0.5, blue: 0.5).vivified(1)
        #expect(grey.saturation == 0)
    }

    @Test("Wash style rides on the token and defaults to glow")
    func washStyle() {
        #expect(SpaceTint(token: "rose").wash == .glow)
        #expect(SpaceTint(token: "rose~80/aurora") == SpaceTint(base: .named("rose"), vividness: 0.8, wash: .aurora))
        #expect(SpaceTint(base: .named("rose"), wash: .none).token == "rose/none")
        #expect(SpaceTint(token: "#3366FF/bogus").wash == .glow)
    }

    @Test("Grain rides last on the token, stays off by default, and clamps")
    func grain() {
        #expect(SpaceTint(token: "rose~80/aurora").grain == 0)
        let grained = SpaceTint(base: .named("rose"), vividness: 0.8, wash: .aurora, grain: 0.3)
        #expect(grained.token == "rose~80/aurora+30")
        #expect(SpaceTint(token: grained.token) == grained)
        #expect(SpaceTint(token: "#3366FF+45") == SpaceTint(base: .custom(SpaceRGB(red: 0.2, green: 0.4, blue: 1)), grain: 0.45))
        #expect(SpaceTint(token: "rose+loud").grain == 0)
        #expect(SpaceTint(token: "rose+400").grain == 1)
    }
}
