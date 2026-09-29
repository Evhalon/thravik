import UniformTypeIdentifiers
import WebKit

/// Serves the copy of Chrome's DevTools frontend bundled with the app at
/// `redent-devtools://frontend/…`, and nothing else: a path that climbs out
/// of that folder is refused.
@MainActor
final class DevToolsFrontendScheme: NSObject, WKURLSchemeHandler {
    static let scheme = "redent-devtools"
    /// `can_dock` is how Chrome tells its frontend it shares the tab with the
    /// page: it then draws the close button and its own resize handle.
    static let entry = URL(string: "\(scheme)://frontend/devtools_app.html?can_dock=true")

    private let root = EngineResources.bundle?.resourceURL?
        .appendingPathComponent("DevToolsFrontend", isDirectory: true).standardizedFileURL

    /// Whether this build carries the frontend at all.
    var isAvailable: Bool {
        root.map { FileManager.default.fileExists(atPath: $0.appendingPathComponent("devtools_app.html").path) } ?? false
    }

    func webView(_ webView: WKWebView, start task: any WKURLSchemeTask) {
        guard let url = task.request.url, let file = file(for: url), let data = try? Data(contentsOf: file) else {
            task.didFailWithError(URLError(.fileDoesNotExist))
            return
        }
        let response = HTTPURLResponse(url: url, statusCode: 200, httpVersion: "HTTP/1.1", headerFields: [
            "Content-Type": Self.mimeType(for: file),
            "Content-Length": String(data.count)
        ])
        guard let response else { return task.didFailWithError(URLError(.cannotParseResponse)) }
        task.didReceive(response)
        task.didReceive(data)
        task.didFinish()
    }

    func webView(_ webView: WKWebView, stop task: any WKURLSchemeTask) {}

    private func file(for url: URL) -> URL? {
        guard let root, url.host() == "frontend" else { return nil }
        let file = root.appendingPathComponent(url.path(percentEncoded: false)).standardizedFileURL
        guard file.path.hasPrefix(root.path + "/") else { return nil }
        return file
    }

    private static func mimeType(for file: URL) -> String {
        // ES modules are refused unless served as JavaScript.
        if file.pathExtension == "js" || file.pathExtension == "mjs" { return "text/javascript" }
        return UTType(filenameExtension: file.pathExtension)?.preferredMIMEType ?? "application/octet-stream"
    }
}
