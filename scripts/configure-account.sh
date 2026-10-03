#!/bin/sh
set -eu

# Only public project configuration belongs in the application bundle.
plist=$1
root=$(CDPATH= cd -- "$(dirname -- "$0")/.." && pwd)
# Public project values only. Absent file leaves the build without an account.
if [ -z "${REDENT_SUPABASE_URL:-}" ] && [ -f "$root/config/account.release.env" ]; then
  set -a
  # shellcheck disable=SC1091
  . "$root/config/account.release.env"
  set +a
fi
if [ -n "${REDENT_ICLOUD_ACCESS_GROUP:-}" ]; then
  plutil -replace RedentICloudAccessGroup -string "$REDENT_ICLOUD_ACCESS_GROUP" "$plist"
fi
endpoint=${REDENT_SUPABASE_URL:-}
publishable_key=${REDENT_SUPABASE_PUBLISHABLE_KEY:-}
if [ -z "$endpoint" ] && [ -z "$publishable_key" ]; then
  if [ "${REQUIRE_ACCOUNT_CONFIG:-0}" = "1" ]; then
    echo "error: release requires account configuration" >&2
    exit 1
  fi
  exit 0
fi
case "$endpoint" in
  https://*) ;;
  *) echo "error: REDENT_SUPABASE_URL must use HTTPS" >&2; exit 1 ;;
esac
case "$publishable_key" in
  sb_publishable_*) ;;
  *) echo "error: configure a Supabase publishable key, never an admin key" >&2; exit 1 ;;
esac
plutil -replace RedentSupabaseURL -string "$endpoint" "$plist"
plutil -replace RedentSupabasePublishableKey -string "$publishable_key" "$plist"
