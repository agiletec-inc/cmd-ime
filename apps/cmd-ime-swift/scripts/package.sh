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
FRAMEWORKS_DIR="$APP_DIR/Contents/Frameworks"
INFO_PLIST="$APP_DIR/Contents/Info.plist"
ICON_SOURCE="$PROJECT_ROOT/../../AppIcon.icns"
CACHE_DIR="$BUILD_DIR/local-cache"
CLANG_MODULE_CACHE_DIR="$CACHE_DIR/clang-module-cache"
SWIFTPM_CACHE_DIR="$CACHE_DIR/swiftpm"
BUILD_MODE="${CMDIME_BUILD_MODE:-distribution}"
SPARKLE_KEY_ACCOUNT="${CMDIME_SPARKLE_KEY_ACCOUNT:-agiletec-inc-cmd-ime}"
SPARKLE_GENERATE_KEYS_BIN="$BUILD_DIR/artifacts/sparkle/Sparkle/bin/generate_keys"
SPARKLE_PUBLIC_ED_KEY="${CMDIME_SPARKLE_PUBLIC_ED_KEY:-}"

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

resolve_signing_identity() {
    if [[ -n "${CMDIME_SIGNING_IDENTITY:-}" ]]; then
        printf '%s' "$CMDIME_SIGNING_IDENTITY"
        return
    fi

    if [[ "$BUILD_MODE" == "local" ]]; then
        local local_identity
        local_identity=$(
            security find-identity -v -p codesigning 2>/dev/null |
            awk -F'"' '/"Apple Development: / { print $2; exit }'
        )
        if [[ -n "$local_identity" ]]; then
            printf '%s' "$local_identity"
            return
        fi
    fi

    local preferred_identity
    preferred_identity=$(
        security find-identity -v -p codesigning 2>/dev/null |
        awk -F'"' '/"Developer ID Application: / { print $2; exit }'
    )
    if [[ -n "$preferred_identity" ]]; then
        printf '%s' "$preferred_identity"
        return
    fi

    printf '%s' "-"
}

require_distribution_prerequisites() {
    if [[ "$BUILD_MODE" == "local" ]]; then
        if [[ "$SIGN_IDENTITY" == "-" ]]; then
            echo "No Apple Development identity found. Falling back to ad-hoc signing for local build."
        fi
        return
    fi

    if [[ -z "$SPARKLE_PUBLIC_ED_KEY" ]]; then
        echo "CMDIME_SPARKLE_PUBLIC_ED_KEY is required for Sparkle distribution builds." >&2
        exit 1
    fi

    if [[ "$SIGN_IDENTITY" == "-" ]]; then
        echo "A Developer ID Application signing identity is required for distribution builds." >&2
        echo "Set CMDIME_SIGNING_IDENTITY explicitly or install a Developer ID Application certificate." >&2
        exit 1
    fi

    if [[ "$SIGN_IDENTITY" != Developer\ ID\ Application:* ]]; then
        echo "Distribution builds must use a Developer ID Application identity." >&2
        echo "Current identity: $SIGN_IDENTITY" >&2
        exit 1
    fi
}

resolve_sparkle_public_key() {
    if [[ -n "${CMDIME_SPARKLE_PUBLIC_ED_KEY:-}" ]]; then
        printf '%s' "$CMDIME_SPARKLE_PUBLIC_ED_KEY"
        return
    fi

    if [[ -x "$SPARKLE_GENERATE_KEYS_BIN" ]]; then
        local detected_public_key
        detected_public_key=$("$SPARKLE_GENERATE_KEYS_BIN" --account "$SPARKLE_KEY_ACCOUNT" -p 2>/dev/null | awk 'NF {print $NF; exit}')
        if [[ -n "$detected_public_key" ]]; then
            printf '%s' "$detected_public_key"
            return
        fi
    fi

    printf '%s' ""
}

sign_bundle_with_runtime() {
    local path="$1"
    shift
    if [[ "$BUILD_MODE" == "local" ]]; then
        codesign --force --sign "$SIGN_IDENTITY" "$@" "$path"
    else
        codesign --force --timestamp --options runtime --sign "$SIGN_IDENTITY" "$@" "$path"
    fi
}

sign_nested_code() {
    local path="$1"
    shift
    if [[ "$BUILD_MODE" == "local" ]]; then
        codesign --force --sign "$SIGN_IDENTITY" "$@" "$path"
    else
        codesign --force --timestamp --sign "$SIGN_IDENTITY" "$@" "$path"
    fi
}

