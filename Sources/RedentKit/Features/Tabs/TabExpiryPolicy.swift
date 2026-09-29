import Foundation

/// Decides what happens to temporary tabs whose deadline has passed.
///
/// A background tab closes on its own — nobody is looking at it, and leaving it
/// open defeats the point. The tab the user is actually reading is never closed
/// out from under them: it is offered, and they choose.
public struct TabExpiryPolicy: Sendable {
    public struct Decision: Equatable, Sendable {
        public var closing: [UUID]
        public var prompting: UUID?

        public var isEmpty: Bool { closing.isEmpty && prompting == nil }

        public init(closing: [UUID] = [], prompting: UUID? = nil) {
            self.closing = closing
            self.prompting = prompting
        }
    }

    public init() {}

    public func decide(tabs: [TabSnapshot], selectedID: UUID?, now: Date) -> Decision {
        var decision = Decision()
        for tab in tabs {
            guard let deadline = tab.lifespan.expiresAt, deadline <= now else { continue }
            if tab.id == selectedID {
                decision.prompting = tab.id
            } else {
                decision.closing.append(tab.id)
            }
        }
        return decision
    }
}
