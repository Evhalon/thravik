import Foundation

public enum MeetingLinkExtractor: Sendable {
    public static func meetingURL(in sources: [String]) -> URL? {
        for source in sources {
            if let url = httpsURLs(in: source).first(where: isVideoMeeting) { return url }
        }
        return nil
    }

    public static func httpsURLs(in text: String) -> [URL] {
        var found: [URL] = []
        var seen = Set<String>()
        var index = text.startIndex
        while index < text.endIndex {
            guard let start = text[index...].range(of: "https://", options: .caseInsensitive) else { break }
            let rest = text[start.lowerBound...]
            let stop = rest.firstIndex(where: isURLTerminator) ?? rest.endIndex
            index = stop
            guard let url = acceptedHTTPS(sanitize(String(text[start.lowerBound..<stop]))),
                  seen.insert(url.absoluteString).inserted
            else { continue }
            found.append(url)
        }
        return found
    }

    public static func isVideoMeeting(_ url: URL) -> Bool {
        guard url.scheme?.lowercased() == "https", let host = url.host?.lowercased() else { return false }
        return meetingHosts.contains { host == $0 || host.hasSuffix(".\($0)") }
    }

    private static func acceptedHTTPS(_ raw: String) -> URL? {
        guard let url = URL(string: raw), url.scheme?.lowercased() == "https", url.host != nil else {
            return nil
        }
        return url
    }

    private static func sanitize(_ raw: String) -> String {
        var trimmed = raw
        while let last = trimmed.last, trailingPunctuation.contains(last) { trimmed.removeLast() }
        return trimmed
    }

    private static func isURLTerminator(_ character: Character) -> Bool {
        character.isWhitespace || character == "<" || character == ">" || character == "\""
    }

    private static let trailingPunctuation: Set<Character> = [
        ".", ",", ";", ":", "!", "?", ")", "]", "}", "'", "\"",
    ]

    private static let meetingHosts = [
        "meet.google.com",
        "zoom.us",
        "zoom.com",
        "teams.microsoft.com",
        "teams.live.com",
        "webex.com",
        "facetime.apple.com",
    ]
}
