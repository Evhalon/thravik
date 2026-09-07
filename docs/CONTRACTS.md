# Cross-target API contracts

Every target below is built by a different agent, in parallel. These signatures
are **frozen**: implement them exactly, and assume the others exist exactly as
written. Do not rename, do not add required parameters, do not change
throwing-ness. Additive `public` API beyond this list is allowed.

`RedentKit` is already written — read it, do not modify it.

---

## RedentCrypto  (imports: Foundation, CryptoKit)

```swift
public enum HashAlgorithm: String, Sendable, Hashable { case sha1, sha256, sha512 }

public enum Base32Error: Error, Sendable, Equatable {
    case invalidCharacter(Character)
    case invalidLength
}

/// RFC 4648 base32. Decoding is case-insensitive, tolerates missing padding,
/// and ignores spaces and dashes (users paste seeds with both).
public enum Base32 {
    public static func decode(_ string: String) throws -> Data
    public static func encode(_ data: Data, padded: Bool = false) -> String
}

/// RFC 4226.
public enum HOTP {
    public static func generate(
        secret: Data, counter: UInt64, digits: Int, algorithm: HashAlgorithm
    ) -> String
}

public struct TOTPResult: Sendable, Hashable {
    public let digits: String
    public let windowStart: Date
    public let period: Int
}

/// RFC 6238.
public enum TOTP {
    public static func generate(
        secret: Data, at date: Date, period: Int, digits: Int, algorithm: HashAlgorithm
    ) -> TOTPResult
}
```

## RedentOTPAuth  (imports: Foundation, RedentKit, RedentCrypto)

```swift
public struct SystemTOTPGenerator: TOTPGenerating {
    public init()
    public func code(for account: TOTPAccount, at date: Date) throws -> TOTPCode
}

public struct OTPAuthImporter: OTPAuthImporting {
    public init()
    /// Accepts `otpauth://totp/…`, `otpauth://hotp/…` (rejected with
    /// `.counterBasedNotSupported`), and Google Authenticator's
    /// `otpauth-migration://offline?data=<base64>` export.
    public func accounts(fromScannedText text: String) throws -> [TOTPAccount]
}
```

## RedentVault  (imports: Foundation, Security, RedentKit)

```swift
public struct KeychainCredentialStore: CredentialStoring {
    public init(service: String = "app.redent.browser.credentials")
}

public struct KeychainTOTPStore: TOTPAccountStoring {
    public init(service: String = "app.redent.browser.totp")
}

public struct UserDefaultsSettingsStore: SettingsStoring {
    public init(defaults: UserDefaults = .standard)
}

public struct UserDefaultsSessionStore: SessionStoring {
    public init(defaults: UserDefaults = .standard)
}

public struct OSLogEventLogger: EventLogging {
    public init(subsystem: String = "app.redent.browser", category: String)
}
```

## RedentEngine  (imports: Foundation, SwiftUI, WebKit, RedentKit)

`RedentEngine` is the **only** target allowed to `import WebKit`. It therefore
also owns the SwiftUI bridge view, so that `RedentUI` never sees a WebKit type.

```swift
/// Emitted by injected page scripts. Carries no page content beyond what the
/// feature needs.
public enum PageSignal: Sendable, Equatable {
    case loginFormDetected(origin: Origin)
    case credentialSubmitted(CredentialCandidate)
    case otpFieldAppeared(origin: Origin, username: String)
    case otpFieldDisappeared
    case identityCaptured(username: String)
}

@MainActor
public protocol PageSignalHandling: AnyObject {
    func handle(_ signal: PageSignal, fromTab tabID: UUID)
}

@MainActor @Observable
public final class WebTab: Identifiable {
    public let id: UUID
    public private(set) var snapshot: TabSnapshot
    public private(set) var title: String
    public private(set) var url: URL?
    public private(set) var progress: Double        // 0…1
    public private(set) var isLoading: Bool
    public private(set) var canGoBack: Bool
    public private(set) var canGoForward: Bool
    public private(set) var isHibernated: Bool
    public private(set) var themeColor: Color?
    public var isPinned: Bool
    public var origin: Origin? { get }

    public func load(_ url: URL)
    public func goBack()
    public func goForward()
    public func reload()
    public func stopLoading()
    /// Fills the detected login form. Never submits it.
    public func fillCredential(username: String, password: String) async
    /// Fills the detected one-time-code field. Never submits.
    public func fillOTPCode(_ code: String) async
    /// Releases the web view, keeping `snapshot`. Idempotent.
    public func hibernate()
}

@MainActor @Observable
public final class TabController {
    public init(session: BrowserSession, settings: BrowserSettings, logger: any EventLogging)
    public private(set) var tabs: [WebTab]
    public var selectedID: UUID?
    public var selectedTab: WebTab? { get }
    public weak var signalHandler: (any PageSignalHandling)?
    /// Kept in sync by the app when settings change.
    public func apply(settings: BrowserSettings)

    @discardableResult public func newTab(url: URL?) -> WebTab
    public func close(_ id: UUID)
    public func closeOthers(than id: UUID)
    public func select(_ id: UUID)
    public func selectNext()
    public func selectPrevious()
    public func move(fromOffsets: IndexSet, toOffset: Int)
    public func togglePin(_ id: UUID)
    public func reopenLastClosed()
    public var session: BrowserSession { get }
    /// Hibernates tabs idle past the policy threshold. Called on a timer by the app.
    public func sweepHibernation(now: Date)
}

/// SwiftUI host for a tab's web view. Renders a placeholder when hibernated,
/// and wakes the tab on appear.
public struct WebContentView: View {
    public init(tab: WebTab)
}
```

## RedentDesign  (imports: SwiftUI)

```swift
public enum Metric {                       // spacing / radius / sizes
    public static let tabRowHeight: CGFloat
    public static let toolbarHeight: CGFloat
    public static let cornerRadius: CGFloat
    public static let smallRadius: CGFloat
    public static let gutter: CGFloat
    public static let tightGutter: CGFloat
}

public enum Palette {                      // semantic colors, light+dark aware
    public static var accent: Color
    public static var chromeText: Color
    public static var chromeSecondaryText: Color
    public static var hairline: Color
    public static var canvas: Color
    public static var danger: Color
}

public extension View {
    /// Liquid Glass panel with a hairline edge.
    func glassPanel(radius: CGFloat, tint: Color?) -> some View
    /// Floating, interactive glass capsule — used by the OTP pill.
    func glassCapsuleSurface(tint: Color?) -> some View
    /// Subtle hover/press affordance for chrome controls.
    func chromeHoverEffect(isActive: Bool, radius: CGFloat) -> some View
}

/// Circular progress ring, 1.0 → full. Used for the TOTP countdown.
public struct CountdownRing: View {
    public init(fraction: Double, lineWidth: CGFloat, tint: Color)
}

/// A square favicon with a graceful letter fallback.
public struct FaviconView: View {
    public init(data: Data?, host: String?, size: CGFloat)
}

/// Toolbar/sidebar icon button, glass-aware.
public struct ChromeButton: View {
    public init(systemImage: String, help: String, isEnabled: Bool, action: @escaping () -> Void)
}
```
