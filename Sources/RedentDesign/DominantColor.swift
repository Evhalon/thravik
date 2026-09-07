import AppKit
import SwiftUI

/// Pulls the ambient hue for the chrome out of a site's favicon.
///
/// A page's own `theme-color` is unreliable as a source of character — plenty
/// of sites declare near-black or omit it entirely — whereas a favicon is
/// almost always the brand color. Saturated pixels are weighted heavily so a
/// mostly-white icon still yields its accent rather than grey.
public enum DominantColor {
    private static let cache = Cache()

    public static func extract(from data: Data?) -> Color? {
        guard let data, !data.isEmpty else { return nil }
        let key = data.hashValue
        if let cached = cache.value(for: key) { return cached }
        let color = compute(from: data)
        cache.store(color, for: key)
        return color
    }

    private static func compute(from data: Data) -> Color? {
        guard let image = NSImage(data: data),
              let bitmap = downsample(image, to: 16)
        else { return nil }

        var totals = (h: 0.0, s: 0.0, b: 0.0, weight: 0.0)
        for y in 0..<bitmap.pixelsHigh {
            for x in 0..<bitmap.pixelsWide {
                guard let pixel = bitmap.colorAt(x: x, y: y)?
                    .usingColorSpace(.sRGB), pixel.alphaComponent > 0.4 else { continue }
                // Saturation² keeps a single vivid glyph from being averaged out
                // by a large flat background.
                let weight = pixel.saturationComponent * pixel.saturationComponent
                    * (0.3 + pixel.brightnessComponent)
                guard weight > 0.01 else { continue }
                totals.h += pixel.hueComponent * weight
                totals.s += pixel.saturationComponent * weight
                totals.b += pixel.brightnessComponent * weight
                totals.weight += weight
            }
        }
        guard totals.weight > 0.05 else { return nil }
        return Color(
            hue: totals.h / totals.weight,
            saturation: min(1, totals.s / totals.weight * 1.25),
            brightness: min(1, max(0.55, totals.b / totals.weight))
        )
    }

    private static func downsample(_ image: NSImage, to side: Int) -> NSBitmapImageRep? {
        guard let rep = NSBitmapImageRep(
            bitmapDataPlanes: nil, pixelsWide: side, pixelsHigh: side,
            bitsPerSample: 8, samplesPerPixel: 4, hasAlpha: true, isPlanar: false,
            colorSpaceName: .calibratedRGB, bytesPerRow: 0, bitsPerPixel: 0
        ) else { return nil }

        NSGraphicsContext.saveGraphicsState()
        defer { NSGraphicsContext.restoreGraphicsState() }
        NSGraphicsContext.current = NSGraphicsContext(bitmapImageRep: rep)
        image.draw(in: NSRect(x: 0, y: 0, width: side, height: side))
        return rep
    }
}

/// Favicons repeat constantly across tabs; recomputing per render would put
/// a bitmap downsample on the main thread every frame.
private final class Cache: @unchecked Sendable {
    private var storage: [Int: Color?] = [:]
    private let lock = NSLock()

    func value(for key: Int) -> Color?? {
        lock.withLock { storage[key] }
    }

    func store(_ color: Color?, for key: Int) {
        lock.withLock {
            if storage.count > 200 { storage.removeAll(keepingCapacity: true) }
            storage[key] = color
        }
    }
}
