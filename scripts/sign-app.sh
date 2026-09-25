#!/bin/sh
# Sign the Thravik app. The legacy Keychain pins an ad-hoc app's ACL to its
# cdhash, which changes on every build, so each rebuild re-prompts for the
# vault and the authenticator. A certificate-backed signature keeps a stable
# designated requirement, so "Always Allow" is asked once and then sticks.
# Local builds pick the Apple Development identity when one is installed;
# CODESIGN_IDENTITY=- forces ad-hoc. Release builds set REQUIRE_SIGNING=1 with
# a Developer ID identity, and notarization rejects any nested binary that is
# not signed by that same identity — so helpers are signed before the app.
set -e
APP_DIR="$1"
BUNDLE_ID="$2"
ENTITLEMENTS="$3"
HELPERS_DIR="$APP_DIR/Contents/Helpers"

adhoc_sign() {
	for helper in "$HELPERS_DIR"/*; do
		[ -f "$helper" ] && codesign --force --sign - "$helper"
	done
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

identity_sign() {
	for helper in "$HELPERS_DIR"/*; do
		[ -f "$helper" ] || continue
		codesign --force --sign "$identity" $timestamp --options runtime "$helper" || return 1
	done
	codesign --force --sign "$identity" $timestamp \
		--identifier "$BUNDLE_ID" \
		--entitlements "$ENTITLEMENTS" \
		--options runtime \
		"$APP_DIR"
}

local_identity() {
	security find-identity -v -p codesigning 2>/dev/null \
		| sed -n 's/.*"\(Apple Development: [^"]*\)".*/\1/p' | head -n 1
}

identity="${CODESIGN_IDENTITY:-$(local_identity)}"
identity="${identity:--}"
if [ "$identity" = "-" ]; then
	if [ "${REQUIRE_SIGNING:-0}" = "1" ]; then
		echo "error: REQUIRE_SIGNING=1 but no signing identity is available"
		exit 1
	fi
	echo "signing ad hoc with stable requirement"
	adhoc_sign
	exit 0
fi

echo "signing with $identity"
timestamp=""
if [ "${REQUIRE_SIGNING:-0}" = "1" ]; then
	timestamp="--timestamp"
fi
if identity_sign; then
	exit 0
fi

if [ "${REQUIRE_SIGNING:-0}" = "1" ]; then
	echo "error: release signing failed"
	exit 1
fi

echo "warning: $identity failed; falling back to ad-hoc"
adhoc_sign
