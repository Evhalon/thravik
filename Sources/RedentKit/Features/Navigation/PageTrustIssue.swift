/// A trust problem that stopped a page before it could load.
///
/// This is deliberately small and platform-neutral: the engine translates
/// WebKit's transport error without leaking its error objects into the UI.
public enum PageTrustIssue: Sendable, Equatable {
    case invalidCertificate
}
