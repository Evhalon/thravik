import SwiftUI

/// The scrolling region under the new-tab search field.
///
/// It runs to the bottom of the window and fades out there, so a grid taller
/// than the window reads as "more below" instead of being cut off.
struct NewTabScrollArea<Content: View>: View {
    @ViewBuilder let content: () -> Content

    private let fadeHeight: CGFloat = 56

    var body: some View {
        ScrollView {
            content()
                // Room for the favorite badge and hover glow above the first row.
                .padding(.top, 10)
                .padding(.bottom, fadeHeight)
        }
        .scrollIndicators(.never)
        .mask { fade }
    }

    private var fade: some View {
        VStack(spacing: 0) {
            Color.black
            LinearGradient(colors: [.black, .clear], startPoint: .top, endPoint: .bottom)
                .frame(height: fadeHeight)
        }
    }
}
