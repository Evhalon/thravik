import Foundation

public protocol ManagedPolicyProviding: Sendable {
    func current() -> ManagedPolicy
}
