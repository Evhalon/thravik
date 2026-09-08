#!/bin/sh
set -eu

app_path="$1"
image_path="$2"

# A .app without its resource bundle launches into a Bundle.module trap.
if ! ls -d "$app_path"/Contents/Resources/*.bundle >/dev/null 2>&1; then
	echo "error: $app_path ships no resource bundle" >&2
	exit 1
fi

codesign --verify --deep --strict --verbose=2 "$app_path"

rm -f "$image_path"
hdiutil create -volname Thravik -srcfolder "$app_path" -ov -format UDZO "$image_path"
echo "packaged $image_path"
