@preconcurrency import AVFoundation
import Foundation

/// Errors surfaced to the UI when the camera route can't start.
public enum CameraSessionError: Error, Equatable, Sendable {
    case unauthorized
    case noCameraAvailable
    case configurationFailed
}

/// Owns the `AVCaptureSession` lifecycle for the QR scan route.
///
/// AVFoundation's capture types predate Swift concurrency and aren't
/// Sendable-audited, hence `@preconcurrency import` above. Configuration,
/// `startRunning()`, and `stopRunning()` run on this session's serial queue —
/// never the Swift cooperative pool, which `AVCaptureSession` rejects with
/// an NSException.
@MainActor
public final class CameraSession {
    private let session = AVCaptureSession()
    private let queue = DispatchQueue(label: "app.redent.browser.camera-scan")
    private var relay: BarcodeFrameRelay?
    public private(set) lazy var previewLayer = AVCaptureVideoPreviewLayer(session: session)

    public init() {}

    public static var authorizationStatus: AVAuthorizationStatus {
        AVCaptureDevice.authorizationStatus(for: .video)
    }

    @discardableResult
    public static func requestAccess() async -> Bool {
        await AVCaptureDevice.requestAccess(for: .video)
    }

    /// Starts capturing and detecting. `onDetect` fires on whatever thread a
    /// barcode is found on — callers that touch UI state must hop to the
    /// main actor themselves.
    public func start(onDetect: @escaping @Sendable (String) -> Void) async throws {
        guard Self.authorizationStatus == .authorized else { throw CameraSessionError.unauthorized }
        guard let device = AVCaptureDevice.default(for: .video) else {
            throw CameraSessionError.noCameraAvailable
        }

        let relay = BarcodeFrameRelay(onDetect: onDetect)
        self.relay = relay
        let session = self.session
        let queue = self.queue
        try await Self.runOnQueue(queue) {
            try Self.configureAndStart(session, device: device, relay: relay, queue: queue)
        }
    }

    /// Idempotent. Safe to call from `onDisappear` even if `start` never ran.
    public func stop() {
        let session = self.session
        relay = nil
        queue.async { session.stopRunning() }
    }

    private nonisolated static func runOnQueue(_ queue: DispatchQueue, work: @escaping @Sendable () throws -> Void) async throws {
        try await withCheckedThrowingContinuation { continuation in
            queue.async {
                do {
                    try work()
                    continuation.resume()
                } catch {
                    continuation.resume(throwing: error)
                }
            }
        }
    }

    private nonisolated static func configureAndStart(
        _ session: AVCaptureSession, device: AVCaptureDevice, relay: BarcodeFrameRelay, queue: DispatchQueue
    ) throws {
        try CaptureSessionBootstrap.commitThenStart(
            begin: { session.beginConfiguration() },
            configure: { try Self.installIO(session, device: device, relay: relay, queue: queue) },
            commit: { session.commitConfiguration() },
            start: { session.startRunning() }
        )
    }

    private nonisolated static func installIO(
        _ session: AVCaptureSession, device: AVCaptureDevice, relay: BarcodeFrameRelay, queue: DispatchQueue
    ) throws {
        session.inputs.forEach { session.removeInput($0) }
        session.outputs.forEach { session.removeOutput($0) }

        guard let input = try? AVCaptureDeviceInput(device: device), session.canAddInput(input) else {
            throw CameraSessionError.configurationFailed
        }
        let output = AVCaptureVideoDataOutput()
        output.alwaysDiscardsLateVideoFrames = true
        output.setSampleBufferDelegate(relay, queue: queue)
        guard session.canAddOutput(output) else { throw CameraSessionError.configurationFailed }

        session.addInput(input)
        session.addOutput(output)
    }
}
