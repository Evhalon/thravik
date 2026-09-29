import Foundation
import RedentKit

@MainActor
final class VisitRecorder {
    private let history: any HistoryStoring

    init(history: any HistoryStoring) { self.history = history }

    func record(_ snapshot: TabSnapshot, navigationID: UUID) {
        guard !snapshot.isTemporary, let url = snapshot.url else { return }
        let context = HistoryVisitContext(navigationID: navigationID, tabID: snapshot.id,
                                          spaceID: snapshot.spaceID, containerID: snapshot.containerID)
        let visit = HistoryVisit(url: url, title: snapshot.title, context: context)
        Task { [history] in await history.record(visit) }
    }
}
