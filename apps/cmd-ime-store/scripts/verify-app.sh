#!/bin/bash
set -euo pipefail

app=${1:?usage: verify-app.sh APP_PATH VERSION BUILD_NUMBER [EXPECTED_TEAM_ID]}
version=${2:?missing expected marketing version}
build=${3:?missing expected build number}
expected_team=${4:-}
plist="$app/Contents/Info.plist"
resources="$app/Contents/Resources"
[[ -d "$app" && -f "$plist" ]]
[[ "$(/usr/libexec/PlistBuddy -c 'Print :CFBundleIdentifier' "$plist")" == 'com.kazuki.cmdime' ]]
[[ "$(/usr/libexec/PlistBuddy -c 'Print :CFBundleShortVersionString' "$plist")" == "$version" ]]
[[ "$(/usr/libexec/PlistBuddy -c 'Print :CFBundleVersion' "$plist")" == "$build" ]]
[[ "$(/usr/libexec/PlistBuddy -c 'Print :CFBundleIconName' "$plist")" == 'AppIcon' ]]
[[ -f "$resources/PrivacyInfo.xcprivacy" ]]
/usr/bin/plutil -lint "$resources/PrivacyInfo.xcprivacy" >/dev/null
/usr/libexec/PlistBuddy -c 'Print :NSPrivacyTracking' "$resources/PrivacyInfo.xcprivacy" | grep -qx false
python3 - "$resources/PrivacyInfo.xcprivacy" <<'PYVERIFY'
import plistlib, sys
with open(sys.argv[1], 'rb') as f:
    privacy = plistlib.load(f)
assert privacy.get('NSPrivacyTracking') is False
assert privacy.get('NSPrivacyCollectedDataTypes') == []
assert privacy.get('NSPrivacyAccessedAPITypes') == [{
    'NSPrivacyAccessedAPIType': 'NSPrivacyAccessedAPICategoryUserDefaults',
    'NSPrivacyAccessedAPITypeReasons': ['CA92.1'],
}]
PYVERIFY
/usr/libexec/PlistBuddy -c 'Print :NSPrivacyAccessedAPITypes:0:NSPrivacyAccessedAPIType' "$resources/PrivacyInfo.xcprivacy" | grep -qx 'NSPrivacyAccessedAPICategoryUserDefaults'
/usr/libexec/PlistBuddy -c 'Print :NSPrivacyAccessedAPITypes:0:NSPrivacyAccessedAPITypeReasons:0' "$resources/PrivacyInfo.xcprivacy" | grep -qx 'CA92.1'
if [[ -n "$expected_team" ]]; then
  signature=$(/usr/bin/codesign -dv --verbose=4 "$app" 2>&1 || true)
  printf '%s\n' "$signature" | grep -Fxq "TeamIdentifier=$expected_team"
  printf '%s\n' "$signature" | grep -Eq 'Authority=Apple Distribution:|Authority=3rd Party Mac Developer Application:'
  /usr/bin/codesign --verify --deep --strict "$app"
  /usr/bin/swift "$(dirname "$0")/verify-sandbox.swift" "$app"
fi
if /usr/bin/find "$app/Contents" -iname '*sparkle*' -print -quit | grep -q .; then
  echo 'Sparkle content found in the Mac App Store app.' >&2
  exit 1
fi
printf 'CmdIME app bundle metadata verified: %s (%s)\n' "$version" "$build"
