# Passkeys

Thravik delegates website passkey registration and authentication to system
WebKit. It does not intercept `navigator.credentials`, handle challenges in
JavaScript, or store private keys in its password vault. macOS presents the
credential picker and verifies the person using the browser.

## Using saved passkeys

In a build with browser passkey approval, open Settings → Privacy → Passkeys
and click **Allow Passkeys**. Grant access in the macOS prompt, then reload the
website's sign-in page and choose its passkey option. This applies to Google
and other websites; the passkey must already be available to your Mac's
configured credential provider.

If you previously denied access, enable Thravik in System Settings → Privacy &
Security → Passkeys Access for Web Browsers, then return to Thravik. The status
refreshes when the app becomes active, and **Check Again** refreshes it manually.

An ordinary local or unprovisioned release build reports that saved passkeys
are unavailable. Google's “Something went wrong” message alone does not prove
the cause, but Thravik previously lacked the required browser entitlement.
A successful Google sign-in still needs manual verification with a provisioned
build and an account with a usable passkey.

## Building with browser passkey approval

Apple controls `com.apple.developer.web-browser.public-key-credential`. An
organization's Apple Developer Account Holder must request it through the
[macOS Browsers Passkeys form](https://developer.apple.com/contact/request/macos-browsers-passkeys/).
After approval, enable the managed capability on the explicit App ID
`app.redent.browser` and generate a macOS provisioning profile for the
certificate used to sign the app. Distribution needs a Developer ID profile
and matching Developer ID Application identity; local development uses a
development profile with its matching Apple Development identity.

```sh
PROVISIONING_PROFILE=/absolute/path/browser.provisionprofile \
CODESIGN_IDENTITY='Apple Development: Your Name (TEAMID)' \
REQUIRE_PASSKEYS=1 make app
```

The signing script decodes the profile, checks macOS support, expiry, explicit
app identity, team identity, and passkey approval, and merges the required
managed entitlements into the existing app entitlements. It embeds the profile
as `Contents/embedded.provisionprofile` and verifies the signed bundle. Profile
validation or signing failure stops the build; it cannot fall back to ad hoc
signing and claim passkey support. Rebuilding without a profile removes any
stale embedded profile and retains the ordinary app entitlements.

For GitHub releases, add `MACOS_BROWSER_PROFILE_BASE64` containing the base64
encoded approved Developer ID provisioning profile. The existing certificate
secret must contain a matching identity. When the profile secret is supplied,
the workflow requires passkey signing to succeed. Without it, releases continue
to build with saved passkeys unavailable. Profile and certificate files stay
outside version control.

## Validation

`make verify` covers permission-state mapping, permission requests, duplicate
requests from multiple windows, external permission changes, unentitled builds,
and signing regressions. Signing tests use synthetic decoded profiles and tool
stubs; they do not exercise Apple's provisioning service or real credentials.
If concurrent native-window tests hit animation timing failures, use
`make verify TEST_FLAGS=--no-parallel` to run the full suite serially.

For release acceptance, launch a provisioned build, grant permission, and test
Google sign-in with a saved passkey. Also test registration and authentication
on a WebAuthn test site, denial and re-enabling in System Settings, and a popup
sign-in. Use the existing container/private-tab settings to confirm browser
sessions remain isolated. Passkeys themselves are managed by macOS and are
available across browser containers once access is granted.

Apple references: [Passkey use in web browsers](https://developer.apple.com/documentation/authenticationservices/passkey-use-in-web-browsers),
[browser entitlement requirements](https://developer.apple.com/documentation/bundleresources/entitlements/com.apple.developer.web-browser.public-key-credential),
[authorization flow](https://developer.apple.com/documentation/authenticationservices/authenticating-people-by-using-passkeys-in-browser-apps).
