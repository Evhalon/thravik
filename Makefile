APP        := Redent
BUNDLE_ID  := app.redent.browser
CONFIG     ?= release
BUILD_DIR  := .build/$(CONFIG)
APP_DIR    := dist/$(APP).app
MAX_LINES  := 150

.PHONY: all build test run app clean verify release check-lines check-arch check-force-unwrap

all: app

build:
	swift build -c $(CONFIG)

test:
	swift test

## Bundle the SPM executable into a signed .app.
## Keep the .app directory so Launch Services / TCC see the same app. Sign with
## Apple Development when present — ad-hoc cdhash is unique per rebuild, so
## Keychain, cookies, and authenticator look wiped on the next `make run`.
app: build
	@mkdir -p "$(APP_DIR)/Contents/MacOS" "$(APP_DIR)/Contents/Resources"
	@rm -rf "$(APP_DIR)/Contents/MacOS/$(APP)" "$(APP_DIR)/Contents/Resources/"*.bundle
	@cp "$(BUILD_DIR)/$(APP)" "$(APP_DIR)/Contents/MacOS/$(APP)"
	@cp Resources/Info.plist "$(APP_DIR)/Contents/Info.plist"
	@if [ -f Resources/AppIcon.icns ]; then cp Resources/AppIcon.icns "$(APP_DIR)/Contents/Resources/"; fi
	@for b in $(BUILD_DIR)/*.bundle; do [ -e "$$b" ] && cp -R "$$b" "$(APP_DIR)/Contents/Resources/" || true; done
	@sh scripts/sign-app.sh "$(APP_DIR)" "$(BUNDLE_ID)" Resources/Redent.entitlements
	@echo "built $(APP_DIR)"

run: app
	@open "$(APP_DIR)"

release: verify app
	@sh scripts/package-release.sh "$(APP_DIR)" dist/Redent-macOS.dmg

clean:
	@rm -rf .build dist

## --- quality gates (see AGENTS.md §7) ---

check-lines:
	@fail=0; \
	for f in $$(find Sources Tests -name '*.swift'); do \
		n=$$(wc -l < "$$f" | tr -d ' '); \
		if [ "$$n" -gt $(MAX_LINES) ]; then echo "  $$f: $$n lines (max $(MAX_LINES))"; fail=1; fi; \
	done; \
	if [ $$fail -eq 1 ]; then echo "FAIL: files over $(MAX_LINES) lines"; exit 1; fi; \
	echo "OK: no file over $(MAX_LINES) lines"

check-arch:
	@fail=0; \
	if grep -rlE '^import (SwiftUI|WebKit|AppKit|Security)' Sources/RedentKit >/dev/null 2>&1; then \
		echo "FAIL: RedentKit must not import platform frameworks"; \
		grep -rlE '^import (SwiftUI|WebKit|AppKit|Security)' Sources/RedentKit; fail=1; fi; \
	if grep -rl '^import WebKit' Sources --include='*.swift' | grep -v '^Sources/RedentEngine' >/dev/null 2>&1; then \
		echo "FAIL: only RedentEngine may import WebKit"; \
		grep -rl '^import WebKit' Sources --include='*.swift' | grep -v '^Sources/RedentEngine'; fail=1; fi; \
	if grep -rlE '^import (Security|LocalAuthentication)' Sources --include='*.swift' | grep -vE '^Sources/(RedentVault|RedentImport|Redent)/' >/dev/null 2>&1; then \
		echo "FAIL: Keychain access belongs in RedentVault"; fail=1; fi; \
	[ $$fail -eq 0 ] && echo "OK: dependency rule holds"

check-force-unwrap:
	@if grep -rnE '(try!|as!)' Sources --include='*.swift'; then \
		echo "FAIL: force try/cast in Sources"; exit 1; fi; \
	echo "OK: no force try/cast"

verify: check-lines check-arch check-force-unwrap build test
	@echo "-- verify passed --"
