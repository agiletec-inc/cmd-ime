#!/usr/bin/env bash
set -euo pipefail

# Verifies a distribution-mode CmdIME.app bundle is signed with a Developer ID
# Application identity, hardened-runtime enabled, and structurally intact —
# the preconditions notarytool requires before it will accept a submission.
#
# Usage: verify-developer-id-signature.sh /path/to/CmdIME.app
# Env:   CMDIME_EXPECTED_TEAM_ID (optional) — fail if TeamIdentifier differs.

app_path=${1:?usage: verify-developer-id-signature.sh /path/to/CmdIME.app}
if [[ ! -d "$app_path" ]]; then
    echo "App bundle does not exist: $app_path" >&2
    exit 1
fi

signature=$(codesign -dv --verbose=4 "$app_path" 2>&1)
echo "$signature"

grep -Fq 'Authority=Developer ID Application:' <<<"$signature" || {
    echo 'App is not signed with a Developer ID Application identity.' >&2
    exit 1
}

if [[ -n "${CMDIME_EXPECTED_TEAM_ID:-}" ]]; then
    grep -Fq "TeamIdentifier=${CMDIME_EXPECTED_TEAM_ID}" <<<"$signature" || {
        echo "App signature has an unexpected Team ID (expected ${CMDIME_EXPECTED_TEAM_ID})." >&2
        exit 1
    }
fi

grep -Eq 'flags=0x[0-9a-f]*10000\(runtime\)' <<<"$signature" || {
    echo 'App is not hardened-runtime signed (flags=... runtime missing).' >&2
    exit 1
}

codesign --verify --strict --deep "$app_path"

bundle_id=$(/usr/libexec/PlistBuddy -c 'Print :CFBundleIdentifier' "$app_path/Contents/Info.plist")
[[ "$bundle_id" == 'com.kazuki.cmdime' ]] || {
    echo "Unexpected bundle ID: $bundle_id" >&2
    exit 1
}

echo "Developer ID signature verification passed: $app_path"
