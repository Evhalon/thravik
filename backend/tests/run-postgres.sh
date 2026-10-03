#!/bin/sh
set -eu
cd "$(dirname "$0")/.."
container="redent-sync-test-$$"
cleanup() { docker rm -f "$container" >/dev/null 2>&1 || true; }
trap cleanup EXIT HUP INT TERM
# Requires a cached development image; no published ports, host mounts or credentials.
docker run --pull never --rm -d --network none --name "$container" \
  -e POSTGRES_HOST_AUTH_METHOD=trust postgres:17-alpine >/dev/null
attempt=0
until docker exec "$container" pg_isready -U postgres >/dev/null 2>&1; do
  attempt=$((attempt + 1))
  if [ "$attempt" -ge 30 ]; then echo "Postgres did not start" >&2; exit 1; fi
  sleep 1
done
docker exec -i "$container" psql -U postgres -v ON_ERROR_STOP=1 < tests/postgres-bootstrap.sql
for migration in supabase/migrations/*.sql; do
  docker exec -i "$container" psql -U postgres -v ON_ERROR_STOP=1 < "$migration"
done
docker exec -i "$container" psql -U postgres -v ON_ERROR_STOP=1 < tests/sync_foundation.sql
docker exec -i "$container" psql -U postgres -v ON_ERROR_STOP=1 < tests/vault_recovery.sql
docker exec -i "$container" psql -U postgres -v ON_ERROR_STOP=1 < tests/device_membership.sql

python3 tests/concurrency.py "$container"
