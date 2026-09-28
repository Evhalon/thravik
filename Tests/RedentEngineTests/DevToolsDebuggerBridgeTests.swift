import Foundation
import Testing
@testable import RedentEngine

/// Breakpoints, `monitor`, and the hidden Web Inspector staying hidden.
@MainActor
@Suite struct DevToolsDebuggerBridgeTests {
    /// WebKit starts with breakpoints off, and its hidden Web Inspector shows
    /// its own window on every pause: a breakpoint never stopped the page,
    /// and once it did, Safari's inspector popped up over the browser.
    @Test func aBreakpointPausesThePageAndOnlyChromeSeesIt() async throws {
        let session = try await DevToolsBridgeSession.open()
        defer { session.close() }
        try await session.result("Runtime.enable")
        try await session.result("Debugger.enable")
        try await session.result("Debugger.setBreakpointByUrl", ["url": "app.js", "lineNumber": 2, "columnNumber": 2])
        try await session.result("Runtime.evaluate", ["expression": "setTimeout(() => greet('x'), 0)"])

        let paused = await session.event("Debugger.paused")
        let frames = paused?["callFrames"] as? [[String: Any]]
        #expect(frames?.first?["functionName"] as? String == "greet")
        #expect(!session.isHiddenInspectorVisible)
        try await session.result("Debugger.resume")
    }

    @Test func monitorLogsCallsUntilUnmonitored() async throws {
        let session = try await DevToolsBridgeSession.open()
        defer { session.close() }
        try await session.result("Runtime.enable")
        try await session.result("Debugger.enable")
        let repl: [String: Any] = ["replMode": true, "includeCommandLineAPI": true]
        try await session.result("Runtime.evaluate", repl.merging(["expression": "monitor(greet)"]) { $1 })
        try await session.result("Runtime.evaluate", ["expression": "setTimeout(() => greet('ada'), 0)"])

        let logged = await session.event("Runtime.consoleAPICalled") { params in
            let args = params["args"] as? [[String: Any]] ?? []
            return args.contains { $0["value"] as? String == "function greet called with arguments: ada" }
        }
        #expect(logged != nil)
    }
}
