import Darwin

/// Turns off Keychain ACL dialogs for the duration of `body`.
///
/// `LAContext` and `u_AuthUI=fail` do not suppress file-based "Always Allow"
/// sheets. This is the switch that actually does — looked up by symbol so
/// the deprecated `SecKeychainSetUserInteractionAllowed` stays out of Swift.
enum KeychainInteraction {
    static func withDialogsDisabled<T>(_ body: () -> T) -> T {
        setAllowed(false)
        defer { setAllowed(true) }
        return body()
    }

    private static func setAllowed(_ allowed: Bool) {
        guard let handle = dlopen(
            "/System/Library/Frameworks/Security.framework/Security",
            RTLD_NOW
        ) else { return }
        defer { dlclose(handle) }
        typealias Fn = @convention(c) (UInt8) -> Int32
        guard let symbol = dlsym(handle, "SecKeychainSetUserInteractionAllowed") else { return }
        _ = unsafeBitCast(symbol, to: Fn.self)(allowed ? 1 : 0)
    }
}
