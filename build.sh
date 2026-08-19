#!/bin/bash
set -e

echo "🔨 Building Klack Release Executable..."
swift build -c release

BUILD_DIR=".build/release"
APP_DIR="build/Klack.app"
CONTENTS_DIR="$APP_DIR/Contents"
MACOS_DIR="$CONTENTS_DIR/MacOS"
RESOURCES_DIR="$CONTENTS_DIR/Resources"

echo "📦 Creating App Bundle Structure..."
mkdir -p "$MACOS_DIR"
mkdir -p "$RESOURCES_DIR"

echo "🚚 Copying Binary, Info.plist, and AppIcon.icns..."
cp "$BUILD_DIR/Klack" "$MACOS_DIR/Klack"
cp "Info.plist" "$CONTENTS_DIR/Info.plist"

if [ -f "AppIcon.icns" ]; then
    cp "AppIcon.icns" "$RESOURCES_DIR/AppIcon.icns"
fi

echo "🔏 Ad-hoc Signing App Bundle..."
codesign --force --deep --sign - "$APP_DIR" || true

echo "✅ Klack.app Built Successfully at: $(pwd)/$APP_DIR"
echo "🚀 Run with: open $APP_DIR"
