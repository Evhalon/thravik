import RedentEngine
import RedentKit
import RedentUI

/// Builds the per-site privacy screen for whatever a window is showing now.
/// Lives in the app target: only the composition root knows which concrete
/// registry and store back the ports the screen talks to.
extension AppContainer {
    func sitePrivacyModel(for window: WindowContainer) -> SitePrivacyModel? {
        let model = window.model
        guard let tab = model.selectedTab, let origin = tab.origin else { return nil }
        return SitePrivacyModel(configuration: .init(
            origin: origin,
            context: tab.snapshot.browsingContext,
            permissions: permissions,
            siteData: siteData,
            forgetting: ForgetSiteService(siteData: siteData, history: history, tabs: model.tabs)
        ))
    }
}
