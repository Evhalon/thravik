import RedentKit
import SwiftUI

struct RecentlyClosedMenuItems: View {
    let entries: [RecentlyClosedEntry]
    let reopen: (UUID) -> Void

    var body: some View {
        if entries.isEmpty {
            Button("Recently Closed") {}.disabled(true)
        } else {
            Menu("Recently Closed") {
                ForEach(entries) { entry in
                    Button(Self.title(entry)) { reopen(entry.id) }
                }
            }
        }
    }

    /// One string, because an NSMenu item draws a single title: stacked
    /// SwiftUI views collapse into joined text.
    nonisolated static func title(_ entry: RecentlyClosedEntry) -> String {
        switch entry.kind {
        case .group(let count):
            return "\(entry.title) — \(count) tabs"
        case .tab:
            guard let host = entry.host, !host.isEmpty, host != entry.title else { return entry.title }
            return "\(entry.title) — \(host)"
        }
    }
}
