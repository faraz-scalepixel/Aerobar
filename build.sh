#!/usr/bin/env bash
set -e

DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
cd "$DIR"

echo "❄️ Building AeroBar for macOS..."

APP_NAME="AeroBar"
APP_BUNDLE="$APP_NAME.app"
CONTENTS="$APP_BUNDLE/Contents"
MACOS_DIR="$CONTENTS/MacOS"
RESOURCES_DIR="$CONTENTS/Resources"

# Clean previous build
rm -rf "$APP_BUNDLE"
mkdir -p "$MACOS_DIR"
mkdir -p "$RESOURCES_DIR"

# Source files
SOURCES=(
    "Sources/AeroBar/Models/ACState.swift"
    "Sources/AeroBar/Services/SoundManager.swift"
    "Sources/AeroBar/Services/SmartACService.swift"
    "Sources/AeroBar/Services/SamsungLocalACService.swift"
    "Sources/AeroBar/Services/TokenInterceptorServer.swift"
    "Sources/AeroBar/Services/LocalNetworkScanner.swift"
    "Sources/AeroBar/Services/CLIController.swift"
    "Sources/AeroBar/Views/ACUnitView.swift"
    "Sources/AeroBar/Views/FeatureCardView.swift"
    "Sources/AeroBar/Views/TemperatureSlider.swift"
    "Sources/AeroBar/Views/SettingsView.swift"
    "Sources/AeroBar/Views/MenuBarView.swift"
    "Sources/AeroBar/AppDelegate.swift"
    "Sources/AeroBar/main.swift"
)

echo "📦 Compiling Swift sources..."
swiftc -O \
    -target arm64-apple-macos14.0 \
    "${SOURCES[@]}" \
    -o "$MACOS_DIR/$APP_NAME"

# Copy Icons if present
if [ -f "Sources/AeroBar/Resources/AppIcon.icns" ]; then
    cp "Sources/AeroBar/Resources/AppIcon.icns" "$RESOURCES_DIR/AppIcon.icns"
fi
if [ -f "Sources/AeroBar/Resources/AppIcon.png" ]; then
    cp "Sources/AeroBar/Resources/AppIcon.png" "$RESOURCES_DIR/AppIcon.png"
fi

# Write Info.plist
cat << 'EOF' > "$CONTENTS/Info.plist"
<?xml version="1.0" encoding="UTF-8"?>
<!DOCTYPE plist PUBLIC "-//Apple//DTD PLIST 1.0//EN" "http://www.apple.com/DTDs/PropertyList-1.0.dtd">
<plist version="1.0">
<dict>
    <key>CFBundleExecutable</key>
    <string>AeroBar</string>
    <key>CFBundleIdentifier</key>
    <string>com.faraz.aerobar</string>
    <key>CFBundleName</key>
    <string>AeroBar</string>
    <key>CFBundleDisplayName</key>
    <string>AeroBar</string>
    <key>CFBundleIconFile</key>
    <string>AppIcon</string>
    <key>CFBundlePackageType</key>
    <string>APPL</string>
    <key>CFBundleShortVersionString</key>
    <string>1.1.0</string>
    <key>CFBundleVersion</key>
    <string>2</string>
    <key>LSMinimumSystemVersion</key>
    <string>14.0</string>
    <key>LSUIElement</key>
    <true/>
    <key>NSHighResolutionCapable</key>
    <true/>
    <key>NSPrincipalClass</key>
    <string>NSApplication</string>
    <key>NSAppTransportSecurity</key>
    <dict>
        <key>NSAllowsArbitraryLoads</key>
        <true/>
        <key>NSAllowsLocalNetworking</key>
        <true/>
    </dict>
</dict>
</plist>
EOF

# Code sign ad-hoc
echo "🔏 Signing application bundle..."
codesign --force --deep --sign - "$APP_BUNDLE" 2>/dev/null || true

echo "✨ Successfully built $APP_BUNDLE!"
echo "👉 Launch with: open $APP_BUNDLE or ./run.sh"
