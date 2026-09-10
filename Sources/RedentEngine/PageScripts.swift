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

    /// Adds the user scripts to a fresh configuration's content controller: the
    /// credential bridge, and find-in-page. A missing resource is a no-op,
    /// never a crash — a bundle resource must never be force-unwrapped.
    static func install(into controller: WKUserContentController) {
        for name in ["redent-page", "redent-find"] {
            guard let source = loadSource(named: name) else { continue }
            controller.addUserScript(
                WKUserScript(
                    source: source,
                    injectionTime: .atDocumentEnd,
                    forMainFrameOnly: false,
                    in: contentWorld
                )
            )
        }
    }

    private static func loadSource(named name: String) -> String? {
        guard let url = EngineResources.url(forResource: name, withExtension: "js"),
              let data = try? Data(contentsOf: url)
        else { return nil }
        return String(data: data, encoding: .utf8)
    }
}
