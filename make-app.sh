#!/bin/sh
# Build the release binary and wrap it as FormJyotish.app in this folder.
set -e
cd "$(dirname "$0")"
swift build -c release
app=FormJyotish.app
rm -rf "$app"
mkdir -p "$app/Contents/MacOS"
cp .build/release/FormJyotish "$app/Contents/MacOS/FormJyotish"
cat > "$app/Contents/Info.plist" <<'PLIST'
<?xml version="1.0" encoding="UTF-8"?>
<!DOCTYPE plist PUBLIC "-//Apple//DTD PLIST 1.0//EN" "http://www.apple.com/DTDs/PropertyList-1.0.dtd">
<plist version="1.0">
<dict>
  <key>CFBundleName</key><string>Form Jyotish</string>
  <key>CFBundleIdentifier</key><string>org.coherence.FormJyotish</string>
  <key>CFBundleExecutable</key><string>FormJyotish</string>
  <key>CFBundlePackageType</key><string>APPL</string>
  <key>CFBundleShortVersionString</key><string>0.1</string>
  <key>CFBundleVersion</key><string>1</string>
  <key>LSMinimumSystemVersion</key><string>14.0</string>
  <key>NSHighResolutionCapable</key><true/>
</dict>
</plist>
PLIST
echo "built $app"
