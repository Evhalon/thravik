import Foundation

public struct ManagedPolicySnapshot: Sendable, Equatable {
    public var settings: BrowserSettings
    public var locked: Set<ManagedPolicyLockKey>

    public init(settings: BrowserSettings, locked: Set<ManagedPolicyLockKey>) {
        self.settings = settings
        self.locked = locked
    }
}

public enum ManagedPolicyApplication {
    public static func apply(user: BrowserSettings, policy: ManagedPolicy) -> ManagedPolicySnapshot {
        guard policy.isActive else { return ManagedPolicySnapshot(settings: user, locked: []) }
        var settings = user
        var locked = Set<ManagedPolicyLockKey>()
        if let homepage = policy.homepageURL?.trimmingCharacters(in: .whitespacesAndNewlines), !homepage.isEmpty {
            settings.homepage = homepage
            locked.insert(.homepage)
        }
        if let engine = policy.defaultSearchEngine {
            applySearchEngine(engine, to: &settings)
            locked.insert(.searchEngine)
        }
        if policy.forceTrackerBlocking == true {
            settings.blocksTrackers = true
            locked.insert(.blocksTrackers)
        }
        if policy.disablePasswordSaving == true {
            settings.offersPasswordSave = false
            locked.insert(.offersPasswordSave)
        }
        return ManagedPolicySnapshot(settings: settings, locked: locked)
    }

    /// Starts from the effective settings and puts every locked field back to
    /// the user's own value, so a field added later is persisted by default.
    public static func storedUserSettings(
        effective: BrowserSettings,
        previousStored: BrowserSettings,
        policy: ManagedPolicy
    ) -> BrowserSettings {
        let locked = apply(user: previousStored, policy: policy).locked
        var stored = effective
        if locked.contains(.homepage) { stored.homepage = previousStored.homepage }
        if locked.contains(.searchEngine) {
            stored.searchEngine = previousStored.searchEngine
            stored.customSearchEngines = previousStored.customSearchEngines
            stored.activeCustomSearchEngineID = previousStored.activeCustomSearchEngineID
        }
        if locked.contains(.blocksTrackers) { stored.blocksTrackers = previousStored.blocksTrackers }
        if locked.contains(.offersPasswordSave) { stored.offersPasswordSave = previousStored.offersPasswordSave }
        return stored
    }

    /// Picking an engine normally drags the homepage along; a managed engine
    /// must not, or the unlocked homepage would persist the managed value.
    private static func applySearchEngine(_ engine: ManagedDefaultSearchEngine, to settings: inout BrowserSettings) {
        let homepage = settings.homepage
        switch engine {
        case .builtIn(let builtIn):
            settings.selectSearchEngine(builtIn)
        case .customTemplate(let template):
            applyManagedTemplate(template, to: &settings)
        }
        settings.homepage = homepage
    }

    private static func applyManagedTemplate(_ template: String, to settings: inout BrowserSettings) {
        if let existing = settings.customSearchEngines.first(where: { $0.template == template }) {
            settings.select(.custom(existing.id))
            return
        }
        let managed = CustomSearchEngine(name: "Managed Search", keyword: "managed", template: template)
        settings.addCustomSearchEngine(managed)
        settings.select(.custom(managed.id))
    }
}
