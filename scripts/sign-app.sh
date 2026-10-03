#!/bin/sh
# Sign the Thravik app. The legacy Keychain pins an ad-hoc app's ACL to its
# cdhash, which changes on every build, so each rebuild re-prompts for the
# vault and the authenticator. A certificate-backed signature keeps a stable
# designated requirement, so "Always Allow" is asked once and then sticks.
# Local builds sign with the Developer ID identity: the Keychain partitions
# file-based items by Team ID, and only a Team ID survives a rebuild — a
# self-signed certificate still partitions by cdhash and re-prompts. The
# Apple Development key needs Keychain UI to sign (errSecInternalComponent),
# so it is skipped. "Redent Development" is the last resort before ad-hoc.
# CODESIGN_IDENTITY=- forces ad-hoc. Release builds set REQUIRE_SIGNING=1 with
# a Developer ID identity, and notarization rejects any nested binary that is
# not signed by that same identity — so helpers are signed before the app.
set -e
APP_DIR="$1"
BUNDLE_ID="$2"
ENTITLEMENTS="$3"
HELPERS_DIR="$APP_DIR/Contents/Helpers"
PROFILE_PATH="$APP_DIR/Contents/embedded.provisionprofile"
SCRIPT_DIR=$(CDPATH= cd -- "$(dirname -- "$0")" && pwd)
managed_passkeys=0
managed_icloud=0

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
	|| return 1
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
	team_identity=$(security find-identity -v -p codesigning 2>/dev/null \
		| sed -n 's/.*"\(Developer ID Application: [^"]*\)".*/\1/p' | head -n 1)
	if [ -n "$team_identity" ]; then echo "$team_identity"; return; fi
	sh "$SCRIPT_DIR/ensure-dev-identity.sh" >/dev/null 2>&1 && echo "Redent Development"
}

# Under set -e a failed lookup would end the script silently; ad-hoc is the fallback.
identity="${CODESIGN_IDENTITY:-$(local_identity || true)}"
identity="${identity:--}"
passkey_profile="${PROVISIONING_PROFILE:-}"
icloud_profile="${ICLOUD_PROVISIONING_PROFILE:-}"
if [ "${REQUIRE_ICLOUD_PASSWORDS:-0}" = "1" ] && [ -z "$icloud_profile" ]; then
	echo "error: REQUIRE_ICLOUD_PASSWORDS=1 needs ICLOUD_PROVISIONING_PROFILE" >&2
	exit 1
fi
if [ "${REQUIRE_PASSKEYS:-0}" = "1" ] && [ -z "$passkey_profile" ]; then
	echo "error: REQUIRE_PASSKEYS=1 needs PROVISIONING_PROFILE with Apple's browser passkey approval" >&2
	exit 1
fi
if [ -n "$passkey_profile" ] && [ -n "$icloud_profile" ] && ! cmp -s "$passkey_profile" "$icloud_profile"; then
	echo "error: passkeys and iCloud passwords must use the same provisioning profile" >&2
	exit 1
fi
selected_profile="$passkey_profile"
[ -n "$selected_profile" ] || selected_profile="$icloud_profile"

if [ -n "$selected_profile" ]; then
	if [ "$identity" = "-" ]; then
		echo "error: managed browser capabilities require an Apple signing identity and approved profile" >&2
		exit 1
	fi
	signing_work=$(mktemp -d)
	trap 'rm -rf "$signing_work"' EXIT
	security cms -D -i "$selected_profile" > "$signing_work/profile.plist"
	current_entitlements="$ENTITLEMENTS"
	if [ -n "$passkey_profile" ]; then
		python3 "$SCRIPT_DIR/prepare-passkey-entitlements.py" \
			"$current_entitlements" "$signing_work/profile.plist" "$BUNDLE_ID" "$signing_work/passkey-entitlements.plist"
		current_entitlements="$signing_work/passkey-entitlements.plist"
		managed_passkeys=1
	fi
	if [ -n "$icloud_profile" ]; then
		python3 "$SCRIPT_DIR/prepare-keychain-entitlements.py" \
			"$current_entitlements" "$signing_work/profile.plist" "$BUNDLE_ID" \
			"${REDENT_ICLOUD_ACCESS_GROUP:-}" "$signing_work/entitlements.plist"
		current_entitlements="$signing_work/entitlements.plist"
		managed_icloud=1
	fi
	if [ "$current_entitlements" != "$signing_work/entitlements.plist" ]; then
		cp "$current_entitlements" "$signing_work/entitlements.plist"
	fi
	ENTITLEMENTS="$signing_work/entitlements.plist"
	cp "$selected_profile" "$PROFILE_PATH"
else
	if [ "${REQUIRE_PASSKEYS:-0}" = "1" ]; then
		echo "error: REQUIRE_PASSKEYS=1 needs PROVISIONING_PROFILE with Apple's browser passkey approval" >&2
		exit 1
	fi
	# A local rebuild must not carry a previous release's restricted profile.
	rm -f "$PROFILE_PATH"
	echo "saved passkeys unavailable: no approved browser provisioning profile supplied"
fi
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
	if [ "$managed_passkeys" = "1" ] || [ "$managed_icloud" = "1" ]; then
		certificate_prefix="$signing_work/signer-"
		if ! codesign --display --extract-certificates "$certificate_prefix" "$APP_DIR"; then
			rm -f "$PROFILE_PATH"
			echo "error: cannot extract the signing certificate for profile validation" >&2
			exit 1
		fi
		if ! python3 "$SCRIPT_DIR/validate-profile-certificate.py" \
			"$signing_work/profile.plist" "${certificate_prefix}0"; then
			rm -f "$PROFILE_PATH"
			exit 1
		fi
		codesign --verify --strict "$APP_DIR" || { rm -f "$PROFILE_PATH"; exit 1; }
	fi
	exit 0
fi

if [ "$managed_passkeys" = "1" ] || [ "$managed_icloud" = "1" ] || [ "${REQUIRE_SIGNING:-0}" = "1" ]; then
	rm -f "$PROFILE_PATH"
	echo "error: signing failed; the required capabilities cannot be preserved" >&2
	exit 1
fi

echo "warning: $identity failed; falling back to ad-hoc"
adhoc_sign
