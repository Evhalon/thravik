@preconcurrency import AVFoundation
import Foundation
@preconcurrency import Vision

/// Runs Vision's barcode detector over camera frames, throttled to a few
/// detections per second so we don't run a `VNDetectBarcodesRequest` on every
/// single frame the camera delivers.
///
/// `@unchecked Sendable`: this delegate is only ever installed on the serial
/// queue passed to `setSampleBufferDelegate(_:queue:)`, and AVFoundation
/// guarantees `captureOutput` is only called there — so every mutable
/// property below has exactly one thread touching it, even though the
/// compiler can't see that queue confinement.
final class BarcodeFrameRelay: NSObject, AVCaptureVideoDataOutputSampleBufferDelegate, @unchecked Sendable {
    private let onDetect: @Sendable (String) -> Void
    private var lastDetectionAt = Date.distantPast
    private let minDetectionInterval: TimeInterval = 0.3

    init(onDetect: @escaping @Sendable (String) -> Void) {
        self.onDetect = onDetect
    }

    func captureOutput(
        _ output: AVCaptureOutput, didOutput sampleBuffer: CMSampleBuffer, from connection: AVCaptureConnection
    ) {
        let now = Date()
        guard now.timeIntervalSince(lastDetectionAt) >= minDetectionInterval else { return }
        guard let pixelBuffer = CMSampleBufferGetImageBuffer(sampleBuffer) else { return }
        lastDetectionAt = now
        detectQRCodes(in: pixelBuffer)
    }

    private func detectQRCodes(in pixelBuffer: CVPixelBuffer) {
        let onDetect = self.onDetect
        let request = VNDetectBarcodesRequest { request, _ in
            guard let observations = request.results as? [VNBarcodeObservation] else { return }
            for barcode in observations where barcode.symbology == .qr {
                if let payload = barcode.payloadStringValue { onDetect(payload) }
            }
        }
        request.symbologies = [.qr]
        let handler = VNImageRequestHandler(cvPixelBuffer: pixelBuffer, options: [:])
        try? handler.perform([request])
    }
}
