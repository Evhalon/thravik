import SwiftUI

struct FloatingNewTabHeaderSurface: View {
    @Environment(\.colorScheme) private var scheme

    var body: some View {
        let shape = UnevenRoundedRectangle(topLeadingRadius: 20, bottomLeadingRadius: 0,
                                           bottomTrailingRadius: 0, topTrailingRadius: 20)
        shape.fill(.regularMaterial)
            .overlay {
                shape.fill(LinearGradient(
                    colors: [.white.opacity(scheme == .dark ? 0.15 : 0.48), .clear],
                    startPoint: .top, endPoint: .bottom
                ))
            }
    }
}
