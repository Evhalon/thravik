import Foundation
import RedentEngine
import RedentKit
import RedentUI
import SwiftUI

/// Everything one window owns: its tabs, its chrome state, its autofill and
/// one-time-code coordinators.
///
/// Windows share the stores that hold the user's data — history, passwords,
/// bookmarks, settings, and the one browsing-context registry — and share
/// nothing else. Two windows therefore have independent tabs and Spaces while
/// still seeing the same cookies for the same Container.
@MainActor
final class WindowContainer {
    let spec: BrowserWindowSpec
    let model: BrowserModel
    let tabs: TabController

    init(spec: BrowserWindowSpec, app: AppContainer) {
        self.spec = spec
        let session = app.startingSession(for: spec)
        let settings = app.settingsStore.load()
        let controller = TabController(
            session: session,
            settings: settings,
            logger: app.logger,
            contexts: app.contexts,
            privateSessionID: spec.isPrivate ? UUID() : nil
        )
        self.tabs = controller

        let services = BrowserServices(
            history: app.history,
            bookmarks: app.bookmarks,
            settings: app.settingsStore,
            // A private or secondary window's workspace is deliberately not
            // durable: only the primary window writes the saved session.
            session: spec.isPrimary ? app.sessionStore : EphemeralSessionStore(),
            logger: app.logger,
            downloads: app.downloads
        )
        let features = BrowserFeatures(
            autofill: AutofillCoordinator(
                store: app.credentials, logger: app.logger, isEnabled: settings.offersPasswordSave
            ),
            otp: OTPCoordinator(store: app.authenticator, generator: app.generator, logger: app.logger),
            suggestions: AddressSuggestionsModel(
                engine: SuggestionEngine(history: app.history, bookmarks: app.bookmarks)
            )
        )
        self.model = BrowserModel(
            tabs: controller, services: services, features: features, settings: settings
        ) { id in
            AnyView(BrowserPageView(controller: controller, tabID: id))
        }

        controller.downloads = app.downloadCoordinator
        controller.permissionDecider = { [weak app] key, permission in
            app?.permissions.decision(key, permission) ?? .ask
        }
        if !spec.isPrivate {
            controller.invalidCertificateAllowed = { [weak app] key in
                app?.permissions.allowsInvalidCertificate(at: key) ?? false
            }
            controller.trustInvalidCertificate = { [weak app] key in
                app?.permissions.allowInvalidCertificate(at: key)
            }
        }
        if controller.tabs.isEmpty { controller.newTab(url: spec.startURL) }
        if let message = app.restoreFailureMessage(for: spec) { model.actionError = message }
        controller.warmUp()
    }

    /// The window is closing: flush what is durable, then let go of the
    /// ephemeral stores this window was the last owner of.
    func retire() {
        if spec.isPrimary { model.persistSession() }
        model.dismissPresentations()
        tabs.retire()
    }
}

/// Discards what it is given. A private window's workspace must not reach disk,
/// and a secondary window's would overwrite the primary's on the way out.
struct EphemeralSessionStore: SessionStoring {
    func load() -> BrowserSession { BrowserSession() }
    func save(_ session: BrowserSession) {}
}
