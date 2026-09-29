import RedentDesign
import RedentKit
import SwiftUI

/// An ungrouped tab waiting to be assigned, plus a domain-cluster suggestion.
struct GroupAssignRow: View {
    let title: String
    let groups: [BrowserGroup]
    let onAssign: (UUID?) -> Void
    @State private var isHovering = false

    var body: some View {
        HStack(spacing: Metric.tightGutter + 4) {
            Text(title)
                .font(.system(size: 12.5))
                .foregroundStyle(Palette.chromeText)
                .lineLimit(1)
            Spacer(minLength: 0)
            Menu {
                ForEach(groups) { group in
                    Button(group.name) { onAssign(group.id) }
                }
                if !groups.isEmpty { Divider() }
                Button("Ungroup") { onAssign(nil) }
            } label: {
                Text("Move")
                    .font(.system(size: 11, weight: .medium))
                    .foregroundStyle(Palette.chromeSecondaryText)
            }
            .menuStyle(.borderlessButton)
            .menuIndicator(.hidden)
            .opacity(isHovering || groups.isEmpty ? 1 : 0.55)
        }
        .padding(.horizontal, 10)
        .frame(height: 32)
        .background {
            RoundedRectangle(cornerRadius: Metric.smallRadius, style: .continuous)
                .fill(Palette.chromeFill.opacity(isHovering ? 1 : 0))
        }
        .onHover { hovering in
            withAnimation(.easeOut(duration: 0.12)) { isHovering = hovering }
        }
    }
}
