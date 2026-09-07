import WebKit
import RedentKit

/// Native <-> page bridge for autofill. Every call reaches into the page
/// through the isolated `redent` content world, never `.page` — and the page
/// script itself never submits a form; only the user's own click does.
extension WebTab {
    /// Fills the detected login form. Never submits it.
    public func fillCredential(username: String, password: String) async {
        await evaluateFill(function: "redentFillCredential", args: [username, password])
    }

    /// Fills the detected one-time-code field. Never submits.
    public func fillOTPCode(_ code: String) async {
        await evaluateFill(function: "redentFillOTP", args: [code])
    }

    /// Forwards a signal parsed from the page to whoever the app has
    /// registered as the controller's `signalHandler`.
    func receive(_ signal: PageSignal) {
        controller?.signalHandler?.handle(signal, fromTab: id)
    }

    /// `function` is one of our own fixed script-global names, never page
    /// content; `args` are JSON-encoded so a quote or backslash in a
    /// password can never break out of the call.
    private func evaluateFill(function: String, args: [String]) async {
        guard let webView,
              let data = try? JSONEncoder().encode(args),
              let argsJSON = String(data: data, encoding: .utf8)
        else { return }
        let script = """
        (function () {
          try {
            if (typeof window.\(function) === 'function') {
              window.\(function).apply(null, \(argsJSON));
            }
          } catch (e) {}
        })();
        """
        // Bridged explicitly rather than with `try await`: the completion-handler
        // overload defaults its handler to nil, so the bare call resolves to the
        // synchronous form and the fill would not actually be awaited.
        await withCheckedContinuation { continuation in
            webView.evaluateJavaScript(script, in: nil, in: PageScripts.contentWorld) { _ in
                continuation.resume()
            }
        }
    }
}
