import AppKit
import Foundation
import Testing
@testable import Redent

@MainActor
@Suite("Quitting the app")
struct AppTerminationTests {
    // Regression: ⌘Q called terminate from inside a main-actor task, so the
    // delegate's main-actor reply could never run and the app never quit.
    @Test("Terminate runs outside any task, leaving the main actor free")
    func terminateRunsOutsideTask() async {
        _ = NSApplication.shared
        var ranInsideTask: Bool?
        AppTermination.quit(dismissing: {}, terminate: {
            ranInsideTask = withUnsafeCurrentTask { $0 != nil }
        })

        for _ in 0..<100 where ranInsideTask == nil {
            try? await Task.sleep(for: .milliseconds(50))
        }

        #expect(ranInsideTask == false)
    }
}
