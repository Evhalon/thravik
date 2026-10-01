import RedentDesign
import RedentKit
import SwiftUI

public struct WorkspacePanel: View {
    private let model: BrowserModel
    @Environment(\.dismiss) private var dismiss
    @State private var draft: SpaceDraft?

    /// The sheet's margin. Strips that scroll sideways bleed back out by it so
    /// they run to the dialog's edge instead of stopping short and clipping.
    static let contentInset: CGFloat = 20
    /// One fixed size for the list and every composer step. Sized to its
    /// content, the sheet jumped between steps and a tall step shoved the
    /// heading off the top; fixed, the steps fit themselves to it instead.
    /// `.fitted`, because `sheetCanvas`'s form sizing settles on its 380pt
    /// minimum and would center this frame, clipping both ends.
    private static let size = CGSize(width: 420, height: 600)

    public init(model: BrowserModel) { self.model = model }

    public var body: some View {
        VStack(alignment: .leading, spacing: 14) {
            SheetHeading(title: title, subtitle: subtitle)
            if let draft {
                SpaceComposer(draft: draft, onCancel: closeComposer, onCommit: commit, onChange: { self.draft = $0 })
                    .transition(.opacity.combined(with: .scale(scale: 0.97)))
            } else {
                WorkspaceSpaceList(
                    model: model,
                    onSelect: { model.execute(.focusSpace($0.id)); dismiss() },
                    onCustomize: { open(.editing($0)) }
                )
                newSpaceButton
                footer
            }
        }
        .padding(Self.contentInset)
        .frame(width: Self.size.width, height: Self.size.height, alignment: .top)
        .background(alignment: .top) { draftWash }
        .presentationSizing(.fitted)
        .presentationBackground(.ultraThinMaterial)
    }

    /// The window's own wash sits behind this sheet's material, so the dialog
    /// wears the draft's wash itself; otherwise picking one would show nothing.
    @ViewBuilder private var draftWash: some View {
        if let token = draft?.look.colorToken {
            SpaceWashFill(tint: SpaceTint(token: token), color: SpaceTintColor.color(token), strength: 1.6)
                .frame(height: 240)
                .allowsHitTesting(false)
                .animation(.easeInOut(duration: 0.3), value: token)
        }
    }

    private var title: String {
        guard let draft else { return "Spaces" }
        return draft.isEditing ? "Customize Space" : "New Space"
    }

    private var subtitle: String {
        guard draft == nil else { return "Name it, give it a color, pick an icon." }
        return "Each Space is its own profile: its own tabs, cookies, logins and bookmarks. Drag to reorder."
    }

    private var newSpaceButton: some View {
        Button { open(.new()) } label: {
            Label("New Space", systemImage: "plus")
                .font(.system(size: 13, weight: .medium))
                .foregroundStyle(Palette.chromeText)
                .frame(maxWidth: .infinity)
                .frame(height: Metric.controlHeight + 4)
                .background {
                    RoundedRectangle(cornerRadius: Metric.mediumRadius, style: .continuous)
                        .strokeBorder(Palette.chromeSecondaryText.opacity(0.4), style: StrokeStyle(lineWidth: 1, dash: [4, 3]))
                }
                .contentShape(.rect)
        }
        .buttonStyle(PressScaleStyle())
    }

    private var footer: some View {
        HStack {
            Button("Undo") { model.tabs.undoSpaces() }
                .buttonStyle(.plain)
                .foregroundStyle(Palette.chromeSecondaryText)
                .disabled(!model.tabs.canUndoSpaces)
            Spacer()
            Button("Done") { dismiss() }
                .buttonStyle(.plain)
                .font(.system(size: 13, weight: .semibold))
                .foregroundStyle(Palette.chromeText)
                .keyboardShortcut(.defaultAction)
        }
    }

    private func open(_ next: SpaceDraft) {
        withAnimation(.spring(duration: 0.3)) { draft = next }
    }

    private func closeComposer() {
        withAnimation(.spring(duration: 0.3)) { draft = nil }
    }

    private func commit(_ finished: SpaceDraft) {
        for action in finished.actions { model.execute(action) }
        closeComposer()
    }
}
