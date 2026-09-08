import Foundation
import Testing
@testable import RedentUpdate

@Suite("Relaunch helper")
struct RelaunchScriptTests {
    private let staged = URL(fileURLWithPath: "/tmp/thravik-update/Thravik.app")
    private let target = URL(fileURLWithPath: "/Applications/Thravik.app")

    @Test("The swap waits for the running app to exit")
    func waitsForTheApp() {
        let script = RelaunchScript.source(stagedApp: staged, target: target, pid: 4242)
        #expect(script.contains("while kill -0 4242"))
        // The copy must not start before the wait loop, or it would replace a
        // bundle whose web processes are still running out of it.
        guard let wait = script.range(of: "while kill -0"),
              let copy = script.range(of: "ditto")
        else {
            Issue.record("the helper must wait for the app, then copy")
            return
        }
        #expect(wait.lowerBound < copy.lowerBound)
    }

    @Test("A failed swap puts the old app back and reopens it")
    func restoresOnFailure() {
        let script = RelaunchScript.source(stagedApp: staged, target: target, pid: 1)
        #expect(script.contains("mv \"$backup\" \"$target\""))
        #expect(script.contains("open \"$target\""))
    }

    @Test("A path with quotes in it stays data and never becomes a command")
    func quotesHostilePaths() async throws {
        let canary = URL(fileURLWithPath: NSTemporaryDirectory())
            .appendingPathComponent("canary-\(UUID().uuidString)")
        let hostile = "/tmp/it's here'; touch \(canary.path); '/Thravik.app"
        let script = RelaunchScript.source(
            stagedApp: URL(fileURLWithPath: hostile), target: target, pid: 1
        )
        let assignment = try #require(
            script.split(separator: "\n").first { $0.hasPrefix("staged=") }
        )

        let echoed = URL(fileURLWithPath: NSTemporaryDirectory())
            .appendingPathComponent("echo-\(UUID().uuidString)")
        defer { try? FileManager.default.removeItem(at: echoed) }
        try await Shell.run("/bin/sh", ["-c", "\(assignment); printf '%s' \"$staged\" > \(echoed.path)"])

        #expect(try String(contentsOf: echoed, encoding: .utf8) == hostile)
        #expect(!FileManager.default.fileExists(atPath: canary.path))
    }

    @Test("The helper it writes is valid shell")
    func isValidShell() async throws {
        let script = RelaunchScript.source(stagedApp: staged, target: target, pid: 1)
        let path = URL(fileURLWithPath: NSTemporaryDirectory())
            .appendingPathComponent("relaunch-\(UUID().uuidString).sh")
        try script.write(to: path, atomically: true, encoding: .utf8)
        defer { try? FileManager.default.removeItem(at: path) }
        #expect(await Shell.succeeds("/bin/sh", ["-n", path.path]))
    }
}
