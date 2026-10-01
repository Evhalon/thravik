import AppKit
import RedentDesign
import RedentKit
import SwiftUI

/// One installed extension: what it is, whether it runs, and what to do with it.
struct ExtensionRow: View {
    let extensions: ExtensionsModel
    let item: InstalledExtension
    let onOpenOptions: () -> Void

    var body: some View {
        HStack(alignment: .top, spacing: Metric.tightGutter + 4) {
            icon
            details
            Spacer(minLength: Metric.gutter)
            if extensions.updatingID == item.id { ProgressView().controlSize(.small) }
            actionsMenu
            Toggle("", isOn: enabled)
                .toggleStyle(.switch)
                .labelsHidden()
                .controlSize(.small)
        }
        .padding(10)
        .background {
            RoundedRectangle(cornerRadius: Metric.mediumRadius, style: .continuous).fill(Palette.chromeFill)
        }
    }

    @ViewBuilder
    private var icon: some View {
        if let data = extensions.iconPNG(for: item.id), let image = NSImage(data: data) {
            Image(nsImage: image).resizable().frame(width: 28, height: 28)
        } else {
            Image(systemName: "puzzlepiece.extension.fill")
                .font(.system(size: 18))
                .foregroundStyle(Palette.accent)
                .frame(width: 28, height: 28)
        }
    }

    private var details: some View {
        VStack(alignment: .leading, spacing: 2) {
            Text(item.name)
                .font(.system(size: 13, weight: .medium))
                .foregroundStyle(Palette.chromeText)
            Text([item.version, item.origin.label].filter { !$0.isEmpty }.joined(separator: " · "))
                .font(.system(size: 11))
                .foregroundStyle(Palette.chromeSecondaryText)
            if !item.summary.isEmpty {
                Text(item.summary)
                    .font(.system(size: 11))
                    .foregroundStyle(Palette.chromeSecondaryText)
                    .lineLimit(2)
            }
            let unsupported = extensions.unsupportedFeatures(for: item.id)
            if !unsupported.isEmpty {
                Label(
                    "Needs Chrome-only features WebKit doesn't have: \(unsupported.joined(separator: ", ")). The parts that rely on them won't work.",
                    systemImage: "exclamationmark.triangle.fill"
                )
                .font(.system(size: 11))
                .foregroundStyle(.orange)
                .fixedSize(horizontal: false, vertical: true)
            }
            if item.isEnabled, let failure = extensions.loadFailure(for: item.id) {
                Text(failure)
                    .font(.system(size: 11))
                    .foregroundStyle(.red)
                    .fixedSize(horizontal: false, vertical: true)
            }
        }
    }

    private var actionsMenu: some View {
        Menu {
            if extensions.hasOptionsPage(item.id) {
                Button("Options") {
                    extensions.openOptions(for: item.id)
                    onOpenOptions()
                }
            }
            if case .chromeWebStore = item.origin {
                Button("Update from Chrome Web Store") { Task { await extensions.update(item.id) } }
            }
            Divider()
            Button("Remove", role: .destructive) { extensions.remove(item.id) }
        } label: {
            Image(systemName: "ellipsis.circle")
        }
        .menuStyle(.borderlessButton)
        .menuIndicator(.hidden)
        .fixedSize()
        .help("More")
    }

    private var enabled: Binding<Bool> {
        Binding(get: { item.isEnabled }, set: { extensions.setEnabled($0, for: item.id) })
    }
}
