import Foundation
import Testing
@testable import RedentKit

@Suite("Calendar settings")
struct CalendarSettingsTests {
    @Test("New settings leave meetings off")
    func defaultsOff() {
        #expect(!BrowserSettings().showsUpcomingMeetings)
    }

    @Test("Saved settings from before the preference stay off")
    func legacySettingsStayOff() throws {
        let encoded = try JSONEncoder().encode(BrowserSettings())
        var values = try #require(JSONSerialization.jsonObject(with: encoded) as? [String: Any])
        values.removeValue(forKey: "showsUpcomingMeetings")
        let data = try JSONSerialization.data(withJSONObject: values)
        let decoded = try JSONDecoder().decode(BrowserSettings.self, from: data)
        #expect(!decoded.showsUpcomingMeetings)
    }

    @Test("Turning meetings on survives a save")
    func enabledChoiceIsKept() throws {
        var settings = BrowserSettings()
        settings.showsUpcomingMeetings = true
        let restored = try JSONDecoder().decode(BrowserSettings.self, from: JSONEncoder().encode(settings))
        #expect(restored.showsUpcomingMeetings)
        #expect(restored == settings)
    }
}
