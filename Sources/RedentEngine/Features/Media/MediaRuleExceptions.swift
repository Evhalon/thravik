import Foundation

/// Rules appended to the end of every content-blocking list so no filter can
/// stop a video from starting.
///
/// Each compiled list is evaluated on its own: an `ignore-previous-rules` in
/// the bundled list does nothing for a rule in the EasyList one. Every list
/// therefore carries the same tail.
enum MediaRuleExceptions {

    /// Pages whose player takes itself down when its own scripts are filtered.
    static let mediaDomains: Set<String> = [
        "youtube.com", "youtu.be", "youtube-nocookie.com", "youtubekids.com",
        "netflix.com", "disneyplus.com", "hulu.com", "max.com", "hbomax.com",
        "primevideo.com", "twitch.tv", "vimeo.com", "dailymotion.com",
        "crunchyroll.com", "paramountplus.com", "peacocktv.com", "dazn.com",
        "tiktok.com", "plex.tv", "raiplay.it", "mediaset.it", "mediasetinfinity.it",
        "spotify.com", "soundcloud.com", "vk.com", "bilibili.com", "kick.com",
    ]

    /// Player infrastructure the lists name as ads. uBlock swaps these for a
    /// no-op stub; a content blocker can only refuse them, and a refused IMA
    /// SDK or ad-inserted stream leaves the player waiting forever instead of
    /// skipping to the content.
    static let playerHosts: [String] = [
        "imasdk.googleapis.com", "dai.google.com", "players.brightcove.net",
        "jwpcdn.com", "cdn.jwplayer.com", "vjs.zencdn.net", "player.vimeo.com",
    ]

    /// Content-blocker `if-top-url` filters matching the media properties.
    static var mediaTopURLFilters: [String] {
        mediaDomains.sorted().map { domain in
            "^https://([^/]*\\.)?\(NSRegularExpression.escapedPattern(for: domain))/"
        }
    }

    static func hostFilter(_ host: String) -> String {
        "^https?://([^/]*\\.)?\(NSRegularExpression.escapedPattern(for: host))[:/]"
    }

    /// The media-site exception stays last: tests and readers look for it there.
    static var rules: [[String: Any]] {
        playerHosts.map { exception(["url-filter": hostFilter($0)]) }
            + [
                // The bytes of a `<video>` or `<audio>` element are never an ad
                // on their own; the ad is the script that picked them.
                exception(["url-filter": ".*", "resource-type": ["media"]]),
                exception(["url-filter": ".*", "if-top-url": mediaTopURLFilters]),
            ]
    }

    private static func exception(_ trigger: [String: Any]) -> [String: Any] {
        ["trigger": trigger, "action": ["type": "ignore-previous-rules"]]
    }
}
