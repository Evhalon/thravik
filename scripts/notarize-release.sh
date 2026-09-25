#!/bin/sh
# Sign, notarize and staple the release disk image so Gatekeeper opens it
# without a network round trip. On rejection, print Apple's log: it names the
# exact binary and reason, which the bare "Invalid" status never does.
set -eu
image_path="$1"
: "${CODESIGN_IDENTITY:?missing}" "${NOTARY_KEY_P8_BASE64:?missing}"
: "${NOTARY_KEY_ID:?missing}" "${NOTARY_ISSUER_ID:?missing}" "${RUNNER_TEMP:?missing}"

key_path="$RUNNER_TEMP/AuthKey_$NOTARY_KEY_ID.p8"
result_path="$RUNNER_TEMP/notary-result.json"
printf %s "$NOTARY_KEY_P8_BASE64" | base64 --decode > "$key_path"
trap 'rm -f "$key_path"' EXIT

codesign --force --sign "$CODESIGN_IDENTITY" --timestamp "$image_path"

xcrun notarytool submit "$image_path" \
	--key "$key_path" --key-id "$NOTARY_KEY_ID" --issuer "$NOTARY_ISSUER_ID" \
	--wait --timeout 30m --output-format json > "$result_path"

status="$(plutil -extract status raw -o - "$result_path")"
submission="$(plutil -extract id raw -o - "$result_path")"
echo "notarization $submission: $status"
if [ "$status" != "Accepted" ]; then
	xcrun notarytool log "$submission" \
		--key "$key_path" --key-id "$NOTARY_KEY_ID" --issuer "$NOTARY_ISSUER_ID"
	exit 1
fi

xcrun stapler staple "$image_path"
xcrun stapler validate "$image_path"
spctl --assess --type open --context context:primary-signature --verbose=2 "$image_path"
