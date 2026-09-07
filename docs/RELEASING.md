# Releases

Every push to `main` runs the quality gates, creates a version from the workflow
run number, builds a DMG, and publishes `Redent-macOS.dmg` in a GitHub release.

The build uses an ad hoc signature with a stable designated requirement. It
does not need Apple certificates or GitHub secrets. The stable requirement lets
the file based Keychain recognize Redent across releases.

The DMG is not notarized. macOS can therefore block the first launch. Open the
app with the Finder context menu and choose Open to approve it.

The website uses GitHub's stable latest release URL. No page edit is needed when
a new build ships.
