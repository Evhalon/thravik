import Foundation
import Testing
@testable import RedentEngine

/// The Elements panel and the element picker: before these domains were
/// bridged, the picker button and the whole panel answered nothing.
@MainActor
@Suite struct DevToolsElementsBridgeTests {
    @Test func theDocumentArrivesWithTheIdsChromeNamesNodesBy() async throws {
        let session = try await DevToolsBridgeSession.open(body: "<h1 id='title' class='big'>Hello</h1>")
        defer { session.close() }
        try await session.result("DOM.enable")
        let root = try #require(try await session.result("DOM.getDocument")["root"] as? [String: Any])
        #expect(root["backendNodeId"] as? Int == root["nodeId"] as? Int)

        let found = try await session.result("DOM.querySelector", ["nodeId": root["nodeId"] ?? 0, "selector": "#title"])
        let h1 = try #require(found["nodeId"] as? Int)
        let described = try await session.result("DOM.describeNode", ["backendNodeId": h1])
        #expect((described["node"] as? [String: Any])?["nodeName"] as? String == "H1")
        let box = try await session.result("DOM.getBoxModel", ["nodeId": h1])
        #expect(((box["model"] as? [String: Any])?["height"] as? Int ?? 0) > 0)
    }

    @Test func thePickerAndTheHighlightReachWebKit() async throws {
        let session = try await DevToolsBridgeSession.open(body: "<p>para</p>")
        defer { session.close() }
        let root = try #require(try await session.result("DOM.getDocument")["root"] as? [String: Any])
        let p = try #require(try await session.result("DOM.querySelector", ["nodeId": root["nodeId"] ?? 0, "selector": "p"])["nodeId"])
        let config: [String: Any] = ["showInfo": true, "contentColor": ["r": 111, "g": 168, "b": 220, "a": 0.66]]

        try await session.result("Overlay.enable")
        try await session.result("Overlay.setInspectMode", ["mode": "searchForNode", "highlightConfig": config])
        try await session.result("Overlay.setInspectMode", ["mode": "none"])
        try await session.result("Overlay.highlightNode", ["backendNodeId": p, "highlightConfig": config])
        try await session.result("Overlay.hideHighlight")
    }

    @Test func stylesAreMatchedAndEditable() async throws {
        let session = try await DevToolsBridgeSession.open(body: "<h1 class='big'>Hello</h1>")
        defer { session.close() }
        try await session.result("CSS.enable")
        let root = try #require(try await session.result("DOM.getDocument")["root"] as? [String: Any])
        let h1 = try #require(try await session.result("DOM.querySelector", ["nodeId": root["nodeId"] ?? 0, "selector": "h1"])["nodeId"])

        let matched = try await session.result("CSS.getMatchedStylesForNode", ["nodeId": h1])
        let rules = (matched["matchedCSSRules"] as? [[String: Any]] ?? []).compactMap { $0["rule"] as? [String: Any] }
        let author = try #require(rules.first { $0["origin"] as? String == "regular" })
        let style = try #require(author["style"] as? [String: Any])
        let sheet = try #require(style["styleSheetId"] as? String)

        let edit: [String: Any] = ["styleSheetId": sheet, "range": style["range"] ?? [:], "text": "color: green"]
        try await session.result("CSS.setStyleTexts", ["edits": [edit]])
        let computed = try await session.result("CSS.getComputedStyleForNode", ["nodeId": h1])
        let color = (computed["computedStyle"] as? [[String: Any]])?.first { $0["name"] as? String == "color" }
        #expect(color?["value"] as? String == "rgb(0, 128, 0)")
    }
}
