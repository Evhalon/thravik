#!/bin/sh
set -eu
cd "$(dirname "$0")/.."
# Local Supabase only; never receives a production URL or credential.
container=supabase_db_redent-sync-foundation
docker exec -i "$container" psql -U postgres -d postgres -v ON_ERROR_STOP=1 < tests/sync_foundation.sql
docker exec -i "$container" psql -U postgres -d postgres -v ON_ERROR_STOP=1 < tests/vault_recovery.sql
docker exec -i "$container" psql -U postgres -d postgres -v ON_ERROR_STOP=1 < tests/device_membership.sql
