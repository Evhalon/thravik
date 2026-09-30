import Foundation

/// A torn-off tab's window frame, in screen points. Its own type because a
/// window's spec must be `Hashable`, and `CGRect` is not.
struct TornOffFrame: Hashable, Codable {
    let x: Double
    let y: Double
    let width: Double
    let height: Double

    init(_ rect: CGRect) {
        x = rect.origin.x
        y = rect.origin.y
        width = rect.width
        height = rect.height
    }

    var rect: CGRect { CGRect(x: x, y: y, width: width, height: height) }
}
