import RedentDesign
import RedentKit
import SwiftUI

public struct TabGroupsPanel: View {
    private let controller: any BrowserControlling
    @Environment(\.dismiss) private var dismiss
    @State private var groupName = ""
    @State private var renameID: UUID?
    @State private var dismissedSuggestions: Set<String> = []
    private let suggester = GroupingSuggestionService()

    public init(controller: any BrowserControlling) { self.controller = controller }

    public var body: some View {
        VStack(alignment: .leading, spacing: 14) {
            SheetHeading(
                title: "Tab Groups",
                subtitle: "Clusters inside this Space. Related tabs stay together."
            )
            groupList
            suggestionList
            ChromeComposer(
                placeholder: renameID == nil ? "New group" : "Rename group",
                actionTitle: renameID == nil ? "Create" : "Rename",
                text: $groupName,
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
        .sheetCanvas(width: 440, height: 500)
        .presentationBackground(.ultraThinMaterial)
    }

    private var activeTabs: [any BrowserTab] {
        controller.tabs.filter { $0.snapshot.spaceID == controller.session.selectedSpaceID }
    }

    private var activeGroups: [BrowserGroup] {
        controller.session.groups.filter { $0.spaceID == controller.session.selectedSpaceID }
    }

    private var groupList: some View {
        ScrollView {
            LazyVStack(spacing: 4) {
                ForEach(activeGroups) { group in
                    GroupManageRow(
                        group: group,
                        onRename: { renameID = group.id; groupName = group.name },
                        onDelete: { perform(.deleteGroup(id: group.id)) },
                        onClose: { controller.closeTabs(Set(group.tabIDs)) }
                    )
                }
                ForEach(activeTabs.filter { $0.snapshot.groupID == nil }, id: \.id) { tab in
                    GroupAssignRow(
                        title: tab.snapshot.displayTitle,
                        groups: activeGroups,
                        onAssign: { perform(.moveTabToGroup(tabID: tab.id, groupID: $0)) }
                    )
                }
            }
        }
        .scrollIndicators(.never)
    }

    @ViewBuilder
    private var suggestionList: some View {
        let suggestions = suggester.suggestions(
            for: activeTabs.map(\.snapshot),
            spaceID: controller.session.selectedSpaceID
        ).filter { !dismissedSuggestions.contains($0.id) }
        if !suggestions.isEmpty {
            Text("Suggested")
                .font(.system(size: 11, weight: .semibold))
                .foregroundStyle(Palette.chromeSecondaryText)
            ForEach(suggestions) { suggestion in
                GroupSuggestionRow(
                    suggestion: suggestion,
                    onGroup: { accept(suggestion) },
                    onDismiss: { dismissedSuggestions.insert(suggestion.id) }
                )
            }
        }
    }

    private func accept(_ suggestion: GroupingSuggestion) {
        guard let spaceID = controller.session.selectedSpaceID else { return }
        perform(.createGroupWithTabs(spaceID: spaceID, name: suggestion.name, tabIDs: suggestion.tabIDs))
    }

    private func saveName() {
        let name = groupName.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !name.isEmpty else { return }
        if let renameID { perform(.renameGroup(id: renameID, name: name)) }
        else if let spaceID = controller.session.selectedSpaceID {
            perform(.createGroup(spaceID: spaceID, name: name))
        }
        groupName = ""
        renameID = nil
    }

    private func perform(_ action: WorkspaceAction) {
        try? controller.perform(action)
    }
}
