import RedentKit
import WebKit

@MainActor
enum WebNativeFind {
    static func search(_ query: String, forward: Bool, in view: WKWebView) async -> FindMatches {
        guard !query.isEmpty else { return .empty }
        let configuration = WKFindConfiguration()
        configuration.backwards = !forward
        configuration.caseSensitive = false
        configuration.wraps = true
        let result = try? await view.find(query, configuration: configuration)
        return result?.matchFound == true ? .foundWithoutCount : .empty
    }
}
