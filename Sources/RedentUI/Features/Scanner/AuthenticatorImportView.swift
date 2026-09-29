import RedentDesign
import RedentKit
import SwiftUI

/// Google Authenticator import: camera, image, or pasted payload. A valid QR
/// writes to the vault, tears down the camera, and shows the saved emails.
public struct AuthenticatorImportView: View {
    private enum Route: String, CaseIterable, Identifiable {
        case camera = "Camera", image = "Image", paste = "Paste"
        var id: String { rawValue }
    }

    @State private var model: AuthenticatorImportModel
    @State private var route: Route = .camera
    @Environment(\.dismiss) private var dismiss

    public init(importer: any OTPAuthImporting, store: any TOTPAccountStoring) {
        _model = State(initialValue: AuthenticatorImportModel(importer: importer, store: store))
    }

    public var body: some View {
        VStack(spacing: Metric.gutter) {
            titleBar
            content
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .padding(Metric.gutter * 2)
        .sheetCanvas(width: 520, height: 600)
        .task(id: model.collector.scannedPayloadCount) {
            await model.persistNewAccounts()
        }
        .onDisappear { model.collector.reset() }
        .animation(.spring(duration: 0.4), value: model.isScanning)
    }

    private var titleBar: some View {
        HStack {
            Text("Import from Google Authenticator").font(.title3.bold())
            Spacer()
            Button("Done") { dismiss() }.buttonStyle(.plain)
        }
    }

    @ViewBuilder
    private var content: some View {
        if let outcome = model.outcome {
            AuthenticatorImportSuccessView(outcome: outcome, onAddAnother: model.scanAgain)
                .transition(.opacity.combined(with: .scale(scale: 0.98)))
        } else {
            scanningContent
                .transition(.opacity)
        }
    }

    private var scanningContent: some View {
        VStack(spacing: Metric.gutter) {
            Picker("", selection: $route) {
                ForEach(Route.allCases) { Text($0.rawValue).tag($0) }
            }
            .pickerStyle(.segmented)
            .labelsHidden()
            routeContent
                .frame(maxHeight: .infinity)
            statusBar
        }
        .frame(maxHeight: .infinity)
    }

    @ViewBuilder
    private var routeContent: some View {
        switch route {
        case .camera: CameraScanRouteView(collector: model.collector)
        case .image: ImageImportView(collector: model.collector)
        case .paste: PasteImportView(collector: model.collector)
        }
    }

    private var statusBar: some View {
        Text(model.errorMessage ?? "Point the camera at a valid export QR. Accounts save as soon as the code reads.")
            .font(.subheadline)
            .foregroundStyle(Palette.chromeSecondaryText)
            .frame(maxWidth: .infinity, alignment: .leading)
    }
}
