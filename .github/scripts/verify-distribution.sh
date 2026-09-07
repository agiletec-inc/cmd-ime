#!/usr/bin/env bash
set -euo pipefail
app_bundle="${1:?app bundle path is required}"
: "${CMDIME_EXPECTED_TEAM_ID:?expected Apple Team ID is required}"
codesign --verify --deep --strict "$app_bundle"
signature=$(codesign -dv --verbose=4 "$app_bundle" 2>&1)
grep -Fq 'Authority=Developer ID Application: ' <<< "$signature"
grep -Fxq "TeamIdentifier=$CMDIME_EXPECTED_TEAM_ID" <<< "$signature"
grep -Eq '^CodeDirectory .*flags=.*runtime' <<< "$signature"
grep -Eq '^Timestamp=.+' <<< "$signature"
echo "Verified 1 app bundle: Developer ID, Team ID, hardened runtime, timestamp and nested signatures"
