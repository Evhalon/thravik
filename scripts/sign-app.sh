#!/bin/sh
# Sign the Thravik app with a stable designated requirement. Development uses
# ad-hoc signing deliberately: looking up a local private key makes every build
# unlock the login Keychain, while the explicit requirement stays unchanged.
set -e
APP_DIR="$1"
BUNDLE_ID="$2"
ENTITLEMENTS="$3"

adhoc_sign() {
	req="=designated => identifier \"$BUNDLE_ID\""
	codesign --force --sign - \
		--identifier "$BUNDLE_ID" \
		--requirements "$req" \
		--entitlements "$ENTITLEMENTS" \
		--options runtime \
		"$APP_DIR" \
	|| codesign --force --sign - \
		--identifier "$BUNDLE_ID" \
		--requirements "$req" \
		"$APP_DIR"
}

identity="${CODESIGN_IDENTITY:--}"
if [ "$identity" = "-" ]; then
	echo "signing ad hoc with stable requirement"
	adhoc_sign
	exit 0
fi

echo "signing with $identity"
timestamp=""
if [ "${REQUIRE_SIGNING:-0}" = "1" ]; then
	timestamp="--timestamp"
fi
if codesign --force --sign "$identity" $timestamp \
	--identifier "$BUNDLE_ID" \
	--entitlements "$ENTITLEMENTS" \
	--options runtime \
	"$APP_DIR"
then
	exit 0
fi

if [ "${REQUIRE_SIGNING:-0}" = "1" ]; then
	echo "error: release signing failed"
	exit 1
fi

echo "warning: $identity failed; falling back to ad-hoc"
adhoc_sign
