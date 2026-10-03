import Foundation
import WebKit

@MainActor
final class FindFrameRegistry: NSObject, WKScriptMessageHandlerWithReply {
    static let handlerName = "redentFindFrames"
    private var frames: [String: WKFrameInfo] = [:]
    private weak var view: WKWebView?
    private var session: String?

    func begin(in view: WKWebView) -> String {
        frames.removeAll()
        self.view = view
        let session = UUID().uuidString
        self.session = session
        return session
    }

    func userContentController(
        _ controller: WKUserContentController, didReceive message: WKScriptMessage,
        replyHandler: @escaping @MainActor @Sendable (Any?, String?) -> Void
    ) {
        replyHandler(register(message), nil)
    }

    private func register(_ message: WKScriptMessage) -> Bool {
        guard let view, message.webView === view,
              let body = message.body as? [String: Any], body["type"] as? String == "findFrameReady",
              let candidate = body["session"] as? String, candidate == session else { return false }
        guard let path = body["path"] as? [Int], path.count <= 32,
              path.allSatisfy({ (0...10_000).contains($0) }),
              path.isEmpty == message.frameInfo.isMainFrame else { return false }
        frames[key(path)] = message.frameInfo
        return true
    }

    func frame(at path: [Int]) -> WKFrameInfo? { frames[key(path)] }

    func reset() {
        frames.removeAll()
        view = nil
        session = nil
    }

    var allFrames: [WKFrameInfo] { Array(frames.values) }

    private func key(_ path: [Int]) -> String { path.map(String.init).joined(separator: ".") }
}
