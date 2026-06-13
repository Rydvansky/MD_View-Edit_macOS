#!/usr/bin/env bash
set -euo pipefail

APP_NAME="MD_View-Edit_macOS"
EXECUTABLE_NAME="MDViewEditMacOS"
ROOT_DIR="$(cd "$(dirname "$0")/.." && pwd)"
DIST_DIR="$ROOT_DIR/dist"
VERSION="$(tr -d '[:space:]' < "$ROOT_DIR/VERSION")"
ARCHIVE_BASENAME="$APP_NAME-v$VERSION"
APP_BUNDLE_NAME="$ARCHIVE_BASENAME.app"
APP_DIR="$DIST_DIR/$APP_BUNDLE_NAME"
ZIP_PATH="$DIST_DIR/$ARCHIVE_BASENAME.zip"
DMG_PATH="$DIST_DIR/$ARCHIVE_BASENAME.dmg"
DMG_RW_PATH="$DIST_DIR/$ARCHIVE_BASENAME-rw.dmg"
DMG_STAGE="$DIST_DIR/dmg-stage"
DMG_BACKGROUND_DIR="$DMG_STAGE/.background"
DMG_BACKGROUND_NAME="install-background.png"
DMG_BACKGROUND_SOURCE="$ROOT_DIR/docs/install-background2.png"
BUILD_CONFIGURATION="${1:-release}"

cd "$ROOT_DIR"

if [ ! -f "$ROOT_DIR/Resources/AppIcon.icns" ]; then
    swift "$ROOT_DIR/scripts/make_icon.swift" "$ROOT_DIR/Resources/AppIcon.iconset"
    iconutil -c icns "$ROOT_DIR/Resources/AppIcon.iconset" -o "$ROOT_DIR/Resources/AppIcon.icns"
fi

swift build -c "$BUILD_CONFIGURATION"

rm -rf "$APP_DIR"
mkdir -p "$APP_DIR/Contents/MacOS" "$APP_DIR/Contents/Resources"

cp "$ROOT_DIR/.build/$BUILD_CONFIGURATION/$EXECUTABLE_NAME" "$APP_DIR/Contents/MacOS/$EXECUTABLE_NAME"
cp "$ROOT_DIR/Resources/Info.plist" "$APP_DIR/Contents/Info.plist"
/usr/libexec/PlistBuddy -c "Set :CFBundleShortVersionString $VERSION" "$APP_DIR/Contents/Info.plist"
cp "$ROOT_DIR/Resources/AppIcon.icns" "$APP_DIR/Contents/Resources/AppIcon.icns"
cp "$ROOT_DIR/markdown_demo.md" "$APP_DIR/Contents/Resources/markdown_demo.md"
chmod +x "$APP_DIR/Contents/MacOS/$EXECUTABLE_NAME"

codesign --force --deep --sign - "$APP_DIR" >/dev/null

rm -f "$ZIP_PATH"
ditto -c -k --keepParent "$APP_DIR" "$ZIP_PATH"

rm -rf "$DMG_STAGE" "$DMG_PATH" "$DMG_RW_PATH"
mkdir -p "$DMG_STAGE" "$DMG_BACKGROUND_DIR"
cp -R "$APP_DIR" "$DMG_STAGE/$APP_BUNDLE_NAME"
ln -s /Applications "$DMG_STAGE/Applications"
cp "$DMG_BACKGROUND_SOURCE" "$DMG_BACKGROUND_DIR/$DMG_BACKGROUND_NAME"

hdiutil create \
    -volname "$APP_NAME" \
    -srcfolder "$DMG_STAGE" \
    -ov \
    -format UDRW \
    "$DMG_RW_PATH" >/dev/null

DEVICE=""
MOUNT_POINT=""
cleanup_dmg_mount() {
    if [ -n "${DEVICE:-}" ] && hdiutil info | grep -q "$DEVICE"; then
        hdiutil detach "$DEVICE" -quiet || true
    elif [ -n "${MOUNT_POINT:-}" ] && [ -d "$MOUNT_POINT" ]; then
        hdiutil detach "$MOUNT_POINT" -quiet || true
    fi
}
trap cleanup_dmg_mount EXIT

ATTACH_OUTPUT="$(hdiutil attach "$DMG_RW_PATH" -readwrite -noverify -noautoopen)"
DEVICE="$(printf '%s\n' "$ATTACH_OUTPUT" | awk '/Apple_HFS|Apple_APFS/ {print $1; exit}')"
MOUNT_POINT="$(printf '%s\n' "$ATTACH_OUTPUT" | awk '/\/Volumes\// {for (i=3; i<=NF; i++) {printf (i==3 ? "" : " ") $i}; print ""; exit}')"

if [ -z "$MOUNT_POINT" ] || [ ! -d "$MOUNT_POINT" ]; then
    echo "Could not find mounted DMG volume." >&2
    printf '%s\n' "$ATTACH_OUTPUT" >&2
    exit 1
fi

osascript <<APPLESCRIPT
set mountPoint to POSIX file "$MOUNT_POINT" as alias
set appName to "$APP_BUNDLE_NAME"
set backgroundName to "$DMG_BACKGROUND_NAME"

with timeout of 60 seconds
    tell application "Finder"
        open mountPoint
        delay 1
        set win to container window of mountPoint
        set current view of win to icon view
        set toolbar visible of win to false
        set statusbar visible of win to false
        set bounds of win to {120, 120, 880, 550}
        set viewOptions to icon view options of win
        set arrangement of viewOptions to not arranged
        set icon size of viewOptions to 96
        set background picture of viewOptions to file ((mountPoint as text) & ".background:" & backgroundName)
        set position of item appName of mountPoint to {150, 220}
        set position of item "Applications" of mountPoint to {610, 220}
        delay 2
        close win
    end tell
end timeout
APPLESCRIPT

sync
hdiutil detach "$MOUNT_POINT" -quiet
DEVICE=""
MOUNT_POINT=""
trap - EXIT

hdiutil convert "$DMG_RW_PATH" -format UDZO -imagekey zlib-level=9 -o "$DMG_PATH" >/dev/null
rm -rf "$DMG_STAGE" "$DMG_RW_PATH"
find "$ROOT_DIR" -name .DS_Store -not -path "$ROOT_DIR/dist/*" -delete 2>/dev/null || true

echo "Packaged: $APP_DIR"
echo "Archive: $ZIP_PATH"
echo "Disk image: $DMG_PATH"
echo "DMG background: .background/$DMG_BACKGROUND_NAME"
