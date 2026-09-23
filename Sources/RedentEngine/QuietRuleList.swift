import Foundation

/// Quiet mode's network half: the push-notification services whose only job on
/// a page is the "Allow notifications?" pitch. With their script refused the
/// pitch never draws. Kept apart from the ad list so each has its own toggle.
enum QuietRuleList {
    static let identifier = "app.redent.browser.quiet.v1"

    static let pushPromptDomains = [
        "onesignal.com", "pushengage.com", "izooto.com", "webpushr.com", "pushcrew.com",
        "aimtell.com", "truepush.com", "pushalert.co", "subscribers.com", "gravitec.net",
        "pushwoosh.com", "pushnami.com", "wonderpush.com", "pushowl.com", "notix.co",
    ]

    static var encodedJSON: String? {
        let rules: [[String: Any]] = pushPromptDomains.map { domain in
            [
                "trigger": ["url-filter": MediaRuleExceptions.hostFilter(domain), "load-type": ["third-party"]],
                "action": ["type": "block"],
            ]
        }
        guard let data = try? JSONSerialization.data(withJSONObject: rules) else { return nil }
        return String(data: data, encoding: .utf8)
    }
}
