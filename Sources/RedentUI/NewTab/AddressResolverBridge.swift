import Foundation
import RedentKit

/// Small seam so the new-tab search field resolves input exactly the way the
/// address bar does, without either view reaching into the other's model.
enum AddressResolverBridge {
    static func resolve(_ text: String, engine: SearchEngine) -> URL? {
        AddressResolver.resolve(text, using: engine)
    }
}
