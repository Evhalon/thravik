import RedentDesign
import SwiftUI

/// The tab as it hangs from the pointer outside its window: a small window
/// carrying the tab's pill, so it reads as the window it is about to become.
struct TabTearOffCard: View {
    static let size = CGSize(width: 260, height: 168)
    /// Room around the card for its shadow inside the transparent panel.
    static let inset: CGFloat = 28
    /// Where the pointer holds the card, from the panel's top-left: on the pill.
    static let grip = CGPoint(x: inset + 60, y: inset + 28)

    let title: String
    let faviconData: Data?
    let host: String?

    @State private var appeared = false

    var body: some View {
        VStack(alignment: .leading, spacing: 10) {
            pill
            RoundedRectangle(cornerRadius: 8, style: .continuous)
                .fill(.white.opacity(0.05))
        }
        .padding(10)
        .frame(width: Self.size.width, height: Self.size.height)
        .floatingGlass(in: RoundedRectangle(cornerRadius: 14, style: .continuous))
        .scaleEffect(appeared ? 1 : 0.82, anchor: UnitPoint(x: 0.25, y: 0.15))
        .opacity(appeared ? 1 : 0)
        .padding(Self.inset)
        .onAppear {
            withAnimation(.spring(duration: 0.28, bounce: 0.25)) { appeared = true }
        }
    }

    private var pill: some View {
        HStack(spacing: Metric.tightGutter + 2) {
            FaviconView(data: faviconData, host: host, size: 16)
            Text(title)
                .font(.system(size: 12.5, weight: .semibold))
                .lineLimit(1)
                .truncationMode(.tail)
                .foregroundStyle(Palette.chromeText)
            Spacer(minLength: 0)
        }
        .padding(.horizontal, 12)
        .frame(height: Metric.tabRowHeight)
        .background(Capsule(style: .continuous).fill(.white.opacity(0.13)))
    }
}
