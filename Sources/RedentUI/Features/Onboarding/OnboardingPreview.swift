import SwiftUI

struct OnboardingPreview: View {
    let step: OnboardingModel.Step
    @Environment(\.accessibilityReduceMotion) private var reduceMotion
    @State private var appeared = false

    var body: some View {
        VStack(alignment: .leading, spacing: 28) {
            Spacer()
            browserPreview
                .rotation3DEffect(.degrees(appeared ? -7 : -12), axis: (x: 0, y: 1, z: 0))
                .offset(y: appeared ? 0 : 12)
                .shadow(color: .orange.opacity(0.13), radius: 30, y: 14)
            VStack(alignment: .leading, spacing: 10) {
                Text(title).font(.system(size: 23, weight: .medium, design: .rounded)).tracking(-0.4)
                Text(subtitle).font(.system(size: 13)).foregroundStyle(.white.opacity(0.48)).lineSpacing(4)
            }
            Spacer()
        }
        .padding(24)
        .frame(width: 300, height: 450)
        .background {
            RoundedRectangle(cornerRadius: 18).fill(
                LinearGradient(colors: [.white.opacity(0.035), .orange.opacity(0.06)],
                               startPoint: .topLeading, endPoint: .bottomTrailing))
        }
        .accessibilityHidden(true)
        .onAppear {
            withAnimation(reduceMotion ? nil : .spring(duration: 1.4, bounce: 0.12)) { appeared = true }
        }
    }

    private var browserPreview: some View {
        VStack(alignment: .leading, spacing: 18) {
            HStack(spacing: 5) {
                ForEach(0..<3) { _ in Circle().fill(.white.opacity(0.15)).frame(width: 5, height: 5) }
                Spacer()
                Image(systemName: "sidebar.left").font(.system(size: 10)).foregroundStyle(.secondary)
            }
            Text("Where to next?").font(.system(size: 20, weight: .medium, design: .rounded)).tracking(-0.5)
            HStack {
                Image(systemName: "magnifyingglass")
                Text("Search or ask anything")
                Spacer()
                Text("⌘K")
            }
            .font(.system(size: 9)).foregroundStyle(.white.opacity(0.45)).padding(10)
            .background(.white.opacity(0.045), in: .rect(cornerRadius: 7))
            HStack(spacing: 8) {
                tile("Design", icon: "paintpalette", color: .orange)
                tile("Work", icon: "briefcase", color: .purple)
                tile("Ideas", icon: "sparkle", color: .pink)
            }
        }
        .padding(18)
        .background(.black.opacity(0.8), in: .rect(cornerRadius: 14))
        .overlay { RoundedRectangle(cornerRadius: 14).strokeBorder(.white.opacity(0.12)) }
    }

    private func tile(_ title: String, icon: String, color: Color) -> some View {
        VStack(alignment: .leading, spacing: 10) {
            Image(systemName: icon).foregroundStyle(color)
            Text(title).foregroundStyle(.white.opacity(0.7))
        }
        .font(.system(size: 10)).padding(10).frame(maxWidth: .infinity, alignment: .leading)
        .background(color.opacity(0.09), in: .rect(cornerRadius: 8))
    }

    private var title: String {
        switch step {
        case .welcome: "A quieter kind of browser."
        case .profile: "Built around you."
        case .space: "Everything in its place."
        case .importData: "Bring your favorites."
        case .account: "At home on every Mac."
        case .sync: "Private by design."
        case .defaultBrowser: "One last choice."
        }
    }

    private var subtitle: String {
        switch step {
        case .welcome: "Room to think, explore and make something good."
        case .profile: "Small details make a workspace feel like yours."
        case .space: "Separate work, ideas and everyday life with Spaces."
        case .importData: "Bookmarks, history and saved logins. A familiar place to start."
        case .account: "One account. Your own corner of the internet."
        case .sync: "Encrypted data follows you. Your recovery code stays with you."
        case .defaultBrowser: "Choose where links open. You can change this any time in macOS settings."
        }
    }
}
