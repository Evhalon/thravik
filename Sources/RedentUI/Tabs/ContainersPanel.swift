import RedentDesign
import RedentKit
import SwiftUI

/// Manages website-data boundaries: create, point a Space at one, move a tab, retire one.
public struct ContainersPanel: View {
    private let controller: any BrowserControlling
    @Environment(\.dismiss) private var dismiss
    @State private var containerName = ""
    @State private var renameID: UUID?
    @State private var failure: String?

    public init(controller: any BrowserControlling) { self.controller = controller }

    public var body: some View {
        VStack(alignment: .leading, spacing: 14) {
            SheetHeading(
                title: "Containers",
                subtitle: "Separate cookies and logins. Same site, two accounts."
            )
            containerList
            if let failure {
                Text(failure)
                    .font(.system(size: 11))
                    .foregroundStyle(Palette.danger)
            }
            ChromeComposer(
                placeholder: renameID == nil ? "New Container" : "Rename Container",
                actionTitle: renameID == nil ? "Create" : "Rename",
                text: $containerName,
                action: saveName
            )
            HStack {
                Spacer()
                Button("Done") { dismiss() }
                    .buttonStyle(.plain)
                    .font(.system(size: 13, weight: .semibold))
                    .foregroundStyle(Palette.chromeText)
                    .keyboardShortcut(.defaultAction)
            }
        }
        .padding(20)
        .sheetCanvas(width: 440, height: 460)
        .presentationBackground(.ultraThinMaterial)
    }

    private var containerList: some View {
        ScrollView {
            LazyVStack(spacing: 4) {
                ForEach(controller.session.containers) { container in
                    ContainerManageRow(
                        container: container,
                        tabCount: tabCount(container.id),
                        isSpaceDefault: container.id == activeSpaceContainer,
                        actions: rowActions(container)
                    )
                }
            }
        }
        .scrollIndicators(.never)
    }

    private func rowActions(_ container: BrowserContainer) -> ContainerManageRow.Actions {
        ContainerManageRow.Actions(
            onSetDefault: { setSpaceDefault(container.id) },
            onMoveTab: { moveSelectedTab(to: container.id) },
            onRename: { renameID = container.id; containerName = container.name },
            onDelete: { perform(.deleteContainer(id: container.id)) }
        )
    }

    private var activeSpaceContainer: UUID? {
        controller.session.spaces.first { $0.id == controller.session.selectedSpaceID }?.defaultContainerID
    }

    private func tabCount(_ id: UUID) -> Int {
        controller.tabs.filter { ($0.snapshot.containerID ?? BrowserContainer.defaultID) == id }.count
    }

    private func setSpaceDefault(_ id: UUID) {
        guard let spaceID = controller.session.selectedSpaceID else { return }
        perform(.setSpaceContainer(spaceID: spaceID, containerID: id))
    }

    private func moveSelectedTab(to id: UUID) {
        guard let tabID = controller.selectedID else { return }
        perform(.moveTabToContainer(tabID: tabID, containerID: id))
    }

    private func saveName() {
        let name = containerName.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !name.isEmpty else { return }
        if let renameID { perform(.renameContainer(id: renameID, name: name)) }
        else { perform(.createContainer(name: name)) }
        containerName = ""
        renameID = nil
    }

    private func perform(_ action: WorkspaceAction) {
        do {
            try controller.perform(action)
            failure = nil
        } catch {
            failure = "That Container is still in use, so nothing was changed."
        }
    }
}
