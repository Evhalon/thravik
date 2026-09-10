import Foundation

/// Well-known icon URLs and a cheap sniff of whether bytes are an image.
///
/// Home tiles cannot run page JS, so they probe a short list on the site's
/// own origin. PNG first: many modern icons are PNG-in-ICO that look empty
/// as a 16px glyph, or HTML 200s pretending to be `.ico`.
enum SiteIconProbe {
    static func urls(for host: String) -> [URL] {
        let host = host.trimmingCharacters(in: .whitespacesAndNewlines).lowercased()
        guard !host.isEmpty, !host.contains("/"), !host.contains("://") else { return [] }
        var result: [URL] = []
        for path in ["/apple-touch-icon.png", "/favicon-192.png", "/favicon.png", "/favicon.ico"] {
            if let url = URL(string: "https://\(host)\(path)") { result.append(url) }
        }
        if !host.hasPrefix("www."), let url = URL(string: "https://www.\(host)/favicon.ico") {
            result.append(url)
        }
        return result
    }

    static func isImage(_ data: Data) -> Bool {
        guard data.count >= 4 else { return false }
        let head = [UInt8](data.prefix(16))
        if head.starts(with: [0x89, 0x50, 0x4E, 0x47]) { return true }
        if head.starts(with: [0xFF, 0xD8, 0xFF]) { return true }
        if head.starts(with: [0x47, 0x49, 0x46]) { return true }
        if head.starts(with: [0x00, 0x00, 0x01, 0x00]) { return true }
        if head.starts(with: [0x00, 0x00, 0x02, 0x00]) { return true }
        if head.starts(with: [0x42, 0x4D]) { return true }
        if data.count >= 12, head.starts(with: [0x52, 0x49, 0x46, 0x46]),
           Array(data[8..<12]) == Array("WEBP".utf8)
        { return true }
        return isSVG(data)
    }

    private static func isSVG(_ data: Data) -> Bool {
        guard let text = String(data: data.prefix(256), encoding: .utf8) else { return false }
        let trimmed = text.trimmingCharacters(in: .whitespacesAndNewlines).lowercased()
        return trimmed.contains("<svg") && !trimmed.contains("<html")
    }
}
