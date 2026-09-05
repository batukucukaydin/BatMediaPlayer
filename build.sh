#!/bin/bash
set -euo pipefail
cd "$(dirname "$0")"

APP_NAME="BatMediaPlayer"
BUILD_DIR="build"
APP_DIR="$BUILD_DIR/$APP_NAME.app"

echo "==> Cleaning build directory..."
rm -rf "$BUILD_DIR"
mkdir -p "$BUILD_DIR"

echo "==> Generating app icon..."
mkdir -p "$BUILD_DIR/AppIcon.iconset"
if [ -f "baticon.png" ]; then
    echo "    using baticon.png"
    declare -a SIZES=("16x16:16" "16x16@2x:32" "32x32:32" "32x32@2x:64" "128x128:128" "128x128@2x:256" "256x256:256" "256x256@2x:512" "512x512:512" "512x512@2x:1024")
    for entry in "${SIZES[@]}"; do
        name="${entry%%:*}"
        px="${entry##*:}"
        sips -z "$px" "$px" baticon.png --out "$BUILD_DIR/AppIcon.iconset/icon_${name}.png" >/dev/null
    done
else
    swift scripts/make_icon.swift "$BUILD_DIR/AppIcon.iconset"
fi
iconutil -c icns "$BUILD_DIR/AppIcon.iconset" -o "$BUILD_DIR/AppIcon.icns"

echo "==> Building with Swift Package Manager (release)..."
swift build -c release

BIN_PATH="$(swift build -c release --show-bin-path)"
EXECUTABLE="$BIN_PATH/$APP_NAME"

if [ ! -f "$EXECUTABLE" ]; then
    echo "ERROR: executable not found at $EXECUTABLE" >&2
    exit 1
fi

echo "==> Assembling $APP_NAME.app..."
mkdir -p "$APP_DIR/Contents/MacOS"
mkdir -p "$APP_DIR/Contents/Resources"

cp "$EXECUTABLE" "$APP_DIR/Contents/MacOS/$APP_NAME"
cp "Support/Info.plist" "$APP_DIR/Contents/Info.plist"
cp "$BUILD_DIR/AppIcon.icns" "$APP_DIR/Contents/Resources/AppIcon.icns"
if [ -f "baticon.png" ]; then
    cp "baticon.png" "$APP_DIR/Contents/Resources/baticon.png"
fi
cp -R "Localization/en.lproj" "$APP_DIR/Contents/Resources/"
cp -R "Localization/tr.lproj" "$APP_DIR/Contents/Resources/"

echo "==> Stripping extended attributes..."
xattr -cr "$APP_DIR" || true
# Finder metadata on the bundle root makes strict code-signature verification
# fail with: "resource fork, Finder information, or similar detritus".
xattr -c "$APP_DIR" 2>/dev/null || true
xattr -r -d com.apple.FinderInfo "$APP_DIR" 2>/dev/null || true

echo "==> Code signing (ad-hoc)..."
codesign --force --deep --sign - "$APP_DIR"
# Some macOS tooling can add FinderInfo while creating/updating an app bundle.
# Remove it after signing as well; it is not part of the sealed resources.
xattr -c "$APP_DIR" 2>/dev/null || true
xattr -r -d com.apple.FinderInfo "$APP_DIR" 2>/dev/null || true
codesign --verify --deep --strict "$APP_DIR"

echo ""
echo "Done! App bundle: $APP_DIR"
echo "To install, run: cp -R \"$APP_DIR\" /Applications/"
