import os
from pathlib import Path
import plistlib
import shutil
import subprocess
import tempfile


def verify_configuration():
    with tempfile.TemporaryDirectory() as folder:
        root = Path(folder)
        (root / "scripts").mkdir()
        script = root / "scripts/configure-account.sh"
        shutil.copy(Path(__file__).with_name("configure-account.sh"), script)
        plist = root / "Info.plist"
        plist.write_bytes(plistlib.dumps({}))
        environment = {
            key: value for key, value in os.environ.items()
            if not key.startswith(("REDENT_SUPABASE_", "REQUIRE_ACCOUNT_CONFIG"))
        }

        def configure():
            return subprocess.run(
                ["sh", str(script), str(plist)], env=environment,
                capture_output=True, check=False,
            )

        assert configure().returncode == 0
        environment["REQUIRE_ACCOUNT_CONFIG"] = "1"
        missing = configure()
        assert missing.returncode != 0
        assert b"release requires account configuration" in missing.stderr
        environment["REDENT_SUPABASE_URL"] = "https://example.supabase.co"
        environment["REDENT_SUPABASE_PUBLISHABLE_KEY"] = "sb_publishable_test_public_configuration"
        assert configure().returncode == 0
        bundled = plistlib.loads(plist.read_bytes())
        assert bundled["RedentSupabaseURL"] == environment["REDENT_SUPABASE_URL"]
        assert bundled["RedentSupabasePublishableKey"] == environment["REDENT_SUPABASE_PUBLISHABLE_KEY"]


if __name__ == "__main__":
    verify_configuration()
    print("OK: account configuration packaging")
