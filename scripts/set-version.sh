#!/bin/sh
set -eu

version="$1"
build="$2"
plist="Resources/Info.plist"

/usr/libexec/PlistBuddy -c "Set :CFBundleShortVersionString $version" "$plist"
/usr/libexec/PlistBuddy -c "Set :CFBundleVersion $build" "$plist"
