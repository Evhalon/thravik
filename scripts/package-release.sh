#!/bin/sh
set -eu

app_path="$1"
image_path="$2"

codesign --verify --deep --strict --verbose=2 "$app_path"

rm -f "$image_path"
hdiutil create -volname Redent -srcfolder "$app_path" -ov -format UDZO "$image_path"
echo "packaged $image_path"
