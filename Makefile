APP        := Thravik
EXECUTABLE := Redent
BUNDLE_ID  := app.redent.browser
CONFIG     ?= release
TEST_FLAGS ?=
BUILD_DIR  := .build/$(CONFIG)
APP_DIR    := dist/$(APP).app
STAGING_APP_DIR := dist/.$(APP)-build.app
PREVIOUS_APP_DIR := dist/.$(APP)-previous.app
MAX_LINES  := 150

.PHONY: all build test run app clean verify release check-lines check-layout check-arch check-force-unwrap

all: app

build:
	swift build -c $(CONFIG)

test:
	swift test $(TEST_FLAGS)

## Bundle the SPM executable into a signed .app.
## Keep the .app path so Launch Services / TCC see the same app. Local
## builds use an explicit stable designated requirement; release builds can
## provide CODESIGN_IDENTITY and REQUIRE_SIGNING=1.
app: build
	@rm -rf "$(STAGING_APP_DIR)"
	@mkdir -p "$(STAGING_APP_DIR)/Contents/MacOS" "$(STAGING_APP_DIR)/Contents/Resources" "$(STAGING_APP_DIR)/Contents/Helpers"
	@cp "$(BUILD_DIR)/$(EXECUTABLE)" "$(STAGING_APP_DIR)/Contents/MacOS/$(APP)"
	@cp "$(BUILD_DIR)/RedentAppShim" "$(STAGING_APP_DIR)/Contents/Helpers/RedentAppShim"
	@cp Resources/Info.plist "$(STAGING_APP_DIR)/Contents/Info.plist"
	@if [ -f Resources/AppIcon.icns ]; then cp Resources/AppIcon.icns "$(STAGING_APP_DIR)/Contents/Resources/"; fi
	@copied=0; \
	for b in $(BUILD_DIR)/*.bundle; do \
		[ -e "$$b" ] || continue; \
		cp -R "$$b" "$(STAGING_APP_DIR)/Contents/Resources/" || exit 1; copied=1; \
	done; \
	if [ "$$copied" -eq 0 ]; then \
		echo "error: no SwiftPM resource bundle in $(BUILD_DIR) — the app would crash on launch"; exit 1; fi
	@sh scripts/sign-app.sh "$(STAGING_APP_DIR)" "$(BUNDLE_ID)" Resources/Redent.entitlements
	@rm -rf "$(PREVIOUS_APP_DIR)"
	@if [ -d "$(APP_DIR)" ]; then mv "$(APP_DIR)" "$(PREVIOUS_APP_DIR)"; fi
	@mv "$(STAGING_APP_DIR)" "$(APP_DIR)" || { mv "$(PREVIOUS_APP_DIR)" "$(APP_DIR)"; exit 1; }
	@rm -rf "$(PREVIOUS_APP_DIR)"
	@echo "built $(APP_DIR)"

run: app
	@open "$(APP_DIR)"

release: verify app
	@sh scripts/package-release.sh "$(APP_DIR)" dist/Thravik-macOS.dmg

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

check-layout:
	@sh scripts/check-source-layout.sh

check-force-unwrap:
	@if grep -rnE '(try!|as!)' Sources --include='*.swift'; then \
		echo "FAIL: force try/cast in Sources"; exit 1; fi; \
	echo "OK: no force try/cast"

verify: check-lines check-layout check-arch check-force-unwrap build test
	@echo "-- verify passed --"
