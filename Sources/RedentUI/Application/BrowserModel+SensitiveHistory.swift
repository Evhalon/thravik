import Foundation
import RedentKit

extension BrowserModel {
    func sensitiveSitePolicy() -> SensitiveSitePolicy {
        SensitiveSitePolicy(settings: settings)
    }

    func retainsBrowsingTraces(for tab: any BrowserTab) -> Bool {
        guard !isPrivate, !tab.snapshot.isTemporary else { return false }
        guard let url = tab.snapshot.url ?? tab.origin.flatMap({ URL(string: "\($0.scheme)://\($0.host)/") })
        else { return true }
        return !sensitiveSitePolicy().excludes(url: url)
    }

    public func excludeSiteFromHistory(_ origin: Origin) {
        var updated = settings
        guard case .success = updated.addSensitiveHistoryDomain(origin.registrableDomain) else { return }
        settings = updated
    }

    /// Another window edited the list; without this its tabs would keep
    /// recording, and its next settings save would undo the edit.
    public func adoptSensitiveHistory(from source: BrowserSettings) {
        guard SensitiveSitePolicy(settings: source) != sensitiveSitePolicy() else { return }
        var updated = settings
        updated.excludeBankingAndHealthFromHistory = source.excludeBankingAndHealthFromHistory
        updated.sensitiveSiteHistoryDomains = source.sensitiveSiteHistoryDomains
        settings = updated
    }

    func sensitiveHistoryChanged(from old: BrowserSettings) {
        guard SensitiveSitePolicy(settings: old) != sensitiveSitePolicy() else { return }
        onSensitiveHistoryChanged?(settings)
    }
}
