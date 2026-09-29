import AppKit
import SwiftUI

/// A film of grain laid over the glass.
///
/// Large, low-contrast gradients band badly on 8-bit displays, and perfectly
/// smooth blur reads as plastic. A few percent of noise fixes both, which is
/// why every convincing glass surface has some.
public struct NoiseOverlay: View {
    private let opacity: Double

    public init(opacity: Double = 0.035) {
        self.opacity = opacity
    }

    public var body: some View {
        Image(nsImage: Self.tile)
            .resizable(resizingMode: .tile)
            .opacity(opacity)
            .blendMode(.overlay)
            .allowsHitTesting(false)
    }

    /// Generated once and tiled — cheaper than a filter, and stable across
    /// redraws so the grain doesn't crawl while scrolling.
    private static let tile: NSImage = makeTile(side: 128)

    private static func makeTile(side: Int) -> NSImage {
        var pixels = [UInt8](repeating: 0, count: side * side * 4)
        var seed: UInt64 = 0x9E3779B97F4A7C15
        for index in stride(from: 0, to: pixels.count, by: 4) {
            seed = seed &* 6364136223846793005 &+ 1442695040888963407
            let value = UInt8((seed >> 33) & 0xFF)
            pixels[index] = value
            pixels[index + 1] = value
            pixels[index + 2] = value
            pixels[index + 3] = 255
        }

        let image = NSImage(size: NSSize(width: side, height: side))
        guard let rep = NSBitmapImageRep(
            bitmapDataPlanes: nil, pixelsWide: side, pixelsHigh: side,
            bitsPerSample: 8, samplesPerPixel: 4, hasAlpha: true, isPlanar: false,
            colorSpaceName: .deviceRGB, bytesPerRow: side * 4, bitsPerPixel: 32
        ), let target = rep.bitmapData else { return image }

        pixels.withUnsafeBufferPointer { source in
            guard let base = source.baseAddress else { return }
            target.update(from: base, count: pixels.count)
        }
        image.addRepresentation(rep)
        return image
    }
}
