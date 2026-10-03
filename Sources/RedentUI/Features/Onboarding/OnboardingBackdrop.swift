import SwiftUI

struct OnboardingBackdrop: View {
    var body: some View {
        ZStack {
            Color(red: 0.94, green: 0.93, blue: 0.92)
            RadialGradient(colors: [.purple.opacity(0.18), .clear], center: .topLeading,
                           startRadius: 0, endRadius: 640)
            RadialGradient(colors: [.orange.opacity(0.2), .clear], center: .bottomTrailing,
                           startRadius: 0, endRadius: 580)
        }
        .allowsHitTesting(false)
        .accessibilityHidden(true)
    }
}
