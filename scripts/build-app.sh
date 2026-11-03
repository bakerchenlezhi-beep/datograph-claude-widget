#!/bin/bash
# Builds Datograph.app into ./build.noindex and signs it for local use.
# Spotlight skips folders ending in ".noindex", so this copy doesn't show up next to the installed app.
set -euo pipefail
cd "$(dirname "$0")/.."

swift build -c release
BIN_DIR="$(swift build -c release --show-bin-path)"

APP="build.noindex/Datograph.app"
rm -rf "$APP"
mkdir -p "$APP/Contents/MacOS" "$APP/Contents/Resources"
cp "$BIN_DIR/Datograph" "$APP/Contents/MacOS/Datograph"
cp Resources/Info.plist "$APP/Contents/Info.plist"
cp Resources/AppIcon.icns "$APP/Contents/Resources/AppIcon.icns"
codesign --force --sign - "$APP"

echo "Built $APP"
