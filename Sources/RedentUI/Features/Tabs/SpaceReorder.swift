import CoreGraphics
import Foundation
import RedentKit

/// Turns a vertical drag in the Space manager into the Space's final position.
///
/// Rows share one pitch, so the landing slot is how many rows the pointer has
/// travelled past, and every row between origin and landing slides one pitch
/// toward the gap the lifted row left behind.
enum SpaceReorder {
    static func landing(origin: Int, travel: CGFloat, pitch: CGFloat, count: Int) -> Int {
        guard pitch > 0, count > 0 else { return origin }
        let rows = Int((travel / pitch).rounded())
        return min(max(origin + rows, 0), count - 1)
    }

    static func shift(for index: Int, origin: Int, landing: Int, pitch: CGFloat) -> CGFloat {
        if origin < landing, index > origin, index <= landing { return -pitch }
        if landing < origin, index >= landing, index < origin { return pitch }
        return 0
    }

    static func action(spaces: [BrowserSpace], origin: Int, landing: Int) -> BrowserAction? {
        guard spaces.indices.contains(origin), landing != origin else { return nil }
        return .moveSpace(id: spaces[origin].id, toIndex: landing)
    }
}
