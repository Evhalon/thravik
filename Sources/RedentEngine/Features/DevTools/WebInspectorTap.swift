import WebKit

/// Taps the protocol connection of a tab's own Web Inspector so a Chrome
/// DevTools session can share it.
///
/// WebKit offers no public way to speak its inspector protocol to a web view
/// in this process. Its Web Inspector frontend holds that connection, and it
/// can be opened without being shown; `redent-devtools-bridge.js` runs inside
/// that frontend page — never in a website — and relays the session. Every
/// private selector is checked before use, so a WebKit that drops one makes
/// the tap unavailable instead of crashing the browser.
@MainActor
final class WebInspectorTap {
    var onMessage: ((String) -> Void)?

    private weak var webView: WKWebView?
    private var inspector: NSObject?
    private var frontend: WKWebView?
    private var relay: ScriptMessageRelay?
    private var keepAwake: Task<Void, Never>?

    private static let handlerName = "redentDevTools"
    private static let bridgeSource = EngineResources.url(forResource: "redent-devtools-bridge", withExtension: "js")
        .flatMap { try? String(contentsOf: $0, encoding: .utf8) }

    init(webView: WKWebView) {
        self.webView = webView
    }

    func attach() async throws(WebInspectorTapError) {
        guard let source = Self.bridgeSource else { throw .bridgeMissing }
        guard let webView, let inspector = Self.object(webView, "_inspector") else { throw .unavailable }
        self.inspector = inspector
        // WebKit reuses the frontend's web view across connections, and loads
        // a fresh document into it after `connect` returns: only a document
        // that began after this point belongs to the new connection.
        var connectedAt = 0.0
        if Self.flag(inspector, "isConnected") == false {
            connectedAt = Date().timeIntervalSince1970 * 1000
            guard Self.call(inspector, "connect") else { throw .unavailable }
        }
        let frontend = try await readyFrontend(inspector, loadedAfter: connectedAt)
        let relay = ScriptMessageRelay { [weak self] in self?.onMessage?($0) }
        frontend.configuration.userContentController.add(relay, name: Self.handlerName)
        self.frontend = frontend
        self.relay = relay
        guard await run(source + "\n;window.__redentDevTools.attach(); true", in: frontend) else { throw .unavailable }
        keepFrontendAwake()
    }

    func send(_ message: String) {
        frontend?.callAsyncJavaScript(
            "window.__redentDevTools.fromTools(message)", arguments: ["message": message], in: nil, in: .page
        )
    }

    func inspect(path: [Int]) {
        frontend?.callAsyncJavaScript(
            "window.__redentDevTools.inspectPath(path)", arguments: ["path": path], in: nil, in: .page
        )
    }

    func detach() {
        keepAwake?.cancel()
        keepAwake = nil
        frontend?.evaluateJavaScript("window.__redentDevTools && window.__redentDevTools.detach()")
        if relay != nil {
            frontend?.configuration.userContentController.removeScriptMessageHandler(forName: Self.handlerName)
        }
        // Closed even when WebKit opened it: `WebViewHost` hides every one
        // WebKit docks, and a hidden inspector would outlive the panel.
        if let inspector, Self.flag(inspector, "isVisible") == false {
            _ = Self.call(inspector, "close")
        }
        relay = nil
        frontend = nil
        inspector = nil
    }

    /// WebKit suspends a web view's process within seconds of it being off
    /// screen, and this Web Inspector never is on screen: the page's console
    /// messages and requests then wait in its queue until something else wakes
    /// it, and DevTools looks frozen. Nothing WebKit publishes can stand in for
    /// this wake-up, and the suspension policy cannot change after creation.
    private func keepFrontendAwake() {
        keepAwake = Task { [weak self] in
            while !Task.isCancelled {
                try? await Task.sleep(for: .seconds(1))
                guard let frontend = self?.frontend else { return }
                _ = await self?.run("0", in: frontend)
            }
        }
    }

    /// The frontend page, once its protocol connection knows the page target.
    /// WebKit announces neither moment, so readiness is checked for a
    /// bounded few seconds and then given up on.
    private func readyFrontend(_ inspector: NSObject, loadedAfter start: Double) async throws(WebInspectorTapError) -> WKWebView {
        let probe = "performance.timeOrigin > \(start) && typeof WI === 'object' && !!WI.pageTarget"
            + " && typeof InspectorFrontendAPI === 'object'"
        for _ in 0..<50 {
            if let view = Self.object(inspector, "inspectorWebView") as? WKWebView, await run(probe, in: view) {
                return view
            }
            try? await Task.sleep(for: .milliseconds(100))
        }
        throw .timedOut
    }

    private func run(_ script: String, in view: WKWebView) async -> Bool {
        await withCheckedContinuation { continuation in
            view.evaluateJavaScript(script) { result, _ in
                continuation.resume(returning: (result as? Bool) == true)
            }
        }
    }

    private static func object(_ target: NSObject, _ name: String) -> NSObject? {
        guard target.responds(to: NSSelectorFromString(name)) else { return nil }
        return target.value(forKey: name) as? NSObject
    }

    private static func flag(_ target: NSObject, _ name: String) -> Bool? {
        guard target.responds(to: NSSelectorFromString(name)) else { return nil }
        return (target.value(forKey: name) as? NSNumber)?.boolValue
    }

    private static func call(_ target: NSObject, _ name: String) -> Bool {
        let selector = NSSelectorFromString(name)
        guard target.responds(to: selector) else { return false }
        target.perform(selector)
        return true
    }
}

/// Why a tab's Web Inspector could not be shared.
enum WebInspectorTapError: Error, Equatable {
    /// This WebKit no longer offers what the tap relies on.
    case unavailable
    /// The app was built without its bridge script.
    case bridgeMissing
    /// The Web Inspector never finished connecting to the page.
    case timedOut
}
