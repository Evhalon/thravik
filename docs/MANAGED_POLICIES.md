# Managed policies (macOS MDM)

Redent reads organization policies from the macOS **managed preferences domain** for the app bundle identifier. Values deployed via configuration profiles or files under `/Library/Managed Preferences/<bundle-id>.plist` appear in `UserDefaults.standard`. Redent applies a key **only when** `UserDefaults.standard.objectIsForced(forKey:)` is true, so ordinary user defaults cannot spoof policy.

Development bundle id: `app.redent.browser.dev`. Production: `app.redent.browser`.

## Keys

| Key | Type | Effect |
|-----|------|--------|
| `HomepageURL` | String | Sets homepage; control locked in Settings. |
| `DefaultSearchEngine` | String | Built-in engine id (`duckduckgo`, `google`, `bing`, `brave`, `ecosia`) or custom template with `%s` placeholder. |
| `DisablePrivateWindows` | Boolean | New Private Window (menus, ⌘⇧N, Command Bar) does nothing; menu items are disabled. |
| `DisableExtensions` | Boolean | Blocks extension installs (store, folder, archive) except store IDs in `ExtensionAllowlist`. |
| `ExtensionAllowlist` | Array of String | Chrome Web Store IDs that may be installed. A non-empty list restricts installs to these IDs even without `DisableExtensions`; folder/archive installs are then refused. |
| `DisablePasswordSaving` | Boolean | Turns off password-save prompts; control locked. Autofill of already saved passwords keeps working. |
| `ForceTrackerBlocking` | Boolean | Forces ad/tracker blocking on; control locked. |
| `DisableAccountSync` | Boolean | Stops workspace sync (no pull, no publish) and locks the password storage provider controls. |
| `URLBlocklist` | Array of String | Hosts or registrable domains (a URL is reduced to its host). A registrable domain (`example.com`) blocks itself and every subdomain; a deeper host (`mail.example.com`) blocks only that host. No wildcards, never substring. |

All keys are optional. When none are forced, behavior matches an unmanaged install.

Managed values are never written into the user's own settings. Removing a policy restores the user's previous homepage, search engine, tracker and password-save choices; edits to unlocked settings made while managed are kept. A managed search engine does not move the homepage. A custom-template engine appears as "Managed Search" (keyword `managed`) only while the policy is active.

## Enforcement scope

- **URL blocklist**: checked on typed/programmatic loads, every main-frame navigation decision (links, redirects, back/forward, reloads, restored or woken tabs, popups and ⌘-click tabs), subframe loads and downloads (silently cancelled), and search prerendering. A blocked main-frame load shows "Blocked by your organization" instead of the page and is not recorded in history. A tab already showing a page when that host becomes blocked keeps it until it navigates or reloads.
- **Private windows**: already open private windows stay open when the policy arrives.
- **Extensions**: install-time only. Already installed extensions stay installed and keep running; the user can still disable or remove them.
- **Account sync**: if the user is signed in, the account stays signed in; only sync stops. A Redent cloud password provider chosen before the policy arrived stays selected and keeps syncing passwords (the provider controls are locked, so it cannot be newly chosen); stopping it would cut the user off from their saved passwords.

## Local testing

Managed preferences require root. Example (dev bundle id):

```bash
sudo defaults write "/Library/Managed Preferences/app.redent.browser.dev" DisablePrivateWindows -bool true
sudo defaults write "/Library/Managed Preferences/app.redent.browser.dev" URLBlocklist -array evil.com
sudo defaults write "/Library/Managed Preferences/app.redent.browser.dev" ForceTrackerBlocking -bool true
```

Restart Redent after changing managed preferences. Remove with:

```bash
sudo defaults delete "/Library/Managed Preferences/app.redent.browser.dev"
```

## Sample `.mobileconfig` fragment

```xml
<?xml version="1.0" encoding="UTF-8"?>
<!DOCTYPE plist PUBLIC "-//Apple//DTD PLIST 1.0//EN" "http://www.apple.com/DTDs/PropertyList-1.0.dtd">
<plist version="1.0">
<dict>
  <key>PayloadContent</key>
  <array>
    <dict>
      <key>PayloadType</key>
      <string>com.apple.ManagedClient.preferences</string>
      <key>PayloadIdentifier</key>
      <string>com.example.redent.policies</string>
      <key>PayloadUUID</key>
      <string>00000000-0000-0000-0000-000000000001</string>
      <key>PayloadVersion</key>
      <integer>1</integer>
      <key>PayloadDisplayName</key>
      <string>Redent Browser Policies</string>
      <key>PayloadDescription</key>
      <string>Managed browser settings</string>
      <key>PayloadOrganization</key>
      <string>Example Corp</string>
      <key>PayloadScope</key>
      <string>System</string>
      <key>app.redent.browser</key>
      <dict>
        <key>Forced</key>
        <array>
          <dict>
            <key>mcx_preference_settings</key>
            <dict>
              <key>DisablePrivateWindows</key>
              <true/>
              <key>HomepageURL</key>
              <string>https://intranet.example.com/</string>
              <key>DefaultSearchEngine</key>
              <string>google</string>
              <key>ForceTrackerBlocking</key>
              <true/>
              <key>DisablePasswordSaving</key>
              <true/>
              <key>DisableAccountSync</key>
              <true/>
              <key>URLBlocklist</key>
              <array>
                <string>gambling.example</string>
              </array>
              <key>ExtensionAllowlist</key>
              <array>
                <string>abcdefghijklmnopqrstuvwxyzabcdef</string>
              </array>
              <key>DisableExtensions</key>
              <true/>
            </dict>
          </dict>
        </array>
      </dict>
    </dict>
  </array>
  <key>PayloadType</key>
  <string>Configuration</string>
  <key>PayloadIdentifier</key>
  <string>com.example.redent.profile</string>
  <key>PayloadUUID</key>
  <string>00000000-0000-0000-0000-000000000002</string>
  <key>PayloadVersion</key>
  <integer>1</integer>
  <key>PayloadDisplayName</key>
  <string>Redent Work Profile</string>
</dict>
</plist>
```

Sign and install the profile with your MDM or `profiles install -path RedentWork.mobileconfig`.

## Limitations

- Policies refresh when `UserDefaults.didChangeNotification` fires or Redent becomes active; otherwise on the next launch.
- No remote policy backend: macOS configuration profiles only.
