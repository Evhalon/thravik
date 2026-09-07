import RedentDesign
import RedentKit
import SwiftUI

/// Brings history, bookmarks and saved logins across from another browser.
public struct BrowserImportSheet: View {
    @State private var model: BrowserImportModel
    @Environment(\.dismiss) private var dismiss

    public init(model: BrowserImportModel) {
        _model = State(initialValue: model)
    }

    public var body: some View {
        VStack(alignment: .leading, spacing: 0) {
            header
                .padding(.bottom, Metric.gutter + 4)
            ScrollView {
                VStack(alignment: .leading, spacing: Metric.gutter + 4) {
                    if model.browsers.isEmpty {
                        noBrowsersFound
                    } else {
                        browserPicker
                        kindToggles
                    }
                    outcome
                }
                .frame(maxWidth: .infinity, alignment: .leading)
            }
            .frame(maxHeight: .infinity)
            footer
                .padding(.top, Metric.gutter)
        }
        .padding(22)
        .sheetCanvas(width: 520, height: 560)
        .onAppear(perform: model.discover)
    }

    private var header: some View {
        VStack(alignment: .leading, spacing: 3) {
            Text("Import from another browser")
                .font(.system(size: 16, weight: .semibold))
            Text("Nothing leaves your Mac. Everything is written straight into Redent's own storage.")
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
            Text("BROWSER").font(.system(size: 9.5, weight: .bold)).tracking(1)
                .foregroundStyle(Palette.chromeSecondaryText)
            ForEach(model.browsers) { browser in
                ImportBrowserRow(
                    browser: browser,
                    isSelected: browser.id == model.selectedID
                ) { model.selectedID = browser.id }
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

    @ViewBuilder
    private var outcome: some View {
        if let summary = model.summary {
            ImportSummaryBanner(summary: summary, problem: model.problem)
        } else if let problem = model.problem {
            Text(problem).font(.system(size: 11.5)).foregroundStyle(Palette.danger)
        }
    }

    private var footer: some View {
        HStack {
            if model.isRunning {
                ProgressView().controlSize(.small)
                Text("Importing…").font(.system(size: 11.5))
                    .foregroundStyle(Palette.chromeSecondaryText)
            }
            Spacer()
            Button(model.summary == nil ? "Cancel" : "Done") { dismiss() }
            Button("Import") { Task { await model.run() } }
                .buttonStyle(.borderedProminent)
                .disabled(!model.canRun)
        }
    }
}
