import Foundation

/// Sequences AVCaptureSession setup so `startRunning` never runs inside an
/// open `beginConfiguration` / `commitConfiguration` transaction.
///
/// Apple throws an NSException (uncaught → SIGABRT) if that order is inverted.
/// The camera permission path used to hit this: grant → `Task.detached` →
/// `startRunning` while `defer { commitConfiguration() }` had not yet run.
enum CaptureSessionBootstrap {
    static func commitThenStart(
        begin: () -> Void,
        configure: () throws -> Void,
        commit: () -> Void,
        start: () -> Void
    ) throws {
        begin()
        do {
            try configure()
        } catch {
            commit()
            throw error
        }
        commit()
        start()
    }
}
