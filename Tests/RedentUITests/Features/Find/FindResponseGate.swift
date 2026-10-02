import RedentKit

@MainActor
final class FindResponseGate {
    private var response: CheckedContinuation<FindMatches, Never>?
    private var observers: [CheckedContinuation<Void, Never>] = []

    func waitForResult() async -> FindMatches {
        await withCheckedContinuation {
            response = $0
            for observer in observers { observer.resume() }
            observers.removeAll()
        }
    }

    func waitUntilRequested() async {
        guard response == nil else { return }
        await withCheckedContinuation { observers.append($0) }
    }

    func reply(_ matches: FindMatches) {
        response?.resume(returning: matches)
        response = nil
    }
}
