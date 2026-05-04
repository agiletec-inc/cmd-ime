#!/usr/bin/env bash
set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
PROJECT_ROOT="$(cd "$SCRIPT_DIR/.." && pwd)"
BUILD_DIR="$PROJECT_ROOT/.build"
TRIPLE="arm64-apple-macosx"
BIN_NAME="CmdIMESwift"
APP_NAME="CmdIME"
APP_DIR="$BUILD_DIR/release/${APP_NAME}.app"
MACOS_DIR="$APP_DIR/Contents/MacOS"
RESOURCES_DIR="$APP_DIR/Contents/Resources"
INFO_PLIST="$APP_DIR/Contents/Info.plist"
ICON_SOURCE="$PROJECT_ROOT/../../AppIcon.icns"

resolve_version() {
    if [[ -n "${CMD_IME_VERSION:-}" ]]; then
        printf '%s' "$CMD_IME_VERSION"
        return
    fi
    local manifest="$PROJECT_ROOT/../../manifest.toml"
    if [[ -f "$manifest" ]]; then
        local v
        v=$(awk -F'"' '/^version[[:space:]]*=/ {print $2; exit}' "$manifest" 2>/dev/null)
        if [[ -n "$v" ]]; then
            printf '%s' "$v"
            return
        fi
    fi
    git -C "$PROJECT_ROOT" describe --tags --always 2>/dev/null || printf '0.0.0'
}
VERSION="$(resolve_version)"

echo ">> Building Swift release binary"
swift build -c release --package-path "$PROJECT_ROOT"

BIN_PATH="$BUILD_DIR/$TRIPLE/release/$BIN_NAME"
if [[ ! -f "$BIN_PATH" ]]; then
    echo "Binary not found at $BIN_PATH" >&2
    exit 1
fi

echo ">> Creating app bundle at $APP_DIR"
rm -rf "$APP_DIR"
mkdir -p "$MACOS_DIR" "$RESOURCES_DIR"

cp "$BIN_PATH" "$MACOS_DIR/$APP_NAME"
chmod +x "$MACOS_DIR/$APP_NAME"

if [[ -f "$ICON_SOURCE" ]]; then
    cp "$ICON_SOURCE" "$RESOURCES_DIR/AppIcon.icns"
    ICON_NAME="AppIcon.icns"
else
    ICON_NAME=""
fi

cat > "$INFO_PLIST" <<EOF
<?xml version="1.0" encoding="UTF-8"?>
<!DOCTYPE plist PUBLIC "-//Apple//DTD PLIST 1.0//EN" "http://www.apple.com/DTDs/PropertyList-1.0.dtd">
<plist version="1.0">
<dict>
    <key>CFBundleName</key>
    <string>$APP_NAME</string>
    <key>CFBundleDisplayName</key>
    <string>$APP_NAME</string>
    <key>CFBundleIdentifier</key>
    <string>com.kazuki.cmdime</string>
    <key>CFBundleExecutable</key>
    <string>$APP_NAME</string>
    <key>CFBundlePackageType</key>
    <string>APPL</string>
    <key>CFBundleVersion</key>
    <string>$VERSION</string>
    <key>CFBundleShortVersionString</key>
    <string>$VERSION</string>
    <key>LSMinimumSystemVersion</key>
    <string>13.0</string>
    <key>LSUIElement</key>
    <true/>
    <key>NSHighResolutionCapable</key>
    <true/>
EOF

if [[ -n "$ICON_NAME" ]]; then
cat >> "$INFO_PLIST" <<EOF
    <key>CFBundleIconFile</key>
    <string>$ICON_NAME</string>
EOF
fi

cat >> "$INFO_PLIST" <<'EOF'
</dict>
</plist>
EOF

# Stable Designated Requirement keeps TCC/Accessibility grants alive across
# brew upgrades. Set CMDIME_SIGNING_IDENTITY to a self-signed (or Developer ID)
# identity in CI; falls back to ad-hoc for local dev when unset.
SIGN_IDENTITY="${CMDIME_SIGNING_IDENTITY:--}"
echo ">> Signing app bundle with identity: $SIGN_IDENTITY"
codesign --force --deep \
    --options runtime \
    --timestamp \
    --sign "$SIGN_IDENTITY" \
    "$APP_DIR"

echo ">> Bundle ready: $APP_DIR"
