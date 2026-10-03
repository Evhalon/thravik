import Foundation
import RedentKit
import Testing

@Suite("Auto float video preference")
struct AutoFloatVideoSettingsTests {
    @Test("New settings leave auto-float off")
    func defaultsOff() {
        #expect(!BrowserSettings().floatsPlayingVideoOnTabSwitch)
    }

    @Test("Saved settings from before the preference stay off")
    func legacySettingsStayOff() throws {
        let encoded = try JSONEncoder().encode(BrowserSettings())
        var values = try #require(JSONSerialization.jsonObject(with: encoded) as? [String: Any])
        values.removeValue(forKey: "floatsPlayingVideoOnTabSwitch")
        let data = try JSONSerialization.data(withJSONObject: values)
        let decoded = try JSONDecoder().decode(BrowserSettings.self, from: data)
        #expect(!decoded.floatsPlayingVideoOnTabSwitch)
    }

    @Test("Turning auto-float on survives a save")
    func enabledChoiceIsKept() throws {
        var settings = BrowserSettings()
        settings.floatsPlayingVideoOnTabSwitch = true
        let restored = try JSONDecoder().decode(BrowserSettings.self, from: JSONEncoder().encode(settings))
        #expect(restored.floatsPlayingVideoOnTabSwitch)
        #expect(restored == settings)
    }
}
