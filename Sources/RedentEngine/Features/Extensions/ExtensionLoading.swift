import Foundation
import RedentKit
import WebKit

/// Turning files on disk into a running extension, and back.
extension ExtensionHost {
    func load(_ record: InstalledExtension) async {
        guard contexts[record.id] == nil else { return }
        do {
            let webExtension = try await WKWebExtension(resourceBaseURL: files.installDirectory(record.id))
            let context = WKWebExtensionContext(for: webExtension)
            // Storage is keyed by this id, so it must not change across launches.
            context.uniqueIdentifier = record.id.uuidString
            if let base = URL(string: "webkit-extension://\(record.id.uuidString.lowercased())/") {
                context.baseURL = base
            }
            context.isInspectable = true
            Self.grantRequestedAccess(to: context)
            try controller.load(context)
            contexts[record.id] = context
            failures[record.id] = nil
        } catch {
            failures[record.id] = error.localizedDescription
        }
    }

    func unload(_ id: UUID) {
        guard let context = contexts.removeValue(forKey: id) else { return }
        try? controller.unload(context)
        changed()
    }

    /// The user approved this list when they installed the extension; asking
    /// again on every launch would teach them to click through prompts.
    static func grantRequestedAccess(to context: WKWebExtensionContext) {
        let webExtension = context.webExtension
        for permission in webExtension.requestedPermissions {
            context.setPermissionStatus(.grantedExplicitly, for: permission)
        }
        for pattern in webExtension.allRequestedMatchPatterns {
            context.setPermissionStatus(.grantedExplicitly, for: pattern)
        }
    }

    static func summary(of webExtension: WKWebExtension) -> ExtensionManifestSummary {
        ExtensionManifestSummary(
            name: webExtension.displayName ?? webExtension.displayShortName ?? "Extension",
            version: webExtension.displayVersion ?? webExtension.version ?? "",
            summary: webExtension.displayDescription ?? "",
            permissions: ExtensionPermissionWording.lines(
                permissions: Set(webExtension.requestedPermissions.map(\.rawValue)),
                hostPatterns: Set(webExtension.allRequestedMatchPatterns.map(\.string))
            ),
            unsupportedFeatures: ExtensionPermissionWording.featureNames(droppedPermissions(of: webExtension))
        )
    }

    /// WebKit quietly leaves out of `requestedPermissions` every API it does
    /// not implement, so what the manifest asked for minus what WebKit kept
    /// is exactly what will not work. Host patterns are kept elsewhere.
    static func droppedPermissions(of webExtension: WKWebExtension) -> [String] {
        let asked = webExtension.manifest["permissions"] as? [String] ?? []
        let kept = Set(webExtension.requestedPermissions.map(\.rawValue))
        return asked.filter { !kept.contains($0) && !$0.contains("://") && $0 != "<all_urls>" }
    }
}