VERSION="$(resolve_version)"
BUILD_NUMBER=$(git -C "$PROJECT_ROOT" rev-parse --short HEAD 2>/dev/null || echo "1")
SIGN_IDENTITY="$(resolve_signing_identity)"
SPARKLE_PUBLIC_ED_KEY="$(resolve_sparkle_public_key)"

require_distribution_prerequisites

echo ">> Building Swift release binary (Version: $VERSION, Build: $BUILD_NUMBER)"
mkdir -p "$CLANG_MODULE_CACHE_DIR" "$SWIFTPM_CACHE_DIR"
export CLANG_MODULE_CACHE_PATH="$CLANG_MODULE_CACHE_DIR"
export SWIFTPM_CUSTOM_CACHE_PATH="$SWIFTPM_CACHE_DIR"
swift build -c release --package-path "$PROJECT_ROOT"

BIN_PATH="$BUILD_DIR/$TRIPLE/release/$BIN_NAME"
if [[ ! -f "$BIN_PATH" ]]; then
    echo "Binary not found at $BIN_PATH" >&2
    exit 1
fi

echo ">> Creating app bundle at $APP_DIR"
rm -rf "$APP_DIR"
mkdir -p "$MACOS_DIR" "$RESOURCES_DIR" "$FRAMEWORKS_DIR"

ditto "$BIN_PATH" "$MACOS_DIR/$APP_NAME"
chmod +x "$MACOS_DIR/$APP_NAME"
if ! otool -l "$MACOS_DIR/$APP_NAME" | grep -Fq "@executable_path/../Frameworks"; then
    install_name_tool -add_rpath "@executable_path/../Frameworks" "$MACOS_DIR/$APP_NAME"
fi

SPARKLE_FRAMEWORK="$BUILD_DIR/$TRIPLE/release/Sparkle.framework"
if [[ -d "$SPARKLE_FRAMEWORK" ]]; then
    echo ">> Copying Sparkle.framework"
    ditto "$SPARKLE_FRAMEWORK" "$FRAMEWORKS_DIR/Sparkle.framework"
fi

if [[ -f "$ICON_SOURCE" ]]; then
    ditto "$ICON_SOURCE" "$RESOURCES_DIR/AppIcon.icns"
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
    <string>$BUILD_NUMBER</string>
    <key>CFBundleShortVersionString</key>
    <string>$VERSION</string>
    <key>LSMinimumSystemVersion</key>
    <string>13.0</string>
    <key>LSUIElement</key>
    <true/>
    <key>NSHighResolutionCapable</key>
    <true/>
    <key>SUFeedURL</key>
    <string>https://raw.githubusercontent.com/agiletec-inc/cmd-ime/main/appcast.xml</string>
    <key>SUPublicEDKey</key>
    <string>$SPARKLE_PUBLIC_ED_KEY</string>
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

echo ">> Signing app bundle with identity: $SIGN_IDENTITY"

SPARKLE_APP="$FRAMEWORKS_DIR/Sparkle.framework/Versions/B/Updater.app"
SPARKLE_DOWNLOADER_XPC="$FRAMEWORKS_DIR/Sparkle.framework/Versions/B/XPCServices/Downloader.xpc"
SPARKLE_INSTALLER_XPC="$FRAMEWORKS_DIR/Sparkle.framework/Versions/B/XPCServices/Installer.xpc"
SPARKLE_AUTOUPDATE="$FRAMEWORKS_DIR/Sparkle.framework/Versions/B/Autoupdate"
SPARKLE_BINARY="$FRAMEWORKS_DIR/Sparkle.framework/Versions/B/Sparkle"

if [[ -d "$SPARKLE_DOWNLOADER_XPC" ]]; then
    sign_bundle_with_runtime "$SPARKLE_DOWNLOADER_XPC"
fi

if [[ -d "$SPARKLE_INSTALLER_XPC" ]]; then
    sign_bundle_with_runtime "$SPARKLE_INSTALLER_XPC"
fi

if [[ -d "$SPARKLE_APP" ]]; then
    sign_bundle_with_runtime "$SPARKLE_APP"
fi

if [[ -f "$SPARKLE_AUTOUPDATE" ]]; then
    sign_bundle_with_runtime "$SPARKLE_AUTOUPDATE" --identifier "com.kazuki.cmdime.sparkle.autoupdate"
fi

if [[ -f "$SPARKLE_BINARY" ]]; then
    sign_nested_code "$FRAMEWORKS_DIR/Sparkle.framework"
fi

sign_bundle_with_runtime "$APP_DIR"

echo ">> Bundle ready: $APP_DIR"
