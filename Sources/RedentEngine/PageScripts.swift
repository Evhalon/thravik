import WebKit

/// Installs the Redent page bridge script into an isolated content world.
///
/// The script never runs in `.page` — that would let the site's own scripts
/// see or tamper with credential/OTP detection. It runs in a world named
/// `redent` that only Redent's native code can talk to.
@MainActor
enum PageScripts {
    static let contentWorld = WKContentWorld.world(name: "redent")
    static let messageHandlerName = "redentBridge"

    /// Adds the bridge user script to a fresh configuration's content
    /// controller. A missing resource is a no-op, never a crash — a bundle
    /// resource must never be force-unwrapped.
    static func install(into controller: WKUserContentController) {
        guard let source = loadSource() else { return }
        let script = WKUserScript(
            source: source,
            injectionTime: .atDocumentEnd,
            forMainFrameOnly: false,
            in: contentWorld
        )
        controller.addUserScript(script)
    }

    private static func loadSource() -> String? {
        guard let url = Bundle.module.url(forResource: "redent-page", withExtension: "js"),
              let data = try? Data(contentsOf: url)
        else { return nil }
        return String(data: data, encoding: .utf8)
    }
}
