import Foundation
import RedentKit

/// GitHub's `releases/latest` response, narrowed to the fields that decide
/// whether a release is one this app may install.
struct ReleaseFeedPayload: Decodable {
    let tagName: String
    let htmlURL: URL?
    let draft: Bool
    let prerelease: Bool
    let assets: [Asset]

    enum CodingKeys: String, CodingKey {
        case tagName = "tag_name"
        case htmlURL = "html_url"
        case draft, prerelease, assets
    }

    struct Asset: Decodable {
        let name: String
        let browserDownloadURL: URL

        enum CodingKeys: String, CodingKey {
            case name
            case browserDownloadURL = "browser_download_url"
        }
    }

    func release() throws -> AppRelease {
        guard !draft, !prerelease else { throw UpdateError.noPublishedRelease }
        guard let version = AppVersion(tagName) else {
            throw UpdateError.unreadableVersion(tagName)
        }
        guard let asset = assets.first(where: { $0.name.lowercased().hasSuffix(".dmg") }) else {
            throw UpdateError.noDiskImage
        }
        // The whole trust chain is this link being HTTPS to a host GitHub
        // controls; a plain-http asset would let anyone on the path ship code.
        guard asset.browserDownloadURL.scheme == "https" else {
            throw UpdateError.insecureDownload
        }
        return AppRelease(version: version, downloadURL: asset.browserDownloadURL, pageURL: htmlURL)
    }
}
