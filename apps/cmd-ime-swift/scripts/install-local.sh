#!/usr/bin/env bash
set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
APP_BUNDLE="$SCRIPT_DIR/../.build/release/CmdIME.app"
DEST_APP="/Applications/CmdIME.app"

if [[ ! -d "$APP_BUNDLE" ]]; then
    echo "Error: Build the app first (run package.sh)" >&2
    exit 1
fi

echo ">> Preparing to install to $DEST_APP"

# 1. Kill the running app if any
if pgrep -x "CmdIME" > /dev/null; then
    echo ">> Closing running instance..."
    pkill -x "CmdIME" || true
    sleep 1
fi

# 2. Backup or Remove existing
if [[ -d "$DEST_APP" ]]; then
    echo ">> Removing existing app at $DEST_APP"
    # Use sudo if permission is needed, but for local dev /Applications is usually writable
    rm -rf "$DEST_APP"
fi

# 3. Copy new bundle
echo ">> Copying new bundle to /Applications"
cp -R "$APP_BUNDLE" "$DEST_APP"

# 4. Launch the new version
echo ">> Launching $DEST_APP"
open "$DEST_APP"

echo ">> Done. Check the version in the menu bar."
