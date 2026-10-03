#!/usr/bin/env python3
"""Validate a macOS profile before adding its Keychain access group."""
import datetime
import plistlib
import sys

APPLICATION_IDENTIFIER = "com.apple.application-identifier"
TEAM_IDENTIFIER = "com.apple.developer.team-identifier"
KEYCHAIN_GROUPS = "keychain-access-groups"


def prepare(base_path, profile_path, bundle_id, requested_group, output_path):
    with open(base_path, "rb") as source:
        entitlements = plistlib.load(source)
    with open(profile_path, "rb") as source:
        profile = plistlib.load(source)
    allowed = profile.get("Entitlements", {})
    team = allowed.get(TEAM_IDENTIFIER)
    identifier = allowed.get(APPLICATION_IDENTIFIER)
    if not isinstance(team, str) or not team:
        raise ValueError("profile lacks a team identifier")
    if not isinstance(identifier, str) or identifier != f"{team}.{bundle_id}":
        raise ValueError("profile must explicitly authorize this browser's bundle identifier")
    prefixes = profile.get("ApplicationIdentifierPrefix", [])
    if f"{team}." not in prefixes and not any(
        isinstance(prefix, str) and identifier == f"{prefix}.{bundle_id}" for prefix in prefixes
    ):
        raise ValueError("profile application identifier prefix does not match its team")
    if team not in profile.get("TeamIdentifier", []):
        raise ValueError("profile team identifiers do not match")
    if not set(profile.get("Platform", [])) & {"OSX", "macOS"}:
        raise ValueError("profile must support macOS")
    expiration = profile.get("ExpirationDate")
    now = datetime.datetime.now(datetime.timezone.utc).replace(tzinfo=None)
    if not isinstance(expiration, datetime.datetime) or expiration <= now:
        raise ValueError("profile is expired or has no expiration date")
    groups = allowed.get(KEYCHAIN_GROUPS, [])
    if not isinstance(groups, list) or not groups:
        raise ValueError("profile lacks Keychain access groups")
    group = requested_group or f"{team}.{bundle_id}"
    if not isinstance(group, str) or not group.startswith(team + "."):
        raise ValueError("requested Keychain group must use this profile's team prefix")
    if not any(group == allowed_group or wildcard_allows(allowed_group, group) for allowed_group in groups):
        raise ValueError("profile does not authorize the requested Keychain access group")
    entitlements.update({
        APPLICATION_IDENTIFIER: identifier,
        TEAM_IDENTIFIER: team,
        KEYCHAIN_GROUPS: [group],
    })
    with open(output_path, "wb") as output:
        plistlib.dump(entitlements, output)


def wildcard_allows(allowed_group, group):
    return isinstance(allowed_group, str) and allowed_group.endswith(".*") and group.startswith(
        allowed_group[:-1]
    )


if __name__ == "__main__":
    try:
        prepare(*sys.argv[1:])
    except (ValueError, TypeError, OSError, plistlib.InvalidFileException) as error:
        sys.exit(f"error: cannot enable iCloud passwords: {error}")
