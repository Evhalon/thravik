#!/bin/sh
# Sign the Thravik app. The legacy Keychain pins an ad-hoc app's ACL to its
# cdhash, which changes on every build, so each rebuild re-prompts for the
# vault and the authenticator. A certificate-backed signature keeps a stable
# designated requirement, so "Always Allow" is asked once and then sticks.
# Local builds pick the Apple Development identity when one is installed;
# CODESIGN_IDENTITY=- forces ad-hoc (CI does this).
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

local_identity() {
	security find-identity -v -p codesigning 2>/dev/null \
		| sed -n 's/.*"\(Apple Development: [^"]*\)".*/\1/p' | head -n 1
}

identity="${CODESIGN_IDENTITY:-$(local_identity)}"
identity="${identity:--}"
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
