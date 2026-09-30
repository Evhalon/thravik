import Foundation
import RedentKit

/// Translates a list drag into the Space's final position.
///
/// SwiftUI reports the destination as an offset in the list *before* the
/// row is lifted out; the workspace wants where it lands afterwards.
enum SpaceReorder {
    static func action(spaces: [BrowserSpace], from source: IndexSet, to destination: Int) -> BrowserAction? {
        guard source.count == 1, let origin = source.first, spaces.indices.contains(origin) else { return nil }
        let landing = destination > origin ? destination - 1 : destination
        guard landing != origin else { return nil }
        return .moveSpace(id: spaces[origin].id, toIndex: landing)
    }
}
