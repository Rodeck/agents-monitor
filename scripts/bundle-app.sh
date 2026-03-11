#!/bin/bash
# Bundle the Swift executable into a macOS .app with Info.plist
set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"
PROJECT_DIR="$(dirname "$SCRIPT_DIR")"
APP_NAME="ClaudeMonitor"
APP_BUNDLE="$PROJECT_DIR/build/${APP_NAME}.app"

echo "Building ${APP_NAME}..."
cd "$PROJECT_DIR"
swift build -c release 2>&1

echo "Creating app bundle..."
rm -rf "$APP_BUNDLE"
mkdir -p "$APP_BUNDLE/Contents/MacOS"
mkdir -p "$APP_BUNDLE/Contents/Resources"

# Copy binary
cp ".build/release/${APP_NAME}" "$APP_BUNDLE/Contents/MacOS/${APP_NAME}"

# Copy Info.plist
cp "${APP_NAME}/Resources/Info.plist" "$APP_BUNDLE/Contents/Info.plist"

# Ad-hoc sign (required for UserNotifications framework)
echo "Signing app bundle..."
codesign --force --sign - "$APP_BUNDLE"

echo "App bundle created at: $APP_BUNDLE"
echo "Run with: open $APP_BUNDLE"
