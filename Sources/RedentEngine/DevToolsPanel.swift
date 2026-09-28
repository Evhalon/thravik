import AppKit
import Observation
import WebKit

/// Chrome's DevTools, docked under one tab's page.
///
/// The frontend is Chromium's own, served from the app bundle. Its protocol
/// messages go to the tab's WebKit inspector through `WebInspectorTap`, whose
/// bridge script translates between the two protocols. Nothing listens on a
/// port: the frontend and the page talk only through Redent.
@MainActor
@Observable
final class DevToolsPanel {
    @ObservationIgnored let frontend: WKWebView
    /// The part of the tab DevTools leaves to the page; nil until it says.
    private(set) var pageBounds: CGRect?
    /// The scale device mode draws the emulated screen at; nil outside it.
    @ObservationIgnored private(set) var deviceScale: Double?
    /// Called when the panel gives up — the tap failed — or DevTools asks to close.
    @ObservationIgnored var onClose: (() -> Void)?
    /// A link DevTools wants opened, such as a request's URL.
    @ObservationIgnored var onOpenURL: ((URL) -> Void)?
    @ObservationIgnored var onDeviceScaleChange: (() -> Void)?

    @ObservationIgnored private let tap: WebInspectorTap
    @ObservationIgnored private let host = DevToolsHostChannel()
    @ObservationIgnored private var waiting: [String] = []
    @ObservationIgnored private var isReady = false
    @ObservationIgnored private var isClosed = false

    init?(inspecting webView: WKWebView) {
        let scheme = DevToolsFrontendScheme()
        guard scheme.isAvailable, let hostScript = DevToolsHostChannel.script else { return nil }
        let configuration = WKWebViewConfiguration()
        configuration.setURLSchemeHandler(scheme, forURLScheme: DevToolsFrontendScheme.scheme)
        // DevTools keeps its own settings; they never mix with a site's storage.
        configuration.websiteDataStore = WKWebsiteDataStore(forIdentifier: Self.storeID)
        configuration.userContentController.addUserScript(
            WKUserScript(source: hostScript, injectionTime: .atDocumentStart, forMainFrameOnly: true)
        )
        configuration.userContentController.add(host, name: DevToolsHostChannel.handlerName)
        frontend = WKWebView(frame: .zero, configuration: configuration)
        tap = WebInspectorTap(webView: webView)
    }

    func open() {
        host.onProtocolMessage = { [weak self] in self?.toBackend($0) }
        host.onClose = { [weak self] in self?.close() }
        host.onOpenURL = { [weak self] in self?.onOpenURL?($0) }
        host.onPageBounds = { [weak self] in self?.pageBounds = $0 }
        host.onDeviceScale = { [weak self] in
            self?.deviceScale = $0
            self?.onDeviceScaleChange?()
        }
        tap.onMessage = { [weak self] in self?.toFrontend($0) }
        if let entry = DevToolsFrontendScheme.entry { frontend.load(URLRequest(url: entry)) }
        Task { [weak self] in await self?.attach() }
    }

    func close() {
        guard !isClosed else { return }
        isClosed = true
        tap.detach()
        frontend.configuration.userContentController.removeScriptMessageHandler(forName: DevToolsHostChannel.handlerName)
        frontend.stopLoading()
        onClose?()
    }

    private func attach() async {
        do {
            try await tap.attach()
        } catch {
            return close()
        }
        guard !isClosed else { return tap.detach() }
        isReady = true
        waiting.forEach(tap.send)
        waiting.removeAll()
    }

    private func toBackend(_ message: String) {
        if isReady { tap.send(message) } else { waiting.append(message) }
    }

    private func toFrontend(_ message: String) {
        frontend.callAsyncJavaScript(
            "InspectorFrontendAPI.dispatchMessage(message)", arguments: ["message": message], in: nil, in: .page
        )
    }

    private static let storeID = UUID(uuidString: "6C1B3A52-0B0E-4E57-9E0D-DE7700151A00") ?? UUID()
}
