#!/bin/sh
# CI only: load the Developer ID certificate into a throwaway keychain and
# export its identity name for sign-app.sh. The keychain lives in RUNNER_TEMP,
# so it disappears with the runner and never touches a developer machine.
set -eu
: "${MACOS_CERT_P12_BASE64:?missing}" "${MACOS_CERT_PASSWORD:?missing}" "${RUNNER_TEMP:?missing}"

keychain="$RUNNER_TEMP/signing.keychain-db"
certificate="$RUNNER_TEMP/developer-id.p12"
keychain_password="$(openssl rand -base64 24)"

printf %s "$MACOS_CERT_P12_BASE64" | base64 --decode > "$certificate"
security create-keychain -p "$keychain_password" "$keychain"
security set-keychain-settings -lut 21600 "$keychain"
security unlock-keychain -p "$keychain_password" "$keychain"
security import "$certificate" -k "$keychain" -f pkcs12 \
	-P "$MACOS_CERT_PASSWORD" -T /usr/bin/codesign
rm -f "$certificate"
# Without a partition list, codesign blocks on a GUI prompt the runner cannot answer.
security set-key-partition-list -S apple-tool:,apple:,codesign: \
	-s -k "$keychain_password" "$keychain" > /dev/null
security list-keychains -d user -s "$keychain" login.keychain-db

identity="$(security find-identity -v -p codesigning "$keychain" \
	| sed -n 's/.*"\(Developer ID Application: [^"]*\)".*/\1/p' | head -n 1)"
if [ -z "$identity" ]; then
	echo "error: the certificate holds no Developer ID Application identity" >&2
	exit 1
fi
echo "imported $identity"
echo "CODESIGN_IDENTITY=$identity" >> "$GITHUB_ENV"
