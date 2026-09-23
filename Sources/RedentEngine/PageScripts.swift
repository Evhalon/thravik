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

    /// Frames relay mute requests to their children with this; a page never
    /// sees the isolated world's copy, so it cannot guess one to replay.
    private static let mediaRelayToken = UUID().uuidString
    private static let quietRelayToken = UUID().uuidString

    /// Adds the user scripts to a fresh configuration's content controller: the
    /// credential bridge, find-in-page, tab audio, Reader, and Quiet mode when on.
    /// A missing resource is a no-op, never a crash — a bundle resource must
    /// never be force-unwrapped.
    static func install(into controller: WKUserContentController, quiets: Bool) {
        for name in ["redent-page", "redent-find"] {
            add(loadSource(named: name), at: .atDocumentEnd, to: controller)
        }
        // At document start: a page that autoplays on load must already be heard.
        let media = loadSource(named: "redent-media")?
            .replacingOccurrences(of: "__REDENT_MEDIA_RELAY__", with: mediaRelayToken)
        add(media, at: .atDocumentStart, to: controller)
        add(loadSource(named: "redent-reader"), at: .atDocumentEnd, mainFrameOnly: true, to: controller)
        if quiets { add(quietSource, at: .atDocumentStart, to: controller) }
    }

    /// Quiet mode leaves the media sites' own players alone, the same set the
    /// content blocker steps aside for.
    private static var quietSource: String? {
        let hosts = MediaRuleExceptions.mediaDomains.sorted()
        guard let data = try? JSONEncoder().encode(hosts), let list = String(data: data, encoding: .utf8)
        else { return nil }
        return loadSource(named: "redent-quiet")?
            .replacingOccurrences(of: "__REDENT_MEDIA_HOSTS__", with: list)
            .replacingOccurrences(of: "__REDENT_QUIET_RELAY__", with: quietRelayToken)
    }

    private static func add(
        _ source: String?,
        at time: WKUserScriptInjectionTime,
        mainFrameOnly: Bool = false,
        to controller: WKUserContentController
    ) {
        guard let source else { return }
        controller.addUserScript(
            WKUserScript(source: source, injectionTime: time, forMainFrameOnly: mainFrameOnly, in: contentWorld)
        )
    }

    private static func loadSource(named name: String) -> String? {
        guard let url = EngineResources.url(forResource: name, withExtension: "js"),
              let data = try? Data(contentsOf: url)
        else { return nil }
        return String(data: data, encoding: .utf8)
    }
}
