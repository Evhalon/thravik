import AppKit

// The executable inside every web app the browser installs. It is the app the
// Dock, Spotlight and ⌘Tab see; the page itself runs in the browser, which
// keeps one engine, one set of logins and one memory budget for every app.
MainActor.assumeIsolated {
    let application = NSApplication.shared
    let delegate = LauncherDelegate()
    application.delegate = delegate
    application.mainMenu = LauncherDelegate.makeMenu()
    application.setActivationPolicy(.regular)
    withExtendedLifetime(delegate) { application.run() }
}
