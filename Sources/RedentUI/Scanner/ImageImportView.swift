import AppKit
import RedentDesign
import SwiftUI
import UniformTypeIdentifiers

/// The image route: drag-and-drop, paste, or pick a screenshot of the export
/// QR — the path most people actually use, since Google Authenticator's
/// export screen is usually viewed on a second phone.
struct ImageImportView: View {
    let collector: ScannedPayloadCollector

    @State private var isTargeted = false
    @State private var isPickingFile = false
    @State private var statusMessage: String?

    var body: some View {
        VStack(spacing: Metric.gutter) {
            dropZone
            HStack(spacing: Metric.gutter) {
                Button("Choose Image…") { isPickingFile = true }
                Button("Paste from Clipboard", action: pasteFromClipboard)
            }
            if let statusMessage {
                Text(statusMessage).font(.caption).foregroundStyle(Palette.chromeSecondaryText)
            }
        }
        .fileImporter(isPresented: $isPickingFile, allowedContentTypes: [.image], onCompletion: handleFileImport)
        .onPasteCommand(of: [.image]) { providers in _ = handleProviders(providers) }
    }

    private var dropZone: some View {
        RoundedRectangle(cornerRadius: Metric.cornerRadius, style: .continuous)
            .strokeBorder(isTargeted ? Palette.accent : Palette.hairline, style: dashStyle)
            .overlay(dropZoneLabel)
            .frame(maxWidth: .infinity, minHeight: 220)
            .onDrop(of: [.image], isTargeted: $isTargeted, perform: handleProviders)
    }

    private var dashStyle: StrokeStyle { StrokeStyle(lineWidth: 1.5, dash: [6, 4]) }

    private var dropZoneLabel: some View {
        VStack(spacing: Metric.tightGutter) {
            Image(systemName: "qrcode.viewfinder")
                .font(.system(size: 28))
                .foregroundStyle(Palette.chromeSecondaryText)
            Text("Drop a screenshot of the export QR here")
                .font(.subheadline)
                .foregroundStyle(Palette.chromeSecondaryText)
        }
    }

    private func handleFileImport(_ result: Result<URL, Error>) {
        guard case .success(let url) = result else { return }
        Task { await importImage(fromFileAt: url) }
    }

    private func pasteFromClipboard() {
        let objects = NSPasteboard.general.readObjects(forClasses: [NSItemProvider.self])
        _ = handleProviders((objects as? [NSItemProvider]) ?? [])
    }

    @discardableResult
    private func handleProviders(_ providers: [NSItemProvider]) -> Bool {
        guard let provider = providers.first(where: { $0.hasItemConformingToTypeIdentifier(UTType.image.identifier) })
        else { return false }
        provider.loadDataRepresentation(forTypeIdentifier: UTType.image.identifier) { data, _ in
            guard let data else { return }
            Task { await self.importImage(data: data) }
        }
        return true
    }

    private func importImage(fromFileAt url: URL) async {
        guard let data = try? Data(contentsOf: url) else {
            statusMessage = "Couldn't read that file."
            return
        }
        await importImage(data: data)
    }

    @MainActor
    private func importImage(data: Data) async {
        do {
            let payloads = try await QRImageDecoder.payloads(inImageData: data)
            guard !payloads.isEmpty else {
                statusMessage = "No QR code found in that image."
                return
            }
            for payload in payloads { await collector.add(payloadText: payload) }
            statusMessage = "Found \(payloads.count) QR code\(payloads.count == 1 ? "" : "s")."
        } catch {
            statusMessage = "Couldn't read that image."
        }
    }
}
