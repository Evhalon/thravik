import Foundation
import RedentKit

struct SystemAccountCallback {
    private let expected: URL
    private let state: String

    init(authorizationURL: URL) throws {
        let query = URLComponents(url: authorizationURL, resolvingAgainstBaseURL: false)?.queryItems ?? []
        let redirects = query.filter { $0.name == "redirect_to" }
        guard redirects.count == 1, let value = redirects.first?.value, let expected = URL(string: value),
              expected.scheme == "redent", expected.host == "account", expected.path == "/callback",
              expected.user == nil, expected.password == nil, expected.port == nil,
              let items = URLComponents(url: expected, resolvingAgainstBaseURL: false)?.queryItems else {
            throw AccountError.invalidConfiguration
        }
        let states = items.filter { $0.name == "state" }
        guard states.count == 1, let state = states.first?.value, !state.isEmpty else {
            throw AccountError.invalidConfiguration
        }
        self.expected = expected
        self.state = state
    }

    func matches(_ url: URL) -> Bool {
        guard url.scheme == expected.scheme, url.host == expected.host, url.path == expected.path,
              url.port == expected.port, url.user == nil, url.password == nil, url.fragment == nil else { return false }
        let states = URLComponents(url: url, resolvingAgainstBaseURL: false)?.queryItems?.filter { $0.name == "state" }
        return states?.count == 1 && states?.first?.value == state
    }
}
