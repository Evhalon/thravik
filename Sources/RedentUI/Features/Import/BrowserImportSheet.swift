import RedentDesign
import RedentKit
import SwiftUI

public struct BrowserImportSheet: View {
    @State private var model: BrowserImportModel
    @State private var showsOptionsAfterImport = false
    @Environment(\.dismiss) private var dismiss
    public init(model: BrowserImportModel) {
        _model = State(initialValue: model)
    }

    public var body: some View {
        Group {
            if let summary = model.summary, !model.isRunning, !showsOptionsAfterImport {
                ImportSummaryBanner(summary: summary, problem: model.problem,
                                    onBack: { showsOptionsAfterImport = true }, onDone: { dismiss() })
            } else {
                importOptions
            }
        }
        .padding(22)
        .sheetCanvas(width: 520, height: 560)
        .onAppear(perform: model.discover)
        .onChange(of: model.isRunning) { _, running in
            if running { showsOptionsAfterImport = false }
        }
    }

    private var importOptions: some View {
        VStack(alignment: .leading, spacing: 0) {
            header.padding(.bottom, Metric.gutter + 4)
            ScrollView {
                VStack(alignment: .leading, spacing: Metric.gutter + 4) {
                    if model.browsers.isEmpty {
                        noBrowsersFound
                    } else {
                        browserPicker
                        destinationOptions
                        kindToggles
                    }
                }
                .frame(maxWidth: .infinity, alignment: .leading)
            }
            .frame(maxHeight: .infinity)
            .disabled(model.isRunning)
            footer.padding(.top, Metric.gutter)
        }
    }

    private var header: some View {
        VStack(alignment: .leading, spacing: 3) {
            Text("Import from another browser")
                .font(.system(size: 16, weight: .semibold))
            Text("All detected profiles are selected. Deselect any you do not want; nothing leaves your Mac.")
                .font(.system(size: 11.5))
                .foregroundStyle(Palette.chromeSecondaryText)
        }
    }

    private var noBrowsersFound: some View {
        Text("No Chromium-based browser profiles were found on this Mac.")
            .font(.system(size: 12))
            .foregroundStyle(Palette.chromeSecondaryText)
            .frame(maxWidth: .infinity, alignment: .leading)
    }

    private var browserPicker: some View {
        VStack(alignment: .leading, spacing: Metric.tightGutter) {
            pickerHeader
            ForEach(model.browsers) { browser in
                ImportBrowserRow(
                    browser: browser,
                    isSelected: model.selectedIDs.contains(browser.id)
                ) { model.toggle(browserID: browser.id) }
            }
        }
    }

    private var pickerHeader: some View {
        HStack(alignment: .firstTextBaseline) {
            Text("PROFILES").font(.system(size: 9.5, weight: .bold)).tracking(1)
                .foregroundStyle(Palette.chromeSecondaryText)
            Spacer(minLength: Metric.gutter)
            if model.browsers.count > 1 {
                Button(model.isEverythingSelected ? "Deselect all" : "Select all") {
                    if model.isEverythingSelected { model.deselectAll() } else { model.selectAll() }
                }
                .buttonStyle(.link)
                .font(.system(size: 11))
            }
        }
    }

    private var kindToggles: some View {
        VStack(alignment: .leading, spacing: Metric.tightGutter) {
            Text("WHAT TO BRING").font(.system(size: 9.5, weight: .bold)).tracking(1)
                .foregroundStyle(Palette.chromeSecondaryText)
            ForEach(ImportKind.allCases) { kind in
                Toggle(isOn: Binding(
                    get: { model.kinds.contains(kind) },
                    set: { _ in model.toggle(kind) }
                )) {
                    VStack(alignment: .leading, spacing: 1) {
                        Text(ImportCopy.title(for: kind)).font(.system(size: 12.5))
                        Text(ImportCopy.detail(for: kind))
                            .font(.system(size: 10.5))
                            .foregroundStyle(Palette.chromeSecondaryText)
                    }
                }
                .toggleStyle(.checkbox)
            }
        }
    }

    private var destinationOptions: some View {
        VStack(alignment: .leading, spacing: Metric.tightGutter) {
            Toggle("Create a Space for each selected profile", isOn: $model.createsSpacePerProfile)
                .toggleStyle(.checkbox)
            if !model.createsSpacePerProfile {
                ImportDestinationPicker(destination: $model.destination)
            } else {
                Text("Each imported profile gets its own Space. History and passwords stay shared.")
                    .font(.system(size: 10.5))
                    .foregroundStyle(Palette.chromeSecondaryText)
            }
        }
    }

    private var progressLabel: String {
        guard let name = model.runningBrowserName else { return "Importing…" }
        return "Importing \(name)…"
    }

    private var footer: some View {
        HStack {
            if model.isRunning {
                ProgressView().controlSize(.small)
                Text(progressLabel).font(.system(size: 11.5))
                    .foregroundStyle(Palette.chromeSecondaryText)
                    .lineLimit(1)
            }
            Spacer()
            Button(model.summary == nil ? "Cancel" : "Done") { dismiss() }
            Button("Import") { Task { await model.run() } }
                .buttonStyle(.borderedProminent)
                .disabled(!model.canRun)
        }
    }
}
