import RedentDesign
import RedentKit
import SwiftUI

/// The mini funnel for making or reshaping a Space: one decision per step,
/// with the finished orb previewed the whole way through.
struct SpaceComposer: View {
    @State private var draft: SpaceDraft
    @FocusState private var isNameFocused: Bool
    private let onCancel: () -> Void
    private let onCommit: (SpaceDraft) -> Void
    private let onChange: (SpaceDraft) -> Void
    private let commitTitle: String?

    init(
        draft: SpaceDraft,
        onCancel: @escaping () -> Void,
        onCommit: @escaping (SpaceDraft) -> Void,
        onChange: @escaping (SpaceDraft) -> Void,
        commitTitle: String? = nil
    ) {
        _draft = State(initialValue: draft)
        self.onCancel = onCancel
        self.onCommit = onCommit
        self.onChange = onChange
        self.commitTitle = commitTitle
    }

    var body: some View {
        VStack(spacing: 14) {
            SpaceComposerPreview(draft: draft)
            SpaceStepBar(draft: $draft)
            stepContent
                .frame(minHeight: 0, maxHeight: .infinity, alignment: .top)
                .animation(.spring(duration: 0.3), value: draft.step)
            navigation
        }
        .onAppear { isNameFocused = true }
        .onChange(of: draft.look) { onChange(draft) }
    }

    @ViewBuilder private var stepContent: some View {
        switch draft.step {
        case .name: nameField.transition(stepTransition)
        case .color: SpaceColorStep(token: colorToken).transition(stepTransition)
        case .icon: SpaceIconGrid(selection: icon, tint: tint).transition(stepTransition)
        }
    }

    private var nameField: some View {
        TextField("Space name", text: $draft.name)
            .textFieldStyle(.plain)
            .font(.system(size: 15, weight: .medium))
            .multilineTextAlignment(.center)
            .foregroundStyle(Palette.chromeText)
            .padding(.horizontal, 12)
            .frame(height: 38)
            .background {
                RoundedRectangle(cornerRadius: Metric.mediumRadius, style: .continuous)
                    .fill(.black.opacity(0.16))
                    .strokeBorder(tint.opacity(0.5), lineWidth: 1)
            }
            .focused($isNameFocused)
            .onSubmit { withAnimation { draft.advance() } }
    }

    private var navigation: some View {
        HStack {
            Button(draft.isFirstStep ? "Cancel" : "Back", action: back)
                .buttonStyle(.plain)
                .foregroundStyle(Palette.chromeSecondaryText)
                .keyboardShortcut(.cancelAction)
            Spacer()
            Button(primaryTitle, action: forward)
                .font(.system(size: 12, weight: .semibold))
                .foregroundStyle(.white)
                .padding(.horizontal, 14)
                .frame(height: Metric.controlHeight)
                .background(Capsule().fill(tint.opacity(draft.trimmedName == nil ? 0.3 : 0.9)))
                .buttonStyle(PressScaleStyle())
                .disabled(draft.trimmedName == nil)
                .keyboardShortcut(.defaultAction)
        }
    }

    private var primaryTitle: String {
        guard draft.isLastStep else { return "Next" }
        return commitTitle ?? (draft.isEditing ? "Save" : "Create Space")
    }

    private var stepTransition: AnyTransition {
        .asymmetric(insertion: .move(edge: .trailing), removal: .move(edge: .leading)).combined(with: .opacity)
    }

    private var tint: Color { SpaceTintColor.color(draft.look.colorToken) }

    private var colorToken: Binding<String> {
        Binding(
            get: { draft.look.colorToken },
            set: { draft.look = SpaceIdentity.Look(icon: draft.look.icon, colorToken: $0) }
        )
    }

    private var icon: Binding<String> {
        Binding(
            get: { draft.look.icon },
            set: { draft.look = SpaceIdentity.Look(icon: $0, colorToken: draft.look.colorToken) }
        )
    }

    private func back() {
        guard !draft.isFirstStep else { return onCancel() }
        withAnimation { draft.retreat() }
    }

    private func forward() {
        guard draft.isLastStep else { return withAnimation { draft.advance() } }
        onCommit(draft)
    }
}
