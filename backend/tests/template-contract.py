#!/usr/bin/env python3
"""Check local Supabase auth email templates against their configured contract."""

from html.parser import HTMLParser
from pathlib import Path
import re
import tomllib


ROOT = Path(__file__).resolve().parents[1]
CONFIG_PATH = ROOT / "supabase" / "config.toml"
EXPECTED = {
    "confirmation": {"Token"},
    "magic_link": {"Token"},
    "reauthentication": {"Token"},
    "invite": {"ConfirmationURL"},
    "recovery": {"Token"},
    "email_change": {"Token", "NewEmail"},
}
VARIABLE = re.compile(r"{{\s*(?:if\s+)?\.([A-Za-z][A-Za-z0-9]*)\s*}}")


class ResourceCheck(HTMLParser):
    def __init__(self):
        super().__init__()
        self.forbidden = []
        self.external_links = []

    def handle_starttag(self, tag, attrs):
        attributes = dict(attrs)
        if tag in {"script", "img", "iframe", "video", "audio"}:
            self.forbidden.append(tag)
        for name in ("src", "href", "action"):
            value = attributes.get(name, "")
            if value.lower().startswith(("http://", "https://", "//")):
                self.external_links.append(value)


def check_template(name, path):
    html = path.read_text()
    variables = set(VARIABLE.findall(html))
    missing = EXPECTED[name] - variables
    assert not missing, f"{path}: missing template variables {sorted(missing)}"
    assert "#0d0d0d" in html and "#ff3b12" in html, f"{path}: brand colors missing"
    assert '<html lang="en">' in html, f"{path}: language not declared"
    assert 'role="presentation"' in html, f"{path}: table layout must be presentational"
    assert "<h1" in html, f"{path}: accessible heading missing"

    parser = ResourceCheck()
    parser.feed(html)
    assert not parser.forbidden, f"{path}: external media/scripts are not allowed"
    assert not parser.external_links, f"{path}: hard-coded external URL found: {parser.external_links}"
    assert "@import" not in html.lower(), f"{path}: external stylesheet import found"
    assert "{{ .Token }}" in html if "Token" in EXPECTED[name] else True


def main():
    config = tomllib.loads(CONFIG_PATH.read_text())
    templates = config["auth"]["email"]["template"]
    assert set(templates) == set(EXPECTED), "configured email templates differ from contract"
    for name, contract in EXPECTED.items():
        configured_path = ROOT / "supabase" / templates[name]["content_path"].removeprefix("./supabase/")
        expected_path = ROOT / "supabase" / "templates" / f"{name}.html"
        assert configured_path == expected_path, f"{name}: unexpected configured template path"
        assert configured_path.is_file(), f"{name}: configured template does not exist"
        check_template(name, configured_path)
    print(f"Validated {len(EXPECTED)} Supabase auth email templates.")


if __name__ == "__main__":
    main()
