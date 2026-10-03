import RedentKit
import SwiftUI

struct RemoteTabsPane: View {
    @Bindable var model: WorkspaceSyncModel

    var body: some View {
        if model.remoteTabs.isEmpty, model.message == nil {
            EmptyView()
        } else {
            VStack(alignment: .leading, spacing: 8) {
                Text("Tabs on other Macs")
                if let message = model.message { Text(message).foregroundStyle(.red) }
                ForEach(model.remoteTabs) { tab in
                    RemoteTabRow(tab: tab) { model.open(tab) }
                }
            }
        }
    }
}

private struct RemoteTabRow: View {
    let tab: RemoteSyncedTab
    let open: () -> Void

    var body: some View {
        HStack {
            VStack(alignment: .leading, spacing: 2) {
                Text(tab.title)
                Text(tab.url.flatMap(Origin.init(url:))?.displayHost ?? "").font(.caption).foregroundStyle(.secondary)
            }
            Spacer()
            Button("Open", action: open)
        }
    }
}
