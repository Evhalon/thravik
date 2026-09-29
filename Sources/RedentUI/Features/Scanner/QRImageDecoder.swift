import CoreGraphics
import Foundation
import ImageIO
@preconcurrency import Vision

/// Finds QR payloads inside a still image — screenshots of the export QR
/// taken on a second phone are the path most people actually use.
enum QRImageDecoder {
    enum DecodeError: Error, Equatable {
        case unreadableImage
    }

    /// Decodes off the main actor; `data` is whatever a drop, paste, or file
    /// pick handed us.
    static func payloads(inImageData data: Data) async throws -> [String] {
        guard let cgImage = cgImage(from: data) else { throw DecodeError.unreadableImage }
        return try await Task.detached(priority: .userInitiated) {
            try detectPayloads(in: cgImage)
        }.value
    }

    private static func detectPayloads(in cgImage: CGImage) throws -> [String] {
        let request = VNDetectBarcodesRequest()
        request.symbologies = [.qr]
        let handler = VNImageRequestHandler(cgImage: cgImage, options: [:])
        try handler.perform([request])
        let observations = request.results ?? []
        return observations.compactMap(\.payloadStringValue)
    }

    private static func cgImage(from data: Data) -> CGImage? {
        guard let source = CGImageSourceCreateWithData(data as CFData, nil) else { return nil }
        return CGImageSourceCreateImageAtIndex(source, 0, nil)
    }
}
