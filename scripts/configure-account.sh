#!/bin/sh
set -eu

# Only public project configuration belongs in the application bundle.
plist=$1
if [ -n "${REDENT_ICLOUD_ACCESS_GROUP:-}" ]; then
  plutil -replace RedentICloudAccessGroup -string "$REDENT_ICLOUD_ACCESS_GROUP" "$plist"
fi
endpoint=${REDENT_SUPABASE_URL:-}
publishable_key=${REDENT_SUPABASE_PUBLISHABLE_KEY:-}
if [ -z "$endpoint" ] && [ -z "$publishable_key" ]; then exit 0; fi
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
