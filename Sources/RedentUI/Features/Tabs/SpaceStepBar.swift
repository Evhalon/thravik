import RedentDesign
import RedentKit
import SwiftUI

/// Where the funnel is, and a way back to any step already unlocked.
struct SpaceStepBar: View {
    @Binding var draft: SpaceDraft

    var body: some View {
        HStack(spacing: 6) {
            ForEach(SpaceDraft.Step.allCases, id: \.self) { step in
                pill(step)
            }
        }
    }

    private func pill(_ step: SpaceDraft.Step) -> some View {
        let isCurrent = step == draft.step
        let isDone = step.rawValue < draft.step.rawValue
        return Button {
            withAnimation { draft.step = step }
        } label: {
            HStack(spacing: 4) {
                Image(systemName: isDone ? "checkmark" : "\(step.rawValue + 1).circle.fill")
                    .font(.system(size: 9, weight: .bold))
                Text(step.title).font(.system(size: 11, weight: .semibold))
            }
            .foregroundStyle(isCurrent ? Color.white : Palette.chromeSecondaryText)
            .padding(.horizontal, 10)
            .frame(height: 22)
            .background(Capsule().fill(isCurrent ? tint.opacity(0.85) : Palette.chromeFill))
        }
        .buttonStyle(.plain)
        .disabled(!draft.canReach(step))
        .animation(.spring(duration: 0.28), value: draft.step)
    }

    private var tint: Color { SpacePalette.color(draft.look.colorToken) }
}
