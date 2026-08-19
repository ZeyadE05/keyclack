#!/bin/bash
set -e

SRC_IMG="/Users/zeyadeissa/.gemini/antigravity/brain/0cfd1669-e808-4a3f-a895-865741f594ab/klack_app_icon_1787146552848.jpg"
ICONSET_DIR="AppIcon.iconset"

echo "🎨 Creating iconset directory..."
mkdir -p "$ICONSET_DIR"

echo "📐 Generating icon variations..."
sips -s format png -z 16 16     "$SRC_IMG" --out "$ICONSET_DIR/icon_16x16.png"
sips -s format png -z 32 32     "$SRC_IMG" --out "$ICONSET_DIR/icon_16x16@2x.png"
sips -s format png -z 32 32     "$SRC_IMG" --out "$ICONSET_DIR/icon_32x32.png"
sips -s format png -z 64 64     "$SRC_IMG" --out "$ICONSET_DIR/icon_32x32@2x.png"
sips -s format png -z 128 128   "$SRC_IMG" --out "$ICONSET_DIR/icon_128x128.png"
sips -s format png -z 256 256   "$SRC_IMG" --out "$ICONSET_DIR/icon_128x128@2x.png"
sips -s format png -z 256 256   "$SRC_IMG" --out "$ICONSET_DIR/icon_256x256.png"
sips -s format png -z 512 512   "$SRC_IMG" --out "$ICONSET_DIR/icon_256x256@2x.png"
sips -s format png -z 512 512   "$SRC_IMG" --out "$ICONSET_DIR/icon_512x512.png"
sips -s format png -z 1024 1024 "$SRC_IMG" --out "$ICONSET_DIR/icon_512x512@2x.png"

echo "🛠️ Compiling AppIcon.icns..."
iconutil -c icns "$ICONSET_DIR" -o AppIcon.icns

echo "🧹 Cleaning up iconset temporary files..."
rm -rf "$ICONSET_DIR"

echo "✅ AppIcon.icns successfully created!"
