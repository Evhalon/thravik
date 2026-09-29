# Releases

Every push to `main` creates a version from the workflow run number, builds a
signed DMG, notarizes and staples it, and publishes `Thravik-macOS.dmg` in a
GitHub release. Run `make verify` before shipping changes.

The workflow imports a Developer ID Application certificate from
`MACOS_CERT_P12_BASE64` and `MACOS_CERT_PASSWORD`. It requires signing to succeed.
Notarization uses `NOTARY_KEY_P8_BASE64`, `NOTARY_KEY_ID`, and `NOTARY_ISSUER_ID`.

Local builds can still use an Apple Development identity or an ad hoc signature;
they are not notarized.

The website uses GitHub's stable latest release URL. No page edit is needed when
a new build ships.

Saved passkeys additionally require Apple's managed browser capability and a
matching provisioning profile. The release workflow accepts the optional
`MACOS_BROWSER_PROFILE_BASE64` secret; see [passkey setup](PASSKEYS.md) for the
approval and signing requirements. A release without that profile cannot use
saved passkeys, and Settings reports this explicitly.
