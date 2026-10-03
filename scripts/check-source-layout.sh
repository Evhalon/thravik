#!/bin/sh
set -eu

check_layout() {
    find "$1" -name '*.swift' -type f | while IFS= read -r file; do
        relative=${file#"$1"/}
        case "$relative" in
            Features/*|Shared/*|Application/*) ;;
            *) echo "FAIL: $file belongs in a feature, shared responsibility, or application folder"; exit 1 ;;
        esac
    done
}

for target in Redent RedentKit RedentEngine RedentUI RedentVault RedentSync; do
    check_layout "Sources/$target"
done
for target in RedentAppTests RedentKitTests RedentEngineTests RedentUITests RedentVaultTests RedentSyncTests; do
    check_layout "Tests/$target"
done
echo "OK: feature and shared source layout holds"
