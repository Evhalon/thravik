import RedentDesign
import RedentKit
import SwiftUI

/// The icon shelves as chips; no shelf picked means the whole catalog.
struct SpaceIconFilterBar: View {
    @Binding var category: SpaceIconCategory?
    let tint: Color

    /// Out to the dialog's edge: the sheet margin plus the icon step's own.
    private static let bleed = WorkspacePanel.contentInset + 4

    var body: some View {
        ScrollView(.horizontal) {
            HStack(spacing: 6) {
                chip("All", isSelected: category == nil) { category = nil }
                ForEach(SpaceIconCategory.allCases, id: \.self) { shelf in
                    chip(Self.title(shelf), isSelected: category == shelf) { category = shelf }
                }
            }
        }
        .scrollIndicators(.never)
        .contentMargins(.horizontal, Self.bleed, for: .scrollContent)
        .padding(.horizontal, -Self.bleed)
        .frame(height: 24)
    }

    private func chip(_ title: String, isSelected: Bool, pick: @escaping () -> Void) -> some View {
        Button(action: pick) {
            Text(title)
                .font(.system(size: 11, weight: .semibold))
                .foregroundStyle(isSelected ? Color.white : Palette.chromeSecondaryText)
                .padding(.horizontal, 10)
                .frame(height: 22)
                .background(Capsule().fill(isSelected ? tint.opacity(0.85) : Palette.chromeFill))
                .contentShape(.capsule)
        }
        .buttonStyle(.plain)
        .accessibilityAddTraits(isSelected ? .isSelected : [])
    }

    private static func title(_ category: SpaceIconCategory) -> String {
        switch category {
        case .developer: "Developer"
        case .work: "Work"
        case .personal: "Personal"
        case .creative: "Creative"
        case .learning: "Learning"
        case .play: "Play"
        case .health: "Health"
        case .travel: "Travel"
        case .money: "Money"
        }
    }
}
