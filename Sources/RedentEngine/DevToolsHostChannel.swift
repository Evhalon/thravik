import AppKit
import WebKit

/// What the DevTools frontend asks of its embedder: protocol messages for the
/// page, plus the few things only the browser can do — copy, open a link in
/// a tab, close the panel.
@MainActor
final class DevToolsHostChannel: NSObject, WKScriptMessageHandler {
    static let handlerName = "redentDevToolsHost"
    static let script = EngineResources.url(forResource: "redent-devtools-host", withExtension: "js")
        .flatMap { try? String(contentsOf: $0, encoding: .utf8) }

    var onProtocolMessage: ((String) -> Void)?
    var onClose: (() -> Void)?
    var onOpenURL: ((URL) -> Void)?
    /// Where DevTools left room for the page, in the frontend's own points.
    var onPageBounds: ((CGRect) -> Void)?
    /// How far device mode shrank the emulated screen; nil when it stops.
    var onDeviceScale: ((Double?) -> Void)?

    func userContentController(_ controller: WKUserContentController, didReceive message: WKScriptMessage) {
        guard let body = message.body as? [String: Any], let kind = body["kind"] as? String else { return }
        switch kind {
        case "protocol":
            if let text = body["message"] as? String { onProtocolMessage?(text) }
        case "copy":
            guard let text = body["text"] as? String else { return }
            NSPasteboard.general.clearContents()
            NSPasteboard.general.setString(text, forType: .string)
        case "open":
            // Only web pages: DevTools links never need another scheme, and a
            // `javascript:` or `file:` one must not get a tab.
            guard let url = (body["url"] as? String).flatMap(URL.init(string:)),
                  url.scheme == "https" || url.scheme == "http" else { return }
            onOpenURL?(url)
        case "close":
            onClose?()
        case "bounds":
            let value = { (key: String) in (body[key] as? NSNumber)?.doubleValue ?? 0 }
            onPageBounds?(CGRect(x: value("x"), y: value("y"), width: value("width"), height: value("height")))
        case "device":
            onDeviceScale?((body["scale"] as? NSNumber)?.doubleValue)
        default:
            break
        }
    }
}
