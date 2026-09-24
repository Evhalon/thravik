import AppKit
import CoreGraphics
import Foundation
import ImageIO

/// Draws a web app's Dock icon: the site's own icon on a light macOS tile, or
/// the app's initial when the site has none that can be read.
enum WebAppIconRenderer {
    private static let canvas = 1024
    /// Apple's icon grid: an 824-point tile centred on the 1024 canvas.
    private static let tile = CGRect(x: 100, y: 100, width: 824, height: 824)
    private static let cornerRadius: CGFloat = 185

    /// An `.icns` file for `name`, drawn from `favicon` when it decodes.
    static func icns(favicon: Data?, name: String) -> Data? {
        guard let master = render(favicon: favicon.flatMap(decode), name: name) else { return nil }
        let chunks = ICNSEncoder.renditions.compactMap { rendition in
            png(master, pixels: rendition.pixels).map { (type: rendition.type, png: $0) }
        }
        return chunks.count == ICNSEncoder.renditions.count ? ICNSEncoder.encode(chunks) : nil
    }

    /// The largest frame, so an `.ico` holding 16, 32 and 256 draws from 256.
    static func decode(_ data: Data) -> CGImage? {
        guard let source = CGImageSourceCreateWithData(data as CFData, nil) else { return nil }
        let frames = (0..<CGImageSourceGetCount(source)).compactMap { CGImageSourceCreateImageAtIndex(source, $0, nil) }
        return frames.max { $0.width < $1.width }
    }

    private static func render(favicon: CGImage?, name: String) -> CGImage? {
        guard let context = makeContext(pixels: canvas) else { return nil }
        let path = CGPath(roundedRect: tile, cornerWidth: cornerRadius, cornerHeight: cornerRadius, transform: nil)
        context.saveGState()
        context.setShadow(offset: CGSize(width: 0, height: -10), blur: 24, color: CGColor(gray: 0, alpha: 0.28))
        context.addPath(path)
        context.setFillColor(favicon == nil ? monogramColor(for: name) : CGColor(gray: 0.98, alpha: 1))
        context.fillPath()
        context.restoreGState()
        context.addPath(path)
        context.clip()
        if let favicon {
            context.interpolationQuality = .high
            context.draw(favicon, in: faviconFrame(for: favicon))
        } else {
            drawInitial(of: name, in: context)
        }
        return context.makeImage()
    }

    /// A large, opaque icon (an apple-touch-icon) is already a tile and fills
    /// this one; a small or transparent favicon sits in the middle of it.
    private static func faviconFrame(for image: CGImage) -> CGRect {
        if image.width >= 120 && hasOpaqueCorners(image) { return tile }
        let side = tile.width * 0.62
        return CGRect(x: tile.midX - side / 2, y: tile.midY - side / 2, width: side, height: side)
    }

    /// PNG decoding hands back an alpha channel even for a fully opaque image,
    /// so the corners are sampled rather than trusting the pixel format.
    private static func hasOpaqueCorners(_ image: CGImage) -> Bool {
        let side = 16
        guard let context = makeContext(pixels: side) else { return false }
        context.draw(image, in: CGRect(x: 0, y: 0, width: side, height: side))
        guard let pixels = context.data?.assumingMemoryBound(to: UInt8.self) else { return false }
        let row = context.bytesPerRow
        let corners = [0, (side - 1) * 4, (side - 1) * row, (side - 1) * row + (side - 1) * 4]
        return corners.allSatisfy { pixels[$0 + 3] == 255 }
    }

    private static func drawInitial(of name: String, in context: CGContext) {
        let letter = String(name.trimmingCharacters(in: .whitespaces).prefix(1)).uppercased()
        let text = NSAttributedString(string: letter.isEmpty ? "•" : letter, attributes: [
            .font: NSFont.systemFont(ofSize: 480, weight: .semibold),
            .foregroundColor: NSColor.white
        ])
        NSGraphicsContext.saveGraphicsState()
        NSGraphicsContext.current = NSGraphicsContext(cgContext: context, flipped: false)
        let size = text.size()
        text.draw(at: CGPoint(x: tile.midX - size.width / 2, y: tile.midY - size.height / 2))
        NSGraphicsContext.restoreGraphicsState()
    }

    /// Stable per name, so reinstalling an app never changes its colour.
    private static func monogramColor(for name: String) -> CGColor {
        let hue = Double(name.unicodeScalars.reduce(0) { ($0 &* 31 &+ Int($1.value)) % 360 }) / 360
        return NSColor(hue: hue, saturation: 0.55, brightness: 0.78, alpha: 1).cgColor
    }

    private static func png(_ master: CGImage, pixels: Int) -> Data? {
        guard let context = makeContext(pixels: pixels) else { return nil }
        context.interpolationQuality = .high
        context.draw(master, in: CGRect(x: 0, y: 0, width: pixels, height: pixels))
        guard let image = context.makeImage() else { return nil }
        let data = NSMutableData()
        guard let destination = CGImageDestinationCreateWithData(data, "public.png" as CFString, 1, nil) else { return nil }
        CGImageDestinationAddImage(destination, image, nil)
        return CGImageDestinationFinalize(destination) ? data as Data : nil
    }

    private static func makeContext(pixels: Int) -> CGContext? {
        CGContext(data: nil, width: pixels, height: pixels, bitsPerComponent: 8, bytesPerRow: 0,
                  space: CGColorSpace(name: CGColorSpace.sRGB) ?? CGColorSpaceCreateDeviceRGB(),
                  bitmapInfo: CGImageAlphaInfo.premultipliedLast.rawValue)
    }
}
