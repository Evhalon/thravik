#!/usr/bin/env python3
"""Require the signed app's leaf certificate to be authorized by its profile."""
import plistlib
import sys


def validate(profile_path, certificate_path):
    with open(profile_path, "rb") as source:
        profile = plistlib.load(source)
    with open(certificate_path, "rb") as source:
        certificate = source.read()
    authorized = profile.get("DeveloperCertificates", [])
    if not certificate or not isinstance(authorized, list):
        raise ValueError("profile or signing certificate is missing")
    if not any(isinstance(value, bytes) and value == certificate for value in authorized):
        raise ValueError("profile does not authorize the signing certificate")


if __name__ == "__main__":
    try:
        validate(*sys.argv[1:])
    except (ValueError, TypeError, OSError, plistlib.InvalidFileException) as error:
        sys.exit(f"error: profile certificate mismatch: {error}")
