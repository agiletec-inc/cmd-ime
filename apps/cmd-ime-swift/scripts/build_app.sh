#!/bin/bash
set -e

# Build the executable
swift build -c release

# Create app bundle structure
APP_NAME="CmdIME"
BUNDLE_DIR="build/$APP_NAME.app"
CONTENTS_DIR="$BUNDLE_DIR/Contents"
MACOS_DIR="$CONTENTS_DIR/MacOS"
RESOURCES_DIR="$CONTENTS_DIR/Resources"

# Clean and create directories
rm -rf build
mkdir -p "$MACOS_DIR"
mkdir -p "$RESOURCES_DIR"

# Copy executable
cp .build/release/CmdIMESwift "$MACOS_DIR/$APP_NAME"

# Copy icon
if [ -f "../../AppIcon.icns" ]; then
    cp ../../AppIcon.icns "$RESOURCES_DIR/AppIcon.icns"
fi

# Copy pre-compiled storyboard from original cmd-eikana
ORIGINAL_STORYBOARD="/Users/kazuki/github/cmd-eikana/build/Debug/⌘英かな.app/Contents/Resources/Base.lproj/Main.storyboardc"
if [ -d "$ORIGINAL_STORYBOARD" ]; then
    mkdir -p "$RESOURCES_DIR/Base.lproj"
    cp -r "$ORIGINAL_STORYBOARD" "$RESOURCES_DIR/Base.lproj/"
fi

# Create Info.plist
cat > "$CONTENTS_DIR/Info.plist" << 'EOF'
<?xml version="1.0" encoding="UTF-8"?>
<!DOCTYPE plist PUBLIC "-//Apple//DTD PLIST 1.0//EN" "http://www.apple.com/DTDs/PropertyList-1.0.dtd">
<plist version="1.0">
<dict>
    <key>CFBundleExecutable</key>
    <string>CmdIME</string>
    <key>CFBundleIdentifier</key>
    <string>com.kazuki.cmdime</string>
    <key>CFBundleIconFile</key>
    <string>AppIcon</string>
    <key>CFBundleName</key>
    <string>CmdIME</string>
    <key>CFBundlePackageType</key>
    <string>APPL</string>
    <key>CFBundleShortVersionString</key>
    <string>1.2.0</string>
    <key>CFBundleVersion</key>
    <string>3</string>
    <key>LSMinimumSystemVersion</key>
    <string>13.0</string>
    <key>LSUIElement</key>
    <true/>
    <key>NSHighResolutionCapable</key>
    <true/>
    <key>NSPrincipalClass</key>
    <string>NSApplication</string>
    <key>SMLoginItemRegisteredByMacOSVersion</key>
    <string>13.0</string>
</dict>
</plist>
EOF

# Sign the app bundle (ad-hoc signature)
codesign --force --deep --sign - "$BUNDLE_DIR"

echo "App bundle created at: $BUNDLE_DIR"
echo "To run: open $BUNDLE_DIR"
