import RedentDesign
import RedentKit
import SwiftUI
import UniformTypeIdentifiers

/// The ways in: a Chrome Web Store link, an unpacked folder, or a package file.
struct ExtensionAddSection: View {
    @Bindable var extensions: ExtensionsModel
    let onOpenStore: () -> Void
    /// One file importer for both buttons: a second on the same view never opens.
    @State private var isImporting = false
    @State private var importKind = ImportKind.package

    private enum ImportKind {
        case folder, package

        var types: [UTType] {
            switch self {
            case .folder: [.folder]
            case .package: [.zip] + [UTType(filenameExtension: "crx")].compactMap { $0 }
            }
        }
    }

    var body: some View {
        SettingsSection("ADD EXTENSIONS") {
            Text("Thravik runs Chrome extensions through WebKit's extension engine. Most work as they do in Chrome; ones built on Chrome-only APIs may not.")
                .font(.system(size: 11))
                .foregroundStyle(Palette.chromeSecondaryText)
                .fixedSize(horizontal: false, vertical: true)
            storeField
            SettingsLinkRow("Browse the Chrome Web Store", systemImage: "bag", action: onOpenStore)
            HStack(spacing: Metric.tightGutter) {
                Button("Load Unpacked Folder…") { startImport(.folder) }
                Button("Install from .crx or .zip…") { startImport(.package) }
            }
            .controlSize(.small)
            .disabled(extensions.isWorking)
        }
        .fileImporter(
            isPresented: $isImporting, allowedContentTypes: importKind.types
        ) { result in
            guard case .success(let url) = result else { return }
            add(importKind == .folder ? .folder(url) : .archive(url), url: url)
        }
    }

    private var storeField: some View {
        HStack(spacing: Metric.tightGutter) {
            TextField("Chrome Web Store link or extension ID", text: $extensions.storeLinkText)
                .textFieldStyle(.roundedBorder)
                .onSubmit(addFromStore)
            if extensions.isWorking {
                ProgressView().controlSize(.small)
            }
            Button("Add", action: addFromStore)
                .disabled(extensions.storeLinkText.isEmpty || extensions.isWorking)
        }
    }

    private func startImport(_ kind: ImportKind) {
        importKind = kind
        isImporting = true
    }

    private func addFromStore() {
        Task { await extensions.addFromStoreLink() }
    }

    private func add(_ source: ExtensionInstallSource, url: URL) {
        Task {
            let access = url.startAccessingSecurityScopedResource()
            defer { if access { url.stopAccessingSecurityScopedResource() } }
            await extensions.review(source)
        }
    }
}
