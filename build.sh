#!/bin/bash
set -e

cd "$(dirname "$0")"

echo "Building ElgatoMirror..."
swift build -c release

echo "Creating .app bundle..."
APP="ElgatoMirror.app"
rm -rf "$APP"
mkdir -p "$APP/Contents/MacOS"
mkdir -p "$APP/Contents/Resources"

cp .build/release/ElgatoMirror "$APP/Contents/MacOS/"
cp Info.plist "$APP/Contents/"
cp AppIcon.icns "$APP/Contents/Resources/"

echo "Signing (ad-hoc)..."
codesign --force --deep --sign - "$APP"

echo ""
echo "Done! Launch with:  open ElgatoMirror.app"
