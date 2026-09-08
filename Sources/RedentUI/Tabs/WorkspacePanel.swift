import RedentDesign
import RedentKit
import SwiftUI

public struct WorkspacePanel: View {
    private let model: BrowserModel
    @Environment(\.dismiss) private var dismiss
    @State private var name = ""
    @State private var editingID: UUID?

    public init(model: BrowserModel) { self.model = model }

    public var body: some View {
        VStack(alignment: .leading, spacing: 14) {
            SheetHeading(
                title: "Spaces",
                subtitle: "Each Space is its own profile: its own tabs, cookies, logins and bookmarks."
            )
            spaceList
            ChromeComposer(
                placeholder: editingID == nil ? "New Space" : "Rename Space",
                actionTitle: editingID == nil ? "Create" : "Rename",
                text: $name,
                action: save
            )
            footer
        }
        .padding(20)
        .sheetCanvas(width: 420, height: 460)
        .presentationBackground(.ultraThinMaterial)
    }

    private var spaceList: some View {
        ScrollView {
            LazyVStack(spacing: 4) {
                ForEach(model.tabs.session.spaces) { space in
                    WorkspaceSpaceRow(
                        space: space,
                        tabCount: tabCount(space.id),
                        isSelected: space.id == model.tabs.session.selectedSpaceID,
                        actions: rowActions(space)
                    )
                }
            }
        }
        .scrollIndicators(.never)
    }

    private var footer: some View {
        HStack {
            Button("Undo") { model.tabs.undo() }
                .buttonStyle(.plain)
                .foregroundStyle(Palette.chromeSecondaryText)
                .disabled(!model.tabs.canUndo)
            Spacer()
            Button("Done") { dismiss() }
                .buttonStyle(.plain)
                .font(.system(size: 13, weight: .semibold))
                .foregroundStyle(Palette.chromeText)
                .keyboardShortcut(.defaultAction)
        }
    }

    private func rowActions(_ space: BrowserSpace) -> WorkspaceSpaceRow.Actions {
        WorkspaceSpaceRow.Actions(
            canDelete: model.tabs.session.spaces.count > 1,
            onSelect: { model.execute(.focusSpace(space.id)); dismiss() },
            onRename: { editingID = space.id; name = space.name },
            onDelete: { model.execute(.deleteSpace(space.id)) }
        )
    }

    private func tabCount(_ id: UUID) -> Int {
        model.tabs.tabs.filter { $0.snapshot.spaceID == id }.count
    }

    private func save() {
        if let editingID { model.execute(.renameSpace(id: editingID, name: name)) }
        else { model.execute(.createSpace(name: name)) }
        name = ""
        editingID = nil
    }
}
