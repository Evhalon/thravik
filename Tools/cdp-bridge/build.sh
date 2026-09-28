#!/bin/sh
# Bundles the Chrome DevTools bridge into the single script Redent evaluates
# inside a tab's hidden Web Inspector. Commit the output with any change here.
set -eu
cd "$(dirname "$0")"
bun build entry.ts --target=browser --format=iife \
  --outfile ../../Sources/RedentEngine/Resources/redent-devtools-bridge.js
