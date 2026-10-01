import RedentDesign
import RedentKit
import SwiftUI

/// Settings → Extensions: add Chrome extensions and manage the installed ones.
///
/// Each alert sits on its own view: macOS SwiftUI presents only one of
/// several alerts attached to the same view.
struct ExtensionsSettingsPane: View {
    @Bindable var extensions: ExtensionsModel
    let onOpenStore: () -> Void
    let onOpenOptions: () -> Void

    var body: some View {
        VStack(alignment: .leading, spacing: 16) {
            ExtensionAddSection(extensions: extensions, onOpenStore: onOpenStore)
                .alert("Extension not added", isPresented: errorIsPresented) {
                    Button("OK", role: .cancel) {}
                } message: {
                    Text(extensions.errorMessage ?? "")
                }
            installedSection
                .alert(reviewTitle, isPresented: reviewIsPresented, presenting: extensions.pending) { _ in
                    Button("Add Extension") { extensions.confirmPending() }
                    Button("Cancel", role: .cancel) { extensions.cancelPending() }
                } message: { pending in
                    Text(Self.reviewMessage(for: pending))
                }
        }
    }

    private var installedSection: some View {
        SettingsSection("INSTALLED") {
            if extensions.installed.isEmpty {
                Text("No extensions yet. Extensions you add appear here and in the toolbar.")
                    .font(.system(size: 12))
                    .foregroundStyle(Palette.chromeSecondaryText)
            }
            ForEach(extensions.installed) { item in
                ExtensionRow(extensions: extensions, item: item, onOpenOptions: onOpenOptions)
            }
        }
        .frame(maxWidth: .infinity, alignment: .leading)
    }

    private var reviewTitle: String {
        extensions.pending.map { "Add “\($0.manifest.name)”?" } ?? ""
    }

    private var reviewIsPresented: Binding<Bool> {
        Binding(get: { extensions.pending != nil }, set: { if !$0 { extensions.cancelPending() } })
    }

    private var errorIsPresented: Binding<Bool> {
        Binding(get: { extensions.errorMessage != nil }, set: { if !$0 { extensions.errorMessage = nil } })
    }

    static func reviewMessage(for pending: PendingExtension) -> String {
        let access = pending.manifest.permissions.isEmpty
            ? "It asks for no special access."
            : "It can:\n" + pending.manifest.permissions.map { "• \($0)" }.joined(separator: "\n")
        let version = pending.manifest.version.isEmpty ? "" : "Version \(pending.manifest.version) · "
        let unsupported = pending.manifest.unsupportedFeatures
        let warning = unsupported.isEmpty ? "" : "\n\n⚠️ It relies on Chrome-only features WebKit doesn't have: "
            + unsupported.joined(separator: ", ") + ". Those parts won't work in Thravik."
        return "\(version)\(pending.origin.label)\n\n\(access)\(warning)"
    }
}
