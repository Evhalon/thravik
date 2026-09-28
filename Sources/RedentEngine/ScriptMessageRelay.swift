import WebKit

/// Hands a page's string messages to a closure.
///
/// The content controller keeps its handlers strongly; the closure is where
/// the owner breaks that cycle, by capturing itself weakly.
@MainActor
final class ScriptMessageRelay: NSObject, WKScriptMessageHandler {
    private let receive: (String) -> Void

    init(_ receive: @escaping (String) -> Void) {
        self.receive = receive
    }

    func userContentController(_ controller: WKUserContentController, didReceive message: WKScriptMessage) {
        guard let text = message.body as? String else { return }
        receive(text)
    }
}
