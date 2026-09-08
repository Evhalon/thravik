import Foundation
import RedentKit

/// Reads the newest published release of a public GitHub repository.
///
/// Unauthenticated, so it is subject to GitHub's per-IP rate limit. That is
/// fine for a check the user asks for; it is the reason there is no polling.
public struct GitHubReleaseFeed: UpdateChecking {
    private let repository: String
    private let session: URLSession

    public init(repository: String, session: URLSession = .shared) {
        self.repository = repository
        self.session = session
    }

    public func latestRelease() async throws -> AppRelease {
        guard let url = URL(string: "https://api.github.com/repos/\(repository)/releases/latest") else {
            throw UpdateError.malformedFeedURL
        }
        var request = URLRequest(url: url, timeoutInterval: 15)
        request.setValue("application/vnd.github+json", forHTTPHeaderField: "Accept")
        request.setValue("2022-11-28", forHTTPHeaderField: "X-GitHub-Api-Version")

        let (data, response) = try await fetch(request)
        guard let http = response as? HTTPURLResponse else { throw UpdateError.feedUnreachable }
        guard http.statusCode == 200 else { throw UpdateError.feedStatus(http.statusCode) }
        return try JSONDecoder().decode(ReleaseFeedPayload.self, from: data).release()
    }

    /// URLSession's own errors are transport noise to the user; they all mean
    /// the same thing here.
    private func fetch(_ request: URLRequest) async throws -> (Data, URLResponse) {
        do {
            return try await session.data(for: request)
        } catch {
            throw UpdateError.feedUnreachable
        }
    }
}
