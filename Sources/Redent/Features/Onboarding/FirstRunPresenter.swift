import RedentUI
import SwiftUI

struct FirstRunPresenter: ViewModifier {
    let app: AppContainer
    let window: WindowContainer
    let isPrimary: Bool

    func body(content: Content) -> some View {
        content
            .overlay {
                if isPrimary && !app.onboarding.model.isComplete {
                    OnboardingView(
                        model: app.onboarding.model,
                        browser: window.model,
                        services: OnboardingServices(
                            account: app.account.model, passwords: app.passwords.model,
                            workspace: app.workspace.model, defaultBrowser: app.defaultBrowser
                        )
                    )
                }
            }
            .task { await start() }
            .onChange(of: app.account.model.session?.accountID) {
                guard isPrimary else { return }
                app.workspace.note(window.model.durableSession())
            }
            .onChange(of: app.onboarding.model.isComplete) {
                guard isPrimary, app.onboarding.model.isComplete, !app.onboarding.model.lastCompletionWasDemo,
                      !app.onboarding.model.didFinishDefaultBrowserChoice else { return }
                Task { await app.offerDefaultBrowserIfNeeded(in: window) }
            }
    }

    private func start() async {
        if isPrimary {
            app.onboarding.model.onImportBrowser = { [weak model = window.model] in
                model?.sheet = .importBrowser
            }
        }
        await app.account.model.restore()
        if app.onboarding.model.isComplete, !app.onboarding.model.lastCompletionWasDemo,
           !app.onboarding.model.didFinishDefaultBrowserChoice {
            await app.offerDefaultBrowserIfNeeded(in: window)
        }
    }
}
