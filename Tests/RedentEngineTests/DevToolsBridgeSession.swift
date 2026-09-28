import Foundation
import Testing
import WebKit
@testable import RedentEngine

/// Speaks Chrome's DevTools protocol to a real page through the bridge, the
/// way the docked frontend does, and keeps every reply and event it heard.
@MainActor
final class DevToolsBridgeSession {
    let tab: WebTab
    let page: WKWebView
    private let tap: WebInspectorTap
    private var received: [[String: Any]] = []
    private var nextID = 1

    /// A page whose script sits in a function, so WebKit keeps its source.
    static let script = """
    <script>
    function greet(name) {
      return "hi " + name;
    }
    function fail() { throw new RangeError("page error"); }
    let pageLexical = 5;
    //# sourceURL=app.js
    </script>
    """

    static func open(body: String = "") async throws -> DevToolsBridgeSession {
        let tab = try await FindTestPage.saying(body + script, head: "<style>h1.big { color: blue }</style>")
        let session = try DevToolsBridgeSession(tab: tab)
        try await session.tap.attach()
        return session
    }

    private init(tab: WebTab) throws {
        self.tab = tab
        self.page = try #require(tab.webView)
        self.tap = WebInspectorTap(webView: page)
        tap.onMessage = { [weak self] raw in
            guard let data = raw.data(using: .utf8),
                  let message = try? JSONSerialization.jsonObject(with: data) as? [String: Any] else { return }
            self?.received.append(message)
        }
    }

    /// The whole reply: `result`, or `error` when the bridge refused.
    @discardableResult
    func call(_ method: String, _ params: [String: Any] = [:]) async throws -> [String: Any] {
        let id = nextID
        nextID += 1
        let data = try JSONSerialization.data(withJSONObject: ["id": id, "method": method, "params": params])
        tap.send(String(decoding: data, as: UTF8.self))
        let reply = await first { ($0["id"] as? Int) == id }
        return try #require(reply, "no reply to \(method)")
    }

    @discardableResult
    func result(_ method: String, _ params: [String: Any] = [:]) async throws -> [String: Any] {
        let reply = try await call(method, params)
        #expect(reply["error"] == nil, "\(method) failed: \(String(describing: reply["error"]))")
        return reply["result"] as? [String: Any] ?? [:]
    }

    /// The first event named `method` whose params satisfy `matching`.
    func event(_ method: String, matching: @escaping ([String: Any]) -> Bool = { _ in true }) async -> [String: Any]? {
        await first { ($0["method"] as? String) == method && matching($0["params"] as? [String: Any] ?? [:]) }?["params"] as? [String: Any]
    }

    var isHiddenInspectorVisible: Bool {
        let inspector = page.value(forKey: "_inspector") as? NSObject
        return (inspector?.value(forKey: "isVisible") as? NSNumber)?.boolValue ?? false
    }

    func close() {
        tap.detach()
    }

    private func first(where test: ([String: Any]) -> Bool) async -> [String: Any]? {
        let deadline = ContinuousClock.now + .seconds(10)
        while ContinuousClock.now < deadline {
            if let hit = received.first(where: test) { return hit }
            try? await Task.sleep(for: .milliseconds(20))
        }
        return nil
    }
}
