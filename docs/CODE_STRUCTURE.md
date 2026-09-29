# Source organization

Swift targets enforce architecture boundaries. Inside each target, folders group
code by the feature that owns it. SwiftPM discovers Swift files recursively, so
moving a file does not change its module or public API.

```text
Sources/
  Redent/                concrete wiring and application lifecycle
    Application/         app and window ownership
    Features/            feature assembly and system integrations
  RedentKit/             Foundation-only domain values and ports
    Features/            FloatingVideo, Workspace, Tabs, History, …
    Shared/              web origins, gestures, page signals, logging
  RedentEngine/          WebKit implementations of domain ports
    Features/            FloatingVideo, Tabs, Downloads, Privacy, …
    Shared/              web rendering, script routing, resource access
    Resources/           isolated JavaScript and content rules
    DevToolsFrontend/    bundled third-party developer tools
  RedentUI/              views and models using domain ports
    Application/         browser model, shell, menu integration
    Features/            FloatingVideo, Commands, Search, Vault, …
    Shared/              sheet headings, controls, text and window helpers
  RedentVault/           persistent adapters
    Features/            credentials, authenticator, history, workspace, …
    Shared/              Keychain access, SQLite, logging
  RedentDesign/          reusable presentation primitives
    Components/          glass surfaces, buttons, badges, volume symbols
    Tokens/              metrics and palettes
    Color/               color analysis
```

The smaller targets already have one purpose: crypto, OTP parsing, browser
import, updates, and the app shim. They keep their compact module layout.

A feature keeps its own models, views and helpers together. Its domain port
lives in the corresponding `RedentKit/Features` folder; its platform adapter
lives in `RedentEngine` or `RedentVault`. `Redent` constructs implementations.
Folder names never authorize an outward dependency.

Extract a helper when real callers share the same behavior. Shared rendering
hosts, page-script infrastructure, Keychain access and SQLite helpers remain
single implementations. Speaker glyph selection is shared by tab audio,
toolbar volume and floating video. Floating video shares pure display selection
between release motion and resize; dragging and shrinking render one frame.

Tests mirror feature and shared folders inside their existing test targets.
Fixtures and SwiftPM resources stay at their declared resource paths.
`make verify` checks folder placement, file sizes, dependency imports, builds,
and tests. Add new Swift files to the owning feature rather than a flat model
or adapter folder. Split files by responsibility when they approach 150 lines.
