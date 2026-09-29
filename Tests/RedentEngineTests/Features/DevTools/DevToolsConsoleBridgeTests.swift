import Foundation
import Testing
@testable import RedentEngine

/// What the Console needed from the bridge beyond plain evaluation.
@MainActor
@Suite struct DevToolsConsoleBridgeTests {
    @Test func eagerEvaluationRunsOnlyWhatCannotChangeThePage() async throws {
        let session = try await DevToolsBridgeSession.open()
        defer { session.close() }
        try await session.result("Runtime.enable")
        let safe = try await session.result("Runtime.evaluate", ["expression": "pageLexical * 2", "throwOnSideEffect": true])
        #expect((safe["result"] as? [String: Any])?["value"] as? Int == 10)

        let unsafe = try await session.result("Runtime.evaluate", ["expression": "window.touched = 1", "throwOnSideEffect": true])
        #expect(unsafe["exceptionDetails"] != nil)
        let check = try await session.result("Runtime.evaluate", ["expression": "typeof window.touched"])
        #expect((check["result"] as? [String: Any])?["value"] as? String == "undefined")
    }

    @Test func autocompletionKnowsTheTopLevelLetNames() async throws {
        let session = try await DevToolsBridgeSession.open()
        defer { session.close() }
        try await session.result("Debugger.enable")
        let names = try await session.result("Runtime.globalLexicalScopeNames")["names"] as? [String] ?? []
        #expect(names.contains("pageLexical"))
    }

    @Test func errorsCarryTheirStackTheWayChromeReadsIt() async throws {
        let session = try await DevToolsBridgeSession.open()
        defer { session.close() }
        let thrown = try await session.result("Runtime.evaluate", ["expression": "fail()"])
        let exception = try #require((thrown["exceptionDetails"] as? [String: Any])?["exception"] as? [String: Any])
        let description = try #require(exception["description"] as? String)
        #expect(description.hasPrefix("RangeError: page error\n    at fail ("))

        let error = try await session.result("Runtime.evaluate", ["expression": "(() => { try { fail() } catch (e) { return e } })()"])
        let objectId = try #require((error["result"] as? [String: Any])?["objectId"])
        let details = try await session.result("Runtime.getExceptionDetails", ["errorObjectId": objectId])
        let frames = ((details["exceptionDetails"] as? [String: Any])?["stackTrace"] as? [String: Any])?["callFrames"] as? [[String: Any]]
        #expect(frames?.first?["functionName"] as? String == "fail")
    }

    @Test func countKeepsItsOwnLevelAndDollarUnderscoreRemembers() async throws {
        let session = try await DevToolsBridgeSession.open()
        defer { session.close() }
        try await session.result("Runtime.enable")
        try await session.result("Runtime.evaluate", ["expression": "console.count('c')"])
        let count = await session.event("Runtime.consoleAPICalled") { $0["type"] as? String == "count" }
        #expect(count != nil)

        try await session.result("Runtime.evaluate", ["expression": "6 * 7", "replMode": true, "includeCommandLineAPI": true])
        let last = try await session.result("Runtime.evaluate", ["expression": "$_ + 1", "includeCommandLineAPI": true])
        #expect((last["result"] as? [String: Any])?["value"] as? Int == 43)
    }

    @Test func aFunctionLinksToItsSource() async throws {
        let session = try await DevToolsBridgeSession.open()
        defer { session.close() }
        let greet = try await session.result("Runtime.evaluate", ["expression": "greet"])
        let objectId = try #require((greet["result"] as? [String: Any])?["objectId"])
        let properties = try await session.result("Runtime.getProperties", ["objectId": objectId, "ownProperties": false])
        let internals = properties["internalProperties"] as? [[String: Any]] ?? []
        #expect(internals.contains { $0["name"] as? String == "[[FunctionLocation]]" })
    }
}
