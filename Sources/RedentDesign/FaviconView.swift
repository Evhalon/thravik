import AppKit
import SwiftUI

/// A site's icon, with a fallback that still looks deliberate.
///
/// Sites without a usable favicon get a tinted tile carrying the first letter
/// of the host. The hue is derived from the host, so a site keeps the same
/// color forever and the tab strip stays scannable by color alone.
public struct FaviconView: View {
    private let data: Data?
    private let host: String?
    private let size: CGFloat

    public init(data: Data?, host: String?, size: CGFloat = 16) {
        self.data = data
        self.host = host
        self.size = size
    }

    public var body: some View {
        Group {
            if let image = decodedImage {
                Image(nsImage: image)
                    .resizable()
                    .interpolation(.high)
                    .aspectRatio(contentMode: .fit)
            } else {
                fallbackTile
            }
        }
        .frame(width: size, height: size)
        .clipShape(RoundedRectangle(cornerRadius: size * 0.28, style: .continuous))
    }

    private var decodedImage: NSImage? {
        guard let data, let image = NSImage(data: data), image.isValid else { return nil }
        return image
    }

    private var fallbackTile: some View {
        let hue = Self.hue(for: host ?? "")
        return ZStack {
            LinearGradient(
                colors: [
                    Color(hue: hue, saturation: 0.55, brightness: 0.92),
                    Color(hue: hue, saturation: 0.75, brightness: 0.66)
                ],
                startPoint: .topLeading, endPoint: .bottomTrailing
            )
            Text(Self.initial(for: host))
                .font(.system(size: size * 0.6, weight: .semibold, design: .rounded))
                .foregroundStyle(.white)
        }
    }

    private static func initial(for host: String?) -> String {
        guard let first = host?.first(where: \.isLetter) ?? host?.first else { return "•" }
        return String(first).uppercased()
    }

    /// djb2 over the host, folded into the hue circle.
    private static func hue(for host: String) -> Double {
        var hash: UInt64 = 5381
        for byte in host.utf8 { hash = (hash &* 33) &+ UInt64(byte) }
        return Double(hash % 360) / 360
    }
}

#Preview("Favicon fallbacks") {
    HStack(spacing: 10) {
        ForEach(["github.com", "figma.com", "stripe.com", "monzo.co.uk"], id: \.self) { host in
            FaviconView(data: nil, host: host, size: 28)
        }
    }
    .padding(24)
    .background(.black)
}
