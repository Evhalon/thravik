import RedentKit
import SwiftUI

/// The Spaces menu: the first nine Spaces of the focused window, plus the two
/// screens that manage them.
struct BrowserSpaceCommands: Commands {
    let model: BrowserModel?

    var body: some Commands {
        CommandMenu("Spaces") {
            ForEach(Array(spaces.prefix(9).enumerated()), id: \.element.id) { index, space in
                Button(space.name) { model?.execute(.focusSpace(space.id)) }
                    .keyboardShortcut(
                        KeyEquivalent(Character(String(index + 1))),
                        modifiers: [.control, .option]
                    )
            }
            Divider()
            Button("Manage Spaces…") { model?.sheet = .spaces }
                .disabled(model == nil)
            Button("Tab Groups…") { model?.sheet = .groups }
                .keyboardShortcut("g", modifiers: [.control, .option])
                .disabled(model == nil)
        }
    }

    private var spaces: [BrowserSpace] { model?.tabs.session.spaces ?? [] }
}
