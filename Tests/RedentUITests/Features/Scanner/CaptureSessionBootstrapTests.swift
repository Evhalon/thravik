import Testing
@testable import RedentUI

@Suite("AVCaptureSession start order")
struct CaptureSessionBootstrapTests {
    @Test("startRunning happens after commitConfiguration")
    func startAfterCommit() throws {
        var calls: [String] = []
        try CaptureSessionBootstrap.commitThenStart(
            begin: { calls.append("begin") },
            configure: { calls.append("configure") },
            commit: { calls.append("commit") },
            start: { calls.append("start") }
        )
        #expect(calls == ["begin", "configure", "commit", "start"])
    }

    @Test("failed configure still commits and never starts")
    func configureFailureCommitsWithoutStart() {
        var calls: [String] = []
        enum Fail: Error { case boom }
        #expect(throws: Fail.boom) {
            try CaptureSessionBootstrap.commitThenStart(
                begin: { calls.append("begin") },
                configure: {
                    calls.append("configure")
                    throw Fail.boom
                },
                commit: { calls.append("commit") },
                start: { calls.append("start") }
            )
        }
        #expect(calls == ["begin", "configure", "commit"])
    }
}
