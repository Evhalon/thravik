import RedentDesign
import RedentKit
import SwiftUI

public struct OnboardingView: View {
    @Bindable private var model: OnboardingModel
    private let browser: BrowserModel
    private let services: OnboardingServices
    @Environment(\.accessibilityReduceMotion) private var reduceMotion
    @Environment(\.scenePhase) private var scenePhase

    public init(model: OnboardingModel, browser: BrowserModel, services: OnboardingServices) {
        self.model = model
        self.browser = browser
        self.services = services
    }

    public var body: some View {
        GeometryReader { geometry in
            ZStack {
                if model.step == .welcome {
                    OnboardingIntroView(model: model)
                } else {
                    OnboardingBackdrop()
                    ScrollView {
                        card(wide: geometry.size.width >= 960)
                            .frame(minHeight: max(0, geometry.size.height - 64))
                            .padding(32)
                    }
                    .scrollIndicators(.hidden)
                }
            }
        }
        .foregroundStyle(Palette.chromeText)
        .preferredColorScheme(.dark)
        .tint(Color(red: 1, green: 0.23, blue: 0.07))
        .animation(reduceMotion ? nil : .spring(duration: 0.65, bounce: 0.12), value: model.step)
        .onAppear {
            if scenePhase == .active { model.startSound() }
        }
        .onDisappear { model.stopSound() }
        .onChange(of: scenePhase) { _, phase in
            if phase == .active { model.startSound() } else { model.stopSound() }
        }
        .onChange(of: services.workspace.syncedProfile, initial: true) { _, profile in
            model.restoreSyncedProfile(profile)
        }
    }

    private func card(wide: Bool) -> some View {
        VStack(spacing: 30) {
            OnboardingHeader(model: model)
            HStack(spacing: 36) {
                content.id(model.step)
                    .frame(maxWidth: .infinity)
                    .transition(reduceMotion ? .opacity : .opacity.combined(with: .offset(y: 18)))
                if wide { OnboardingPreview(step: model.step) }
            }
            .frame(minHeight: 440)
        }
        .padding(36)
        .frame(maxWidth: wide ? 980 : 560)
        .background(Color(red: 0.025, green: 0.025, blue: 0.03), in: .rect(cornerRadius: 28))
        .overlay { RoundedRectangle(cornerRadius: 28).strokeBorder(.white.opacity(0.1)) }
        .shadow(color: .black.opacity(0.22), radius: 32, y: 16)
        .frame(maxWidth: .infinity)
    }

    @ViewBuilder private var content: some View {
        switch model.step {
        case .welcome: EmptyView()
        case .profile: OnboardingProfilePage(model: model)
        case .space: space
        case .importData: OnboardingImportPage(model: model)
        case .account:
            if model.isDemo { OnboardingDemoAccountPage(model: model) }
            else { OnboardingAccountPage(onboarding: model, account: services.account) }
        case .sync:
            if model.isDemo { OnboardingDemoSyncPage(model: model) }
            else {
                OnboardingSyncPage(onboarding: model, passwords: services.passwords,
                                   workspace: services.workspace)
            }
        case .defaultBrowser:
            OnboardingDefaultBrowserPage(onboarding: model, defaultBrowser: services.defaultBrowser)
        }
    }

    private var space: some View {
        VStack(alignment: .leading, spacing: 16) {
            Text("A space for \(model.displayName).")
                .font(.system(size: 28, weight: .medium, design: .rounded))
            Text("Give your first Space a name, a color, a little personality.")
                .foregroundStyle(Palette.chromeSecondaryText)
            SpaceComposer(draft: initialDraft, onCancel: model.back, onCommit: commit,
                          onChange: { _ in }, commitTitle: "Create my Space")
                .frame(height: 500)
        }
    }

    private var initialDraft: SpaceDraft {
        if model.isDemo { return .new() }
        // Customize the starter Space rather than adding a duplicate after a restart.
        if let first = browser.tabs.session.spaces.first { return .editing(first) }
        return .new()
    }

    private func commit(_ draft: SpaceDraft) {
        guard !model.isDemo else { model.advance(); return }
        for action in draft.actions { browser.execute(action) }
        if let id = draft.original?.id { browser.execute(.focusSpace(id)) }
        var session = browser.durableSession()
        session.profile = model.profile
        browser.applySyncedWorkspace(session, remote: browser.remoteTabs)
        model.advance()
    }
}
