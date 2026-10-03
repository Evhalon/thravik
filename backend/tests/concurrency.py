"""Commit-order regression test against the disposable PostgreSQL harness."""
import json
import subprocess
import sys
import time

container = sys.argv[1]
command = ["docker", "exec", "-i", container, "psql", "-U", "postgres", "-Atq", "-v", "ON_ERROR_STOP=1"]
owner = "00000000-0000-0000-0000-000000000003"
subprocess.run(command, input=f"insert into auth.users(id) values ('{owner}');", text=True, check=True)


def transaction(index, delay):
    request = json.dumps({
        "mutation_id": f"10000000-0000-0000-0000-{index:012d}",
        "record_id": f"20000000-0000-0000-0000-{index:012d}",
        "collection": "spaces", "expected_revision": 0, "deleted": False,
        "encrypted_payload": "A" * 40,
    })
    return f"""
    begin;
    set local role authenticated;
    select set_config('request.jwt.claim.sub', '{owner}', true);
    select 'CURSOR:' || (public.sync_push('{request}'::jsonb)->>'cursor');
    select pg_sleep({delay});
    commit;
    """


first = subprocess.Popen(command, stdin=subprocess.PIPE, stdout=subprocess.PIPE, stderr=subprocess.PIPE, text=True)
try:
    first.stdin.write(transaction(1, 2))
    first.stdin.close()
    marker = ""
    for line in first.stdout:
        if line.startswith("CURSOR:"):
            marker = line.strip()
            break
    if marker != "CURSOR:1":
        raise RuntimeError("first transaction failed: " + first.stderr.read())
    started = time.monotonic()
    second = subprocess.run(command, input=transaction(2, 0), text=True, capture_output=True, timeout=15, check=True)
    elapsed = time.monotonic() - started
    first.wait(timeout=15)
    if first.returncode != 0:
        raise RuntimeError("first transaction did not commit")
    if "CURSOR:2" not in second.stdout or elapsed < 1:
        raise RuntimeError("later cursor did not wait for the earlier commit")
    print("OK: concurrent cursors serialize through commit")
finally:
    if first.poll() is None:
        first.kill()
        first.wait()
