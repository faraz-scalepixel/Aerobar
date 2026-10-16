#!/usr/bin/env bash
set -e

DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
cd "$DIR"

# Kill any existing instance
pkill -f "AeroBar.app/Contents/MacOS/AeroBar" 2>/dev/null || true

# Rebuild if app bundle doesn't exist or if requested
if [ ! -d "AeroBar.app" ] || [ "$1" == "--rebuild" ]; then
    ./build.sh
fi

echo "🚀 Launching AeroBar into your macOS Menu Bar..."
open -n AeroBar.app

echo "✅ AeroBar is now active in your top Menu Bar!"
echo "Look for the AC icon next to your macOS clock / Control Center."
