#!/usr/bin/env bash
set -e

DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
cd "$DIR"

VERSION="${1:-v1.0.0}"
echo "🚀 Packaging AeroBar $VERSION..."

# 1. Build the fresh .app bundle
./build.sh

# 2. Package ZIP
echo "📦 Packaging ZIP..."
ZIP_NAME="AeroBar-$VERSION-macOS.zip"
rm -f "$ZIP_NAME"
ditto -c -k --keepParent AeroBar.app "$ZIP_NAME"

# 3. Package DMG
echo "💿 Packaging DMG..."
DMG_NAME="AeroBar-$VERSION.dmg"
rm -rf dmg_staging "$DMG_NAME"
mkdir -p dmg_staging
cp -R AeroBar.app dmg_staging/
ln -s /Applications dmg_staging/Applications
hdiutil create -volname "AeroBar" -srcfolder dmg_staging -ov -format UDZO "$DMG_NAME"
rm -rf dmg_staging

echo "✨ Successfully built $DMG_NAME and $ZIP_NAME!"
ls -lh "$DMG_NAME" "$ZIP_NAME"
