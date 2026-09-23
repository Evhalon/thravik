import RedentDesign
import SwiftUI

/// The glassy square that carries a site's favicon on the new-tab surface.
///
/// Shared by the resting tile and its drag preview so a lifted favorite looks
/// exactly like the one the user grabbed.
struct FavoriteTileIcon: View {
    let host: String
    let iconData: Data?
    let accent: Color
    let isFavorite: Bool
    var isLifted = false

    private let shape = RoundedRectangle(cornerRadius: 17, style: .continuous)

    var body: some View {
        ZStack {
            shape.fill(accent.opacity(isLifted ? 0.34 : 0.18))
            shape.fill(
                LinearGradient(colors: [.white.opacity(0.14), .clear], startPoint: .top, endPoint: .center)
            )
            shape.strokeBorder(
                LinearGradient(colors: [.white.opacity(0.32), .white.opacity(0.05)],
                               startPoint: .top, endPoint: .bottom),
                lineWidth: Metric.hairWidth
            )
            FaviconView(data: iconData, host: host, size: 30)
        }
        .frame(width: 62, height: 62)
        .compositingGroup()
        .shadow(color: accent.opacity(isLifted ? 0.5 : 0.18), radius: isLifted ? 16 : 7, y: isLifted ? 8 : 4)
        .overlay(alignment: .topTrailing) { badge }
    }

    @ViewBuilder
    private var badge: some View {
        if isFavorite {
            Image(systemName: "star.fill")
                .font(.system(size: 8))
                .foregroundStyle(.white.opacity(0.9))
                .padding(4)
                .background(Circle().fill(accent.opacity(0.95)))
                .offset(x: 5, y: -5)
        }
    }
}
