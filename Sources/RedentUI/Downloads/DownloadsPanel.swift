import RedentDesign
import SwiftUI

/// The downloads screen: everything fetched this session, newest first.
public struct DownloadsPanel: View {
    @Bindable private var model: DownloadsModel
    @Environment(\.dismiss) private var dismiss

    public init(model: DownloadsModel) {
        self.model = model
    }

    public var body: some View {
        VStack(spacing: 0) {
            header.padding(Metric.gutter)
            Divider()
            content
        }
        .sheetCanvas(width: 560, height: 420)
        .onAppear(perform: model.markSeen)
    }

    private var header: some View {
        HStack(alignment: .top) {
            SheetHeading(title: "Downloads", subtitle: subtitle)
            Spacer()
            Button("Clear Finished", action: model.clearFinished)
                .disabled(model.items.allSatisfy(\.isActive))
            Button("Done") { dismiss() }
                .keyboardShortcut(.defaultAction)
        }
    }

    private var subtitle: String {
        let active = model.activeItems.count
        if active > 0 { return active == 1 ? "1 file downloading" : "\(active) files downloading" }
        return model.isEmpty ? "Files you download land in your Downloads folder." : "Nothing in flight."
    }

    @ViewBuilder
    private var content: some View {
        if model.isEmpty {
            VStack(spacing: Metric.tightGutter) {
                Image(systemName: "arrow.down.circle").font(.system(size: 26, weight: .light))
                Text("No downloads yet").font(.system(size: 12))
            }
            .foregroundStyle(Palette.chromeSecondaryText)
            .frame(maxWidth: .infinity, maxHeight: .infinity)
        } else {
            List(model.items) { item in
                DownloadRow(
                    item: item,
                    onCancel: { model.cancel(item.id) },
                    onReveal: { model.revealInFinder(item) },
                    onOpen: { model.openFile(item) },
                    onRemove: { model.remove(item.id) }
                )
            }
            .listStyle(.inset)
        }
    }
}
