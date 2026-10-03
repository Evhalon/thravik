import Foundation
@testable import RedentUI

/// Time that only moves when the model sleeps, so coalescing never races a loaded machine.
@MainActor
final class ManualDownloadClock {
    private(set) var now: Date

    init(_ start: Date = Date()) {
        now = start
    }

    func advance(by duration: Duration) {
        let parts = duration.components
        now = now.addingTimeInterval(TimeInterval(parts.seconds) + TimeInterval(parts.attoseconds) / 1e18)
    }

    func makeModel() -> DownloadsModel {
        DownloadsModel(
            sessionStartedAt: now,
            now: { self.now },
            sleep: { await self.advance(by: $0) }
        )
    }
}
