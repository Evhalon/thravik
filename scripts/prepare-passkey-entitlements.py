#!/usr/bin/env python3
"""Validate a decoded macOS profile before adding the managed browser capability."""
import datetime
import plistlib
import sys

PASSKEY_ENTITLEMENT = "com.apple.developer.web-browser.public-key-credential"
APPLICATION_IDENTIFIER = "com.apple.application-identifier"
TEAM_IDENTIFIER = "com.apple.developer.team-identifier"


def prepare(base_path, profile_path, bundle_id, output_path):
    with open(base_path, "rb") as source:
        entitlements = plistlib.load(source)
    with open(profile_path, "rb") as source:
        profile = plistlib.load(source)
    allowed = profile.get("Entitlements", {})
    if allowed.get(PASSKEY_ENTITLEMENT) is not True:
        raise ValueError("profile lacks Apple's browser passkey approval")
    team = allowed.get(TEAM_IDENTIFIER)
    identifier = allowed.get(APPLICATION_IDENTIFIER)
    if not isinstance(team, str) or not team:
        raise ValueError("profile lacks a team identifier")
    prefixes = profile.get("ApplicationIdentifierPrefix", [])
    if not any(identifier == f"{prefix}.{bundle_id}" for prefix in prefixes):
        raise ValueError("profile must explicitly authorize this browser's bundle identifier")
    if team not in profile.get("TeamIdentifier", []):
        raise ValueError("profile team identifiers do not match")
    if not set(profile.get("Platform", [])) & {"OSX", "macOS"}:
        raise ValueError("profile must support macOS")
    expiration = profile.get("ExpirationDate")
    now = datetime.datetime.now(datetime.timezone.utc).replace(tzinfo=None)
    if not isinstance(expiration, datetime.datetime) or expiration <= now:
        raise ValueError("profile is expired or has no expiration date")
    entitlements.update({
        PASSKEY_ENTITLEMENT: True,
        APPLICATION_IDENTIFIER: identifier,
        TEAM_IDENTIFIER: team,
    })
    with open(output_path, "wb") as output:
        plistlib.dump(entitlements, output)


if __name__ == "__main__":
    try:
        prepare(*sys.argv[1:])
    except (ValueError, TypeError, OSError, plistlib.InvalidFileException) as error:
        sys.exit(f"error: cannot enable passkeys: {error}")
