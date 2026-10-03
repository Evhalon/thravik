import RedentKit

extension TabController {
    func applySensitiveSitePolicy(to tabs: [WebTab]) {
        let policy = SensitiveSitePolicy(settings: settings)
        for tab in tabs { tab.timelineRecorder.apply(policy: policy) }
    }
}
