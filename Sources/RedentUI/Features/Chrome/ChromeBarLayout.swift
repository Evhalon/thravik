import SwiftUI

/// Lays out the toolbar as leading cluster, centered address cluster, and
/// trailing cluster.
///
/// The middle cluster is centered on the whole row, not on whatever space the
/// side clusters leave, so the address sits in the same place whichever
/// buttons happen to be showing. When the row is too narrow for that, the
/// middle cluster fills the gap between the sides instead.
struct ChromeBarLayout: Layout {
    var spacing: CGFloat
    var centerMaxWidth: CGFloat
    var centerMinWidth: CGFloat

    func sizeThatFits(proposal: ProposedViewSize, subviews: Subviews, cache: inout ()) -> CGSize {
        let height = subviews.map { $0.sizeThatFits(.unspecified).height }.max() ?? 0
        let width = proposal.width ?? subviews.map { $0.sizeThatFits(.unspecified).width }.reduce(0, +)
        return CGSize(width: width, height: height)
    }

    func placeSubviews(in bounds: CGRect, proposal: ProposedViewSize, subviews: Subviews, cache: inout ()) {
        guard subviews.count == 3 else { return }
        let leading = subviews[0], center = subviews[1], trailing = subviews[2]
        let leadingWidth = leading.sizeThatFits(.unspecified).width
        let trailingWidth = trailing.sizeThatFits(.unspecified).width
        let centerFrame = centerFrame(in: bounds, leadingWidth: leadingWidth, trailingWidth: trailingWidth)

        leading.place(at: CGPoint(x: bounds.minX, y: bounds.midY), anchor: .leading,
                      proposal: ProposedViewSize(width: leadingWidth, height: bounds.height))
        center.place(at: CGPoint(x: centerFrame.minX, y: bounds.midY), anchor: .leading,
                     proposal: ProposedViewSize(width: centerFrame.width, height: bounds.height))
        trailing.place(at: CGPoint(x: bounds.maxX, y: bounds.midY), anchor: .trailing,
                       proposal: ProposedViewSize(width: trailingWidth, height: bounds.height))
    }

    private func centerFrame(in bounds: CGRect, leadingWidth: CGFloat, trailingWidth: CGFloat) -> CGRect {
        let sideReach = max(leadingWidth, trailingWidth) + spacing
        let centeredWidth = min(centerMaxWidth, bounds.width - 2 * sideReach)
        if centeredWidth >= centerMinWidth {
            return CGRect(x: bounds.midX - centeredWidth / 2, y: bounds.minY,
                          width: centeredWidth, height: bounds.height)
        }
        let start = bounds.minX + leadingWidth + spacing
        let available = max(0, bounds.width - leadingWidth - trailingWidth - 2 * spacing)
        return CGRect(x: start, y: bounds.minY, width: min(available, centerMaxWidth), height: bounds.height)
    }
}
